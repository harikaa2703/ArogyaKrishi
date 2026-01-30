"""Repository for user device registrations and alert tracking."""

from datetime import datetime, timedelta
from typing import List, Optional
import math

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db.models import User, SentAlert


class UserRepository:
    """Repository for user/device records and alert tracking."""

    @staticmethod
    async def upsert_user(
        session: AsyncSession,
        device_token: str,
        latitude: float,
        longitude: float,
        notifications_enabled: bool = True,
        language: Optional[str] = None,
    ) -> User:
        """Create or update a user/device record by device token."""
        result = await session.execute(
            select(User).where(User.device_token == device_token)
        )
        user = result.scalars().first()

        if user is None:
            user = User(
                device_token=device_token,
                latitude=latitude,
                longitude=longitude,
                notifications_enabled=notifications_enabled,
                language=language,
            )
            session.add(user)
        else:
            user.latitude = latitude
            user.longitude = longitude
            user.notifications_enabled = notifications_enabled
            if language is not None:
                user.language = language

        await session.commit()
        await session.refresh(user)
        return user

    @staticmethod
    async def get_users_within_radius(
        session: AsyncSession,
        latitude: float,
        longitude: float,
        radius_km: float = 10.0,
    ) -> List[User]:
        """Get users within a geographic radius."""
        lat_delta = radius_km / 111.0
        lng_delta = radius_km / (111.0 * math.cos(math.radians(latitude)))

        query = select(User).where(
            (User.notifications_enabled.is_(True))
            & (User.latitude >= latitude - lat_delta)
            & (User.latitude <= latitude + lat_delta)
            & (User.longitude >= longitude - lng_delta)
            & (User.longitude <= longitude + lng_delta)
        )

        result = await session.execute(query)
        return result.scalars().all()

    @staticmethod
    async def was_alert_sent(
        session: AsyncSession,
        user_id: int,
        disease: str,
        within_hours: int = 6,
    ) -> bool:
        """Check if an alert was sent recently to a user for the same disease."""
        since = datetime.utcnow() - timedelta(hours=within_hours)
        query = select(SentAlert).where(
            (SentAlert.user_id == user_id)
            & (SentAlert.disease == disease)
            & (SentAlert.sent_at >= since)
        )
        result = await session.execute(query)
        return result.scalars().first() is not None

    @staticmethod
    async def log_alert(
        session: AsyncSession,
        user_id: int,
        disease: str,
    ) -> SentAlert:
        """Log a sent alert to prevent duplicates."""
        alert = SentAlert(user_id=user_id, disease=disease)
        session.add(alert)
        await session.commit()
        await session.refresh(alert)
        return alert
