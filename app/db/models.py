"""ORM models for ArogyaKrishi - Consolidated database schema.

All persistent data for the application is managed through these models:
- DetectionEvent: Disease detections from user uploads (includes location for nearby alerts)
- User: Device/user profiles for push notifications (optional, for future expansion)
- SentAlert: Tracking of alerts sent to users (optional, for future expansion)
"""

from sqlalchemy import Column, String, Float, DateTime, Integer, Boolean, ForeignKey, func
from sqlalchemy.orm import relationship
from datetime import datetime
from .session import Base


class DetectionEvent(Base):
    """
    Stores disease detection results with location data.
    
    Used for:
    - Recording detection history
    - Querying nearby disease alerts
    - Analytics and pattern recognition
    """
    
    __tablename__ = "detection_events"
    
    id = Column(Integer, primary_key=True, index=True)
    crop = Column(String, nullable=False, index=True)
    disease = Column(String, nullable=False, index=True)
    confidence = Column(Float, nullable=False)
    latitude = Column(Float, nullable=True, index=True)
    longitude = Column(Float, nullable=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)


class User(Base):
    """
    User/device profiles for notification management (optional, for future features).
    
    Used for:
    - Device token storage for push notifications
    - User location tracking
    - Notification preferences
    """
    
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    device_token = Column(String, nullable=True, index=True)
    notifications_enabled = Column(Boolean, nullable=False, default=True)
    language = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationship to sent alerts
    sent_alerts = relationship(
        "SentAlert", 
        back_populates="user", 
        cascade="all, delete-orphan",
        lazy="selectin"
    )


class SentAlert(Base):
    """
    Tracking of alerts sent to users (optional, for future features).
    
    Used for:
    - Preventing duplicate alerts to same user
    - Alert delivery history
    - User engagement analytics
    """
    
    __tablename__ = "sent_alerts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    disease = Column(String, nullable=False, index=True)
    sent_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)

    # Relationship back to user
    user = relationship("User", back_populates="sent_alerts")
