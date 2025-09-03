import logging
import json
from typing import Dict, Any, Optional
from .providers.azure_client import AzureContentSafetyProvider

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ContentDetector:
    """
    Enhanced content detection system with improved Azure Content Safety integration
    """
    
    def __init__(self, provider: str = 'azure'):
        if provider != 'azure':
            raise NotImplementedError("Only 'azure' provider is supported")
        
        try:
            self.provider = AzureContentSafetyProvider()
            logger.info("✅ Azure Content Safety provider initialized successfully")
        except Exception as e:
            logger.error(f"❌ Failed to initialize Azure provider: {e}")
            raise

    def analyze_content(self, text: str, debug: bool = False) -> Dict[str, Any]:
        """
        Analyze text content for harmful material
        
        Args:
            text: Text content to analyze
            debug: Enable debug logging
            
        Returns:
            Dictionary with analysis results
        """
        if debug:
            logger.info(f"🔍 Analyzing text: '{text[:100]}...' ({len(text)} chars)")
        
        # Handle empty or whitespace-only text
        if not text or not text.strip():
            result = {
                "is_harmful": False,
                "risk_level": "Safe",
                "categories": {},
                "confidence_scores": {},
                "provider": "azure",
                "error": "Empty or whitespace-only text provided",
                "text_length": 0
            }
            if debug:
                logger.info("⚠️ Empty text provided")
            return result
        
        try:
            # Call Azure Content Safety
            azure_result = self.provider.analyze_text(text.strip())
            
            if debug:
                logger.info(f"🔍 Azure raw result: {json.dumps(azure_result, indent=2)}")
            
            # Process the results
            categories = azure_result.get("categories", {})
            confidence_scores = azure_result.get("confidence_scores", {})
            risk_level = azure_result.get("risk_level", "Safe")
            error = azure_result.get("error")
            
            # Determine if content is harmful
            is_harmful = self._determine_harmful_status(categories, risk_level, confidence_scores, debug)
            
            result = {
                "is_harmful": is_harmful,
                "risk_level": risk_level,
                "categories": categories,
                "confidence_scores": confidence_scores,
                "provider": "azure",
                "error": error,
                "text_length": len(text.strip()),
                "analysis_summary": self._create_summary(categories, confidence_scores, is_harmful)
            }
            
            if debug:
                logger.info(f"📊 Final result: {json.dumps(result, indent=2)}")
            
            return result
            
        except Exception as e:
            logger.error(f"❌ Content analysis failed: {str(e)}", exc_info=True)
            return {
                "is_harmful": False,
                "risk_level": "Safe",
                "categories": {},
                "confidence_scores": {},
                "provider": "azure",
                "error": f"Analysis failed: {str(e)}",
                "text_length": len(text) if text else 0
            }

    def _determine_harmful_status(self, categories: Dict[str, str], risk_level: str, 
                                 confidence_scores: Dict[str, float], debug: bool = False) -> bool:
        """
        Determine if content should be flagged as harmful
        """
        # Check if any category is not "Safe"
        harmful_categories = []
        for category, level in categories.items():
            if level and level != "Safe":
                harmful_categories.append(f"{category}:{level}")
        
        # Check risk level
        risk_based_harmful = risk_level not in ["Safe", "Unknown", ""]
        
        # Check confidence scores for high-confidence detections
        high_confidence_harmful = any(
            score > 0.7 for score in confidence_scores.values() if score
        )
        
        is_harmful = bool(harmful_categories) or risk_based_harmful or high_confidence_harmful
        
        if debug:
            logger.info(f"🔍 Harm determination:")
            logger.info(f"  - Harmful categories: {harmful_categories}")
            logger.info(f"  - Risk level: {risk_level}")
            logger.info(f"  - High confidence scores: {[k for k, v in confidence_scores.items() if v > 0.7]}")
            logger.info(f"  - Final decision: {'HARMFUL' if is_harmful else 'SAFE'}")
        
        return is_harmful

    def _create_summary(self, categories: Dict[str, str], confidence_scores: Dict[str, float], 
                       is_harmful: bool) -> str:
        """
        Create a human-readable summary of the analysis
        """
        if not is_harmful:
            return "Content appears to be safe and appropriate."
        
        harmful_cats = [f"{cat} ({level})" for cat, level in categories.items() 
                       if level and level != "Safe"]
        
        if harmful_cats:
            return f"Potentially harmful content detected in categories: {', '.join(harmful_cats)}"
        else:
            return "Content flagged for review due to risk assessment."

# Global instance
default_detector = ContentDetector()

def detect_harmful_content(text: str, debug: bool = False) -> Dict[str, Any]:
    """
    Convenience function for content detection
    """
    return default_detector.analyze_content(text, debug=debug)