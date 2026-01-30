"""Detection service orchestrates image processing and ML inference."""

import logging
from typing import Tuple, Dict, List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from ..utils.image_processor import preprocess_image
from .ml_service import get_model_loader
from .remedy_service import RemedyService
from .detection_repository import DetectionRepository
from .user_repository import UserRepository
from .notification_service import send_push_notification

logger = logging.getLogger(__name__)


class DetectionService:
    """Orchestrate detection workflow."""
    
    @staticmethod
    async def detect_disease(
        image_bytes: bytes,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
        language: str = "en",
        db_session: Optional[AsyncSession] = None
    ) -> Dict:
        """
        Detect disease from image and return results.
        
        Args:
            image_bytes: Raw image file bytes
            latitude: Optional location latitude
            longitude: Optional location longitude
            language: Language code (en, te, hi)
            db_session: Optional database session to save event
        
        Returns:
            Detection response dict
        """
        try:
            # Validate language
            language = RemedyService.validate_language(language)
            
            # Preprocess image
            logger.info("Preprocessing image...")
            image_array = preprocess_image(image_bytes)
            
            # Run inference
            logger.info("Running inference...")
            model_loader = get_model_loader()
            disease, confidence, crop = model_loader.predict(image_array)
            
            # Get translated names and remedies
            translated_crop = RemedyService.get_translated_crop(crop, language)
            translated_disease = RemedyService.get_translated_disease(disease, language)
            translated_remedies = RemedyService.get_remedies_list(disease, language)
            
            # Save to database if session provided (store English names)
            if db_session is not None and confidence >= 0.5:
                logger.info(f"Saving detection event: {disease} (confidence: {confidence})")
                try:
                    await DetectionRepository.save_event(
                        db_session,
                        crop=crop,
                        disease=disease,
                        confidence=confidence,
                        latitude=latitude,
                        longitude=longitude
                    )
                    await DetectionService._notify_nearby_users(
                        disease=disease,
                        latitude=latitude,
                        longitude=longitude,
                        db_session=db_session,
                    )
                except Exception as e:
                    logger.warning(f"Failed to save detection event: {e}")
                async def _notify_nearby_users(
                    disease: str,
                    latitude: Optional[float],
                    longitude: Optional[float],
                    db_session: AsyncSession,
                    radius_km: float = 10.0,
                ) -> None:
                    """Send soft alerts to nearby users (stub push)."""
                    if latitude is None or longitude is None:
                        return

                    users = await UserRepository.get_users_within_radius(
                        db_session,
                        latitude=latitude,
                        longitude=longitude,
                        radius_km=radius_km,
                    )

                    title = "Nearby crop health advisory"
                    body = (
                        f"A nearby report mentioned {disease}. "
                        "Please monitor your crop and follow recommended practices."
                    )

                    for user in users:
                        if not user.device_token:
                            continue
                        recently_sent = await UserRepository.was_alert_sent(
                            db_session,
                            user_id=user.id,
                            disease=disease,
                            within_hours=6,
                        )
                        if recently_sent:
                            continue

                        sent = await send_push_notification(user.device_token, title, body)
                        if sent:
                            await UserRepository.log_alert(
                                db_session,
                                user_id=user.id,
                                disease=disease,
                            )
            
            # Build response with translated content
            response = {
                "crop": translated_crop,
                "disease": translated_disease,
                "confidence": round(confidence, 3),
                "remedies": translated_remedies,
                "language": language
            }
            
            return response
        
        except Exception as e:
            logger.error(f"Detection error: {e}", exc_info=True)
            raise
    
    @staticmethod
    async def get_nearby_alerts(
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
        radius_km: float = 10.0,
        db_session: Optional[AsyncSession] = None
    ) -> Dict:
        """
        Get nearby disease alerts.
        
        Args:
            latitude: Optional user latitude
            longitude: Optional user longitude
            radius_km: Search radius in kilometers
            db_session: Database session
        
        Returns:
            Alerts response dict
        """
        try:
            if db_session is None:
                return {"alerts": []}
            
            # Get events within radius
            logger.info(f"Fetching alerts within {radius_km}km...")
            events = await DetectionRepository.get_events_within_radius(
                db_session,
                latitude=latitude,
                longitude=longitude,
                radius_km=radius_km
            )
            
            # Build alerts list
            alerts = []
            for event in events:
                # Calculate distance if we have coordinates
                distance_km = None
                if latitude is not None and longitude is not None and event.latitude and event.longitude:
                    distance_km = DetectionService._calculate_distance(
                        latitude, longitude, event.latitude, event.longitude
                    )
                
                alert = {
                    "disease": event.disease,
                    "distance_km": distance_km,
                    "timestamp": event.created_at.isoformat() if event.created_at else None
                }
                alerts.append(alert)
            
            return {"alerts": alerts}
        
        except Exception as e:
            logger.error(f"Alert retrieval error: {e}", exc_info=True)
            return {"alerts": []}
    
    @staticmethod
    def _calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two coordinates (simplified)."""
        import math
        
        # Haversine formula (simplified)
        R = 6371  # Earth radius in kilometers
        
        delta_lat = math.radians(lat2 - lat1)
        delta_lon = math.radians(lon2 - lon1)
        
        a = (
            math.sin(delta_lat / 2) ** 2 +
            math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(delta_lon / 2) ** 2
        )
        c = 2 * math.asin(math.sqrt(a))
        
        return round(R * c, 2)
