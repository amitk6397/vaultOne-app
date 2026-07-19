import asyncio
import json
import logging
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

from fastapi import HTTPException, status

from src.config.settings import settings

logger = logging.getLogger(__name__)


class UserAiService:
    def __init__(self) -> None:
        self.model = settings.gemini_model
        self.timeout = settings.gemini_timeout_seconds

    async def chat(
        self,
        message: str,
        user_name: str | None = None,
        app_context: dict[str, Any] | None = None,
    ) -> dict[str, str]:
        api_key = settings.gemini_api_key
        if not api_key:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Gemini API key missing. Set GEMINI_API_KEY in backend/.env and restart backend.",
            )
        prompt = self._build_prompt(message, user_name, app_context)
        payload = {
            "contents": [
                {
                    "role": "user",
                    "parts": [{"text": prompt}],
                }
            ],
            "generationConfig": {
                "temperature": 0.45,
                "maxOutputTokens": 700,
            },
        }
        response = await asyncio.to_thread(self._request_gemini, api_key, payload)
        return {"reply": self._extract_reply(response), "model": self.model}

    async def extract_image(self, image_base64: str, mime_type: str, target: str) -> dict[str, Any]:
        api_key = settings.gemini_api_key
        if not api_key:
            raise HTTPException(status_code=503, detail="Gemini API key missing")
        schemas = {
            "document": "fields may include document_number, issuer, full_name, date_of_birth, issue_date, expiry_date",
            "secure_note": "fields may include summary and category",
            "password": "fields must contain only site, username and password",
        }
        prompt = (
            "Extract visible text from this image. Return ONLY valid JSON with keys raw_text, title, "
            "document_type, and fields (an object of strings). Never infer a password that is not clearly "
            f"visible. Target is {target}; {schemas[target]}. Preserve exact spelling and numbers."
        )
        payload = {
            "contents": [{"role": "user", "parts": [
                {"text": prompt},
                {"inline_data": {"mime_type": mime_type, "data": image_base64}},
            ]}],
            "generationConfig": {"temperature": 0.0, "maxOutputTokens": 1800, "responseMimeType": "application/json"},
        }
        response = await asyncio.to_thread(self._request_gemini, api_key, payload)
        text = self._extract_reply(response).strip()
        if text.startswith("```"):
            text = text.strip("`").removeprefix("json").strip()
        try:
            data = json.loads(text)
        except json.JSONDecodeError as error:
            raise HTTPException(status_code=502, detail="AI returned invalid OCR data") from error
        return {
            "raw_text": str(data.get("raw_text", "")),
            "title": str(data.get("title", "Scanned image")),
            "document_type": str(data.get("document_type", "Other")),
            "fields": {str(k): str(v) for k, v in (data.get("fields") or {}).items()},
            "model": self.model,
        }

    def _request_gemini(self, api_key: str, payload: dict[str, Any]) -> dict[str, Any]:
        model = urllib.parse.quote(self.model, safe="")
        url = (
            "https://generativelanguage.googleapis.com/v1beta/models/"
            f"{model}:generateContent?key={urllib.parse.quote(api_key, safe='')}"
        )
        request = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                body = response.read().decode("utf-8")
                return json.loads(body)
        except urllib.error.HTTPError as error:
            detail = self._error_detail(error)
            logger.warning("Gemini provider error: %s", detail)
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=detail,
            ) from error
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as error:
            logger.warning("Gemini request failed: %s", error)
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="AI service is temporarily unavailable",
            ) from error

    def _extract_reply(self, response: dict[str, Any]) -> str:
        candidates = response.get("candidates")
        if not isinstance(candidates, list) or not candidates:
            return "AI response empty mila. Please thoda aur detail me puchiye."
        content = (
            candidates[0].get("content")
            if isinstance(candidates[0], dict)
            else None
        )
        parts = content.get("parts") if isinstance(content, dict) else None
        if not isinstance(parts, list):
            return "AI response parse nahi ho paya. Please retry kariye."
        text = "\n".join(
            part.get("text", "").strip()
            for part in parts
            if isinstance(part, dict) and part.get("text")
        ).strip()
        return text or "AI response empty mila. Please retry kariye."

    def _error_detail(self, error: urllib.error.HTTPError) -> str:
        try:
            body = error.read().decode("utf-8")
            data = json.loads(body)
            message = data.get("error", {}).get("message")
            if message:
                return f"AI provider error: {message}"
        except (UnicodeDecodeError, json.JSONDecodeError):
            pass
        return "AI provider request failed"

    def _build_prompt(
        self,
        message: str,
        user_name: str | None,
        app_context: dict[str, Any] | None,
    ) -> str:
        name = user_name or "VaultOne user"
        context_text = json.dumps(app_context or {}, ensure_ascii=False, indent=2)
        return (
            "You are VaultOne AI, a concise assistant inside a secure digital vault app. "
            "Help with documents, passwords, file organization, privacy, reminders, "
            "and safe app usage. "
            "Do not ask for passwords, OTPs, private keys, or full sensitive document numbers. "
            "The app context may include metadata from the user's local VaultOne app. "
            "Use it to answer where data exists, counts, titles, categories, dates, and safe summaries. "
            "Never invent hidden secrets. If a user asks for a saved password value, do not reveal it; "
            "tell them the matching entry exists and guide them to open Password Management securely. "
            "If the user asks for sensitive handling, suggest privacy-preserving steps. "
            "Reply in the same language style as the user when possible, often "
            "Hinglish for Indian users.\n\n"
            f"User name: {name}\n"
            f"VaultOne safe app context:\n{context_text}\n\n"
            f"User message: {message}"
        )
