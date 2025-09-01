import logging
from .providers.azure_client import AzureContentSafetyProvider

logger = logging.getLogger(__name__)

class TextAnalyzer:
    def __init__(self, provider: str = 'azure'):
        if provider != 'azure':
            raise NotImplementedError("Only 'azure' provider is wired right now.")
        self.provider = AzureContentSafetyProvider()

    def analyze(self, text: str) -> dict:
        if not text or not text.strip():
            return {
                "is_harmful": False, "risk_level": "Safe", "categories": {},
                "confidence_scores": {}, "provider":"azure", "error": "Empty text"
            }
        out = self.provider.analyze_text(text)
        risk = out.get("risk_level","Safe")
        is_harmful = risk in ("Low","Medium","High") and any(
            lvl in ("Low","Medium","High") and lvl != "Safe" for lvl in out.get("categories",{}).values()
        )
        return {
            "is_harmful": bool(is_harmful),
            "risk_level": risk,
            "categories": out.get("categories",{}),
            "confidence_scores": out.get("confidence_scores",{}),
            "provider": "azure",
            "error": out.get("error")
        }

default_analyzer = TextAnalyzer()

def analyze_text(text: str, provider: str = 'azure') -> dict:
    return TextAnalyzer(provider=provider).analyze(text)
