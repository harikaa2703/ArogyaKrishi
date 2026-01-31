"""Chat API routes for agricultural chatbot."""

import logging
from fastapi import APIRouter, File, UploadFile, HTTPException, status, Form, Request
from fastapi.responses import Response
from typing import Optional

from ..models.chat import ChatTextRequest, ChatResponse
from ..services.chatbot_service import ChatbotService
from ..config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/chat", tags=["chat"])


@router.post("/text", response_model=ChatResponse)
async def chat_text(request: ChatTextRequest, http_request: Request) -> ChatResponse:
    """
    Process text chat message.
    
    - **message**: User's text message
    - **language**: Language code (en, hi, te)
    - **session_id**: Optional session ID for conversation continuity
    """
    try:
        logger.info(f"Chat text request - language: {request.language}, session: {request.session_id}")
        
        # Validate language
        if request.language not in ["en", "hi", "te", "kn", "ml"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported language: {request.language}. Supported: en, hi, te, kn, ml"
            )
        
        # Process message
        reply, session_id, message_id = await ChatbotService.process_text_message(
            message=request.message,
            language=request.language,
            session_id=request.session_id
        )
        
        return ChatResponse(
            reply=reply,
            audio_url=None,  # Client uses flutter_tts
            session_id=session_id,
            language=request.language,
            message_id=message_id
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing text chat: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error processing chat message"
        )


@router.post("/voice", response_model=ChatResponse)
async def chat_voice(
    http_request: Request,
    audio: UploadFile = File(..., description="Audio file (WAV format)"),
    language: str = Form(..., description="Language code: en, hi, te"),
    session_id: Optional[str] = Form(None, description="Session ID for continuity")
) -> ChatResponse:
    """
    Process voice chat message.
    
    - **audio**: Audio file (WAV format)
    - **language**: Language code (en, hi, te)
    - **session_id**: Optional session ID for conversation continuity
    """
    try:
        logger.info(f"Chat voice request - language: {language}, session: {session_id}, filename: {audio.filename}")
        
        # Validate language
        if language not in ["en", "hi", "te", "kn", "ml"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported language: {language}. Supported: en, hi, te, kn, ml"
            )
        
        # Read audio bytes
        audio_bytes = await audio.read()
        
        # Validate audio type (optional)
        if audio.content_type and not audio.content_type.startswith("audio/"):
            logger.warning(f"Unexpected content type: {audio.content_type}")
        
        # Process voice message
        reply, session_id, message_id, audio_url = await ChatbotService.process_voice_message(
            audio_bytes=audio_bytes,
            language=language,
            session_id=session_id
        )

        if audio_url and audio_url.startswith("/api/"):
            audio_url = str(http_request.base_url).rstrip("/") + audio_url
        
        return ChatResponse(
            reply=reply,
            audio_url=audio_url,  # None for now, client uses flutter_tts
            session_id=session_id,
            language=language,
            message_id=message_id
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing voice chat: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error processing voice message"
        )


@router.get("/status")
async def chat_status() -> dict:
    """Expose whether OpenAI is enabled and current model config."""
    return {
        "openai_enabled": bool(settings.openai_api_key),
        "chat_model": settings.openai_chat_model,
        "stt_model": settings.openai_stt_model,
        "tts_model": settings.openai_tts_model,
        "tts_voice": settings.openai_tts_voice,
    }


@router.get("/audio/{audio_id}")
async def get_audio(audio_id: str) -> Response:
    """Fetch generated TTS audio by ID."""
    audio_data = ChatbotService.get_audio(audio_id)
    if not audio_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Audio not found",
        )
    audio_bytes, mime_type = audio_data
    return Response(content=audio_bytes, media_type=mime_type)
