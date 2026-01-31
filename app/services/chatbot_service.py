"""Chatbot service for agricultural assistance."""

import io
import logging
import re
import uuid
from typing import Dict, Optional, Tuple
import random

from openai import AsyncOpenAI

from app.config import settings

logger = logging.getLogger(__name__)

# In-memory session storage (replace with Redis in production)
_sessions: Dict[str, list] = {}


class ChatbotService:
    """Service for chatbot interactions."""

    _client: Optional[AsyncOpenAI] = None
    _audio_store: Dict[str, bytes] = {}
    _audio_mime: Dict[str, str] = {}
    
    # Sample responses for agricultural questions (multilingual)
    RESPONSES = {
        "en": [
            "Based on your question, I recommend consulting with a local agricultural expert for specific advice.",
            "That's a great question about farming! For the best results, consider factors like soil quality, weather patterns, and crop rotation.",
            "In my experience, proper irrigation and pest management are key to healthy crops. What specific crop are you growing?",
            "I suggest monitoring your plants regularly for signs of disease or pest damage. Early detection is crucial.",
            "For optimal growth, ensure your plants receive adequate sunlight, water, and nutrients. What issue are you facing?",
        ],
        "hi": [
            "आपके प्रश्न के आधार पर, मैं विशिष्ट सलाह के लिए स्थानीय कृषि विशेषज्ञ से परामर्श करने की सलाह देता हूं।",
            "खेती के बारे में यह एक बढ़िया सवाल है! सर्वोत्तम परिणामों के लिए, मिट्टी की गुणवत्ता, मौसम के पैटर्न और फसल चक्र जैसे कारकों पर विचार करें।",
            "मेरे अनुभव में, स्वस्थ फसलों के लिए उचित सिंचाई और कीट प्रबंधन महत्वपूर्ण हैं। आप कौन सी फसल उगा रहे हैं?",
            "मैं आपके पौधों की नियमित रूप से बीमारी या कीट क्षति के संकेतों के लिए निगरानी करने का सुझाव देता हूं। शीघ्र पता लगाना महत्वपूर्ण है।",
            "इष्टतम वृद्धि के लिए, सुनिश्चित करें कि आपके पौधों को पर्याप्त धूप, पानी और पोषक तत्व मिलें। आप किस समस्या का सामना कर रहे हैं?",
        ],
        "te": [
            "మీ ప్రశ్న ఆధారంగా, నేను నిర్దిష్ట సలహా కోసం స్థానిక వ్యవసాయ నిపుణుడిని సంప్రదించాలని సిఫార్సు చేస్తున్నాను.",
            "వ్యవసాయం గురించి ఇది గొప్ప ప్రశ్న! ఉత్తమ ఫలితాల కోసం, నేల నాణ్యత, వాతావరణ నమూనాలు మరియు పంట మార్పిడి వంటి అంశాలను పరిగణించండి.",
            "నా అనుభవంలో, ఆరోగ్యకరమైన పంటలకు సరైన నీటిపారుదల మరియు పెస్ట్ నిర్వహణ కీలకం. మీరు ఏ నిర్దిష్ట పంటను పెంచుతున్నారు?",
            "వ్యాధి లేదా పెస్ట్ నష్టం యొక్క సంకేతాల కోసం మీ మొక్కలను క్రమం తప్పకుండా పర్యవేక్షించాలని నేను సూచిస్తున్నాను. ముందస్తు గుర్తింపు కీలకం.",
            "సరైన వృద్ధి కోసం, మీ మొక్కలకు తగినంత సూర్యరశ్మి, నీరు మరియు పోషకాలు అందుతున్నాయని నిర్ధారించుకోండి. మీరు ఏ సమస్యను ఎదుర్కొంటున్నారు?",
        ],
    }
    
    @classmethod
    def get_session_id(cls, session_id: Optional[str] = None) -> str:
        """Get or create session ID."""
        if session_id and session_id in _sessions:
            return session_id
        new_id = str(uuid.uuid4())
        _sessions[new_id] = []
        return new_id

    @classmethod
    def _get_client(cls) -> AsyncOpenAI:
        if not settings.openai_api_key:
            raise RuntimeError("OPENAI_API_KEY is not configured")
        if cls._client is None:
            cls._client = AsyncOpenAI(api_key=settings.openai_api_key)
        return cls._client

    @classmethod
    def _detect_language_code(cls, text: str) -> str:
        # Basic script detection for auto mode
        if re.search(r"[\u0900-\u097F]", text):
            return "hi"
        if re.search(r"[\u0C00-\u0C7F]", text):
            return "te"
        return "en"

    @classmethod
    def _build_system_prompt(cls, language: str) -> str:
        return (
            "You are ArogyaKrishi, an agricultural assistant for farmers. "
            "Provide concise, practical guidance. "
            f"Reply in language code '{language}'."
        )

    @classmethod
    def _normalize_language(cls, language: Optional[str], text_hint: Optional[str] = None) -> str:
        if not language or language == "auto":
            if text_hint:
                return cls._detect_language_code(text_hint)
            return "en"
        return language
    
    @classmethod
    def add_to_history(cls, session_id: str, role: str, content: str) -> None:
        """Add message to session history."""
        if session_id not in _sessions:
            _sessions[session_id] = []
        _sessions[session_id].append({"role": role, "content": content})
        
        # Keep only last 20 messages
        if len(_sessions[session_id]) > 20:
            _sessions[session_id] = _sessions[session_id][-20:]
    
    @classmethod
    async def process_text_message(
        cls,
        message: str,
        language: str,
        session_id: Optional[str] = None
    ) -> Tuple[str, str, str]:
        """
        Process text message and return response.
        
        Args:
            message: User's text message
            language: Language code (en, hi, te)
            session_id: Optional session ID
            
        Returns:
            Tuple of (reply, session_id, message_id)
        """
        language = cls._normalize_language(language, message)
        logger.info(f"Processing text message: {message[:50]}... (lang={language})")
        
        # Get or create session
        session_id = cls.get_session_id(session_id)
        
        # Add user message to history
        cls.add_to_history(session_id, "user", message)
        
        reply = None
        use_openai = bool(settings.openai_api_key)
        if use_openai:
            try:
                client = cls._get_client()

                history = _sessions.get(session_id, [])
                messages = [
                    {"role": "system", "content": cls._build_system_prompt(language)},
                    *history,
                ]

                response = await client.chat.completions.create(
                    model=settings.openai_chat_model,
                    messages=messages,
                    temperature=0.3,
                )
                reply = (response.choices[0].message.content or "").strip()
            except Exception as e:
                logger.error(f"OpenAI chat failed: {e}")
                raise
        else:
            responses = cls.RESPONSES.get(language, cls.RESPONSES["en"])
            reply = random.choice(responses)
        
        # Add assistant message to history
        cls.add_to_history(session_id, "assistant", reply)
        
        # Generate message ID
        message_id = str(uuid.uuid4())
        
        logger.info(f"Generated response for session {session_id}")
        
        return reply, session_id, message_id
    
    @classmethod
    async def process_voice_message(
        cls,
        audio_bytes: bytes,
        language: str,
        session_id: Optional[str] = None
    ) -> Tuple[str, str, str, Optional[str]]:
        """
        Process voice message and return response.
        
        Args:
            audio_bytes: Audio file bytes
            language: Language code (en, hi, te)
            session_id: Optional session ID
            
        Returns:
            Tuple of (reply, session_id, message_id, audio_url)
        """
        language = cls._normalize_language(language)
        logger.info(f"Processing voice message (lang={language}, size={len(audio_bytes)} bytes)")
        
        # Get or create session
        session_id = cls.get_session_id(session_id)
        
        transcribed_text = "[Voice message received]"
        use_openai = bool(settings.openai_api_key)
        if use_openai:
            try:
                client = cls._get_client()
                audio_file = io.BytesIO(audio_bytes)
                audio_file.name = "audio.wav"

                stt_kwargs = {"model": settings.openai_stt_model, "file": audio_file}
                if language in {"en", "hi", "te", "kn", "ml"}:
                    stt_kwargs["language"] = language

                transcription = await client.audio.transcriptions.create(**stt_kwargs)
                transcribed_text = (transcription.text or "").strip() or transcribed_text
            except Exception as e:
                logger.error(f"OpenAI transcription failed: {e}")
                raise
        
        # Add user message to history
        cls.add_to_history(session_id, "user", transcribed_text)
        
        reply = None
        if use_openai:
            try:
                client = cls._get_client()

                history = _sessions.get(session_id, [])
                messages = [
                    {"role": "system", "content": cls._build_system_prompt(language)},
                    *history,
                ]

                response = await client.chat.completions.create(
                    model=settings.openai_chat_model,
                    messages=messages,
                    temperature=0.3,
                )
                reply = (response.choices[0].message.content or "").strip()
            except Exception as e:
                logger.error(f"OpenAI chat failed: {e}")
                raise
        else:
            responses = cls.RESPONSES.get(language, cls.RESPONSES["en"])
            reply = random.choice(responses)
        
        # Add assistant message to history
        cls.add_to_history(session_id, "assistant", reply)
        
        # Generate message ID
        message_id = str(uuid.uuid4())
        
        audio_url = None
        if use_openai:
            try:
                client = cls._get_client()
                tts_response = await client.audio.speech.create(
                    model=settings.openai_tts_model,
                    voice=settings.openai_tts_voice,
                    input=reply,
                )
                audio_bytes = await tts_response.read()
                audio_id = str(uuid.uuid4())
                cls._audio_store[audio_id] = audio_bytes
                cls._audio_mime[audio_id] = "audio/mpeg"
                audio_url = f"/api/chat/audio/{audio_id}"
            except Exception as e:
                logger.warning(f"OpenAI TTS failed, returning no audio: {e}")
        
        logger.info(f"Generated voice response for session {session_id}")
        
        return reply, session_id, message_id, audio_url

    @classmethod
    def get_audio(cls, audio_id: str) -> Optional[Tuple[bytes, str]]:
        if audio_id not in cls._audio_store:
            return None
        return cls._audio_store[audio_id], cls._audio_mime.get(audio_id, "audio/mpeg")
