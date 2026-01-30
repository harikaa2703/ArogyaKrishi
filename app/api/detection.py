"""Detection API routes (multipart-free)."""

import logging
import math
from fastapi import APIRouter, File, UploadFile, Query, Depends, HTTPException, status, Body, Form
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional, List
import httpx

from ..config import settings
from ..models.schemas import (
    DetectImageResponse,
    NearbyAlertsResponse,
    ScanTreatmentResponse,
    SuggestedTreatmentsResponse,
    PesticideStoreResponse,
    RegisterDeviceRequest,
    RegisterDeviceResponse,
)
from ..services.detection_service import DetectionService
from ..services.remedy_service import RemedyService
from ..services.user_repository import UserRepository
from ..db.session import get_db

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["detection"])


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Compute distance in km between two lat/lng points."""
    radius = 6371.0
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return radius * c


@router.post("/detect-image", response_model=DetectImageResponse)
async def detect_image(
    image: UploadFile = File(..., description="Image file (jpg/png)"),
    lat: Optional[float] = Query(None, description="Latitude"),
    lng: Optional[float] = Query(None, description="Longitude"),
    language: str = Query("en", description="Language: en, te, hi, kn, ml"),
    db_session: AsyncSession = Depends(get_db),
) -> DetectImageResponse:
    """
    Detect plant disease from an uploaded image.
    
    - **image**: Image file (jpg/png)
    - **lat**: Optional latitude
    - **lng**: Optional longitude
    - **language**: Response language (en, te, hi, kn, ml)
    """
    try:
        logger.info(f"Received detect-image request - filename: {image.filename}, content_type: {image.content_type}")
        
        # Read image bytes
        image_bytes = await image.read()
        
        # Validate image type
        if image.content_type and image.content_type not in ["image/jpeg", "image/png"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid image type: {image.content_type}. Allowed: image/jpeg, image/png"
            )

        result = await DetectionService.detect_disease(
            image_bytes=image_bytes,
            latitude=lat,
            longitude=lng,
            language=language,
            db_session=db_session,
        )

        return DetectImageResponse(**result)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error detecting disease: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error processing image",
        )


@router.get("/nearby-alerts", response_model=NearbyAlertsResponse)
async def get_nearby_alerts(
    lat: Optional[float] = Query(None, description="Latitude"),
    lng: Optional[float] = Query(None, description="Longitude"),
    radius: float = Query(10.0, description="Search radius in km"),
    db_session: AsyncSession = Depends(get_db),
) -> NearbyAlertsResponse:
    """
    Get disease alerts detected nearby.
    """
    try:
        result = await DetectionService.get_nearby_alerts(
            latitude=lat,
            longitude=lng,
            radius_km=radius,
            db_session=db_session,
        )
        return NearbyAlertsResponse(**result)

    except Exception as e:
        logger.error(f"Error retrieving alerts: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error retrieving nearby alerts",
        )


@router.post("/scan-treatment", response_model=ScanTreatmentResponse)
async def scan_treatment(
    image: UploadFile = File(...),
    disease: str = Form(..., description="Disease name (localized or English key)"),
    item_label: Optional[str] = Form(None, description="Scanned item/product name"),
    language: str = Form("en", description="Language: en, te, hi, kn, ml")
) -> ScanTreatmentResponse:
    """
    Scan a fertilizer/medicine item and provide feedback if it can treat the disease.

    - **image**: Image file (jpg/png)
    - **disease**: Disease name (localized or English key)
    - **item_label**: Scanned item/product name
    - **language**: Response language (en, te, hi, kn, ml)
    """
    try:
        logger.info(f"Received scan-treatment request - filename: {image.filename}, content_type: {image.content_type}")
        logger.info(f"Disease: {disease}, Item Label: '{item_label}', Language: {language}")

        if not image.content_type or image.content_type not in ["image/jpeg", "image/png"]:
            logger.warning(f"Invalid content type: {image.content_type}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid image format. Please upload JPG or PNG."
            )

        max_size = settings.max_image_size_mb * 1024 * 1024
        contents = await image.read()
        if len(contents) > max_size:
            raise HTTPException(
                status_code=status.HTTP_413_PAYLOAD_TOO_LARGE,
                detail=f"Image too large. Maximum size: {settings.max_image_size_mb}MB"
            )

        result = RemedyService.evaluate_treatment(
            disease=disease,
            item_label=item_label,
            language=language
        )

        return ScanTreatmentResponse(**result)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error evaluating treatment: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error evaluating treatment"
        )


@router.post("/register-device", response_model=RegisterDeviceResponse)
async def register_device(
    payload: RegisterDeviceRequest,
    db_session: AsyncSession = Depends(get_db),
) -> RegisterDeviceResponse:
    """Register or update a device for nearby notifications."""
    try:
        if not payload.device_token:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="device_token is required",
            )

        await UserRepository.upsert_user(
            db_session,
            device_token=payload.device_token,
            latitude=payload.latitude,
            longitude=payload.longitude,
            notifications_enabled=payload.notifications_enabled,
            language=payload.language,
        )

        return RegisterDeviceResponse(ok=True)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error registering device: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error registering device",
        )


@router.get("/suggested-treatments", response_model=SuggestedTreatmentsResponse)
async def get_suggested_treatments(
    disease: str = Query(..., description="Disease name (localized or English key)"),
    language: str = Query("en", description="Language: en, te, hi, kn, ml"),
    lat: Optional[float] = Query(None, description="Latitude"),
    lng: Optional[float] = Query(None, description="Longitude"),
) -> SuggestedTreatmentsResponse:
    """
    Get suggested remedies and nearby pesticide stores.
    """
    try:
        language = RemedyService.validate_language(language)
        normalized_disease = RemedyService.normalize_disease_name(disease)
        remedies = RemedyService.get_remedies_list(normalized_disease, language)

        store_responses: List[PesticideStoreResponse] = []
        if lat is not None and lng is not None:
            try:
                store_responses = await _fetch_nearby_stores(
                    lat=lat,
                    lng=lng,
                )
            except Exception as e:
                logger.warning(f"Nearby store lookup failed: {e}")
                store_responses = []

        return SuggestedTreatmentsResponse(
            disease=RemedyService.get_translated_disease(normalized_disease, language),
            language=language,
            remedies=remedies,
            stores=store_responses,
        )

    except Exception as e:
        logger.error(f"Error retrieving suggested treatments: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error retrieving suggested treatments",
        )


async def _fetch_nearby_stores(
    lat: float,
    lng: float,
    radius_m: int = 5000,
    max_results: int = 3,
) -> List[PesticideStoreResponse]:
    """Fetch nearby pesticide shops using OpenStreetMap Overpass API."""
    overpass_urls = [
        "https://overpass-api.de/api/interpreter",
        "https://overpass.kumi.systems/api/interpreter",
        "https://overpass.nchc.org.tw/api/interpreter",
    ]
    query = f"""
    [out:json][timeout:10];
    (
      node(around:{radius_m},{lat},{lng})["shop"~"agrarian|farm|garden_centre|agricultural"]; 
      way(around:{radius_m},{lat},{lng})["shop"~"agrarian|farm|garden_centre|agricultural"]; 
      relation(around:{radius_m},{lat},{lng})["shop"~"agrarian|farm|garden_centre|agricultural"]; 
      node(around:{radius_m},{lat},{lng})["name"~"pesticide|fertilizer|fertiliser|agro|agri",i];
      way(around:{radius_m},{lat},{lng})["name"~"pesticide|fertilizer|fertiliser|agro|agri",i];
      relation(around:{radius_m},{lat},{lng})["name"~"pesticide|fertilizer|fertiliser|agro|agri",i];
    );
    out center 50;
    """

    async with httpx.AsyncClient(timeout=12.0) as client:
        last_error: Exception | None = None
        for overpass_url in overpass_urls:
            try:
                response = await client.post(overpass_url, data={"data": query})
                if response.status_code != 200:
                    last_error = httpx.HTTPStatusError(
                        f"Overpass status {response.status_code}",
                        request=response.request,
                        response=response,
                    )
                    continue

                data = response.json()
                elements = data.get("elements", [])

                stores: List[PesticideStoreResponse] = []
                for element in elements:
                    tags = element.get("tags", {})
                    name = tags.get("name") or "Pesticide Shop"

                    elem_lat = element.get("lat")
                    elem_lng = element.get("lon")
                    if elem_lat is None or elem_lng is None:
                        center = element.get("center", {})
                        elem_lat = center.get("lat")
                        elem_lng = center.get("lon")
                    if elem_lat is None or elem_lng is None:
                        continue

                    address = tags.get("addr:full")
                    if not address:
                        parts = [
                            tags.get("addr:housenumber"),
                            tags.get("addr:street"),
                            tags.get("addr:city"),
                        ]
                        address = ", ".join([p for p in parts if p]) if any(parts) else None

                    phone = tags.get("phone") or tags.get("contact:phone")
                    distance = _haversine_km(lat, lng, elem_lat, elem_lng)

                    stores.append(
                        PesticideStoreResponse(
                            name=name,
                            address=address,
                            phone=phone,
                            latitude=elem_lat,
                            longitude=elem_lng,
                            distance_km=distance,
                        )
                    )

                stores.sort(key=lambda s: s.distance_km or float("inf"))
                return stores[:max_results]
            except (httpx.ReadTimeout, httpx.ConnectTimeout, httpx.ConnectError) as e:
                last_error = e
                continue
            except Exception as e:
                last_error = e
                continue

        if last_error is not None:
            raise last_error
        return []
