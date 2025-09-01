import os
import logging
from azure.core.credentials import AzureKeyCredential
from azure.ai.contentsafety import ContentSafetyClient
from azure.ai.contentsafety.models import AnalyzeTextOptions
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger(__name__)

class AzureContentSafetyProvider:
    def __init__(self):
        key = os.getenv("AZURE_CONTENT_SAFETY_KEY")
        endpoint = os.getenv("AZURE_CONTENT_SAFETY_ENDPOINT")
        if not key or not endpoint:
            raise RuntimeError("Missing AZURE_CONTENT_SAFETY_KEY or AZURE_CONTENT_SAFETY_ENDPOINT")
        self.client = ContentSafetyClient(endpoint=endpoint, credential=AzureKeyCredential(key))

    def analyze_text(self, text: str) -> dict:
        """
        Returns:
          {
            "categories": {"Hate":"Low","SelfHarm":"Safe",...},
            "confidence_scores": {"Hate":0.12,...},
            "risk_level": "Low" | "Medium" | "High" | "Safe"
          }
        """
        try:
            options = AnalyzeTextOptions(text=text)
            resp = self.client.analyze_text(options)
            # The SDK returns a collection of category results with severity & confidence
            cats = {}
            conf = {}
            max_sev = 0
            for r in resp.categories_analysis:
                level = self._severity_to_level(r.severity)
                cats[r.category] = level
                # confidence may be None depending on API version; guard with 0.0
                conf[r.category] = float(getattr(r, "confidence", 0.0) or 0.0)
                max_sev = max(max_sev, int(r.severity or 0))
            return {
                "categories": cats,
                "confidence_scores": conf,
                "risk_level": self._severity_to_level(max_sev),
            }
        except Exception as e:
            logger.exception("Azure Content Safety error")
            return {"categories": {}, "confidence_scores": {}, "risk_level": "Safe", "error": str(e)}

    def _severity_to_level(self, severity: int) -> str:
        # 0=Safe, 1-2 Low, 3-4 Medium, 5-7 High (typical mapping; adjust if your account returns 0-6)
        bands = ['Safe','Low','Low','Medium','Medium','High','High','High']
        return bands[severity] if 0 <= severity < len(bands) else 'Unknown'
