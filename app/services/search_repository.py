"""Repository for disease search history."""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, func
from ..db.models import DiseaseSearch
from typing import List, Optional
from datetime import datetime


class SearchRepository:
    """Repository for disease search history."""
    
    @staticmethod
    async def save_search(
        session: AsyncSession,
        crop: str,
        disease: str,
        confidence: float,
        language: str = "en",
        device_token: Optional[str] = None,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None
    ) -> DiseaseSearch:
        """Save a disease search to history."""
        search = DiseaseSearch(
            crop=crop,
            disease=disease,
            confidence=confidence,
            language=language,
            device_token=device_token,
            latitude=latitude,
            longitude=longitude
        )
        session.add(search)
        await session.commit()
        await session.refresh(search)
        return search
    
    @staticmethod
    async def get_search_history(
        session: AsyncSession,
        device_token: Optional[str] = None,
        limit: int = 50,
        offset: int = 0
    ) -> tuple[List[DiseaseSearch], int]:
        """Get search history for a device, ordered by most recent first."""
        query = select(DiseaseSearch)
        
        if device_token:
            query = query.where(DiseaseSearch.device_token == device_token)
        
        # Get total count
        count_query = select(func.count()).select_from(DiseaseSearch)
        if device_token:
            count_query = count_query.where(DiseaseSearch.device_token == device_token)
        
        total_count = await session.scalar(count_query)
        
        # Get paginated results
        query = query.order_by(desc(DiseaseSearch.created_at)).offset(offset).limit(limit)
        result = await session.execute(query)
        searches = result.scalars().all()
        
        return searches, total_count
    
    @staticmethod
    async def get_unique_diseases(
        session: AsyncSession,
        device_token: Optional[str] = None,
        limit: int = 20
    ) -> List[dict]:
        """Get unique diseases from search history."""
        query = select(
            DiseaseSearch.disease,
            DiseaseSearch.crop,
            func.max(DiseaseSearch.created_at).label('last_searched'),
            func.count(DiseaseSearch.id).label('search_count')
        )
        
        if device_token:
            query = query.where(DiseaseSearch.device_token == device_token)
        
        query = query.group_by(DiseaseSearch.disease, DiseaseSearch.crop).order_by(
            desc(func.max(DiseaseSearch.created_at))
        ).limit(limit)
        
        result = await session.execute(query)
        rows = result.all()
        
        return [
            {
                'disease': row[0],
                'crop': row[1],
                'last_searched': row[2],
                'search_count': row[3]
            }
            for row in rows
        ]

    @staticmethod
    async def delete_search(session: AsyncSession, search_id: int) -> bool:
        """Delete a specific search record."""
        search = await session.get(DiseaseSearch, search_id)
        if search:
            await session.delete(search)
            await session.commit()
            return True
        return False
    
    @staticmethod
    async def clear_history(
        session: AsyncSession,
        device_token: Optional[str] = None
    ) -> int:
        """Clear search history for a device. Returns count of deleted records."""
        query = select(DiseaseSearch)
        if device_token:
            query = query.where(DiseaseSearch.device_token == device_token)
        
        result = await session.execute(query)
        searches = result.scalars().all()
        
        for search in searches:
            await session.delete(search)
        
        await session.commit()
        return len(searches)
