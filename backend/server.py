from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from ai_module.text_analyzer import default_analyzer, analyze_text
from ai_module.content_detector import default_detector, detect_harmful_content
from ai_module.providers.azure_client import AzureContentSafetyProvider
from ai_module.utils.ocr_extractor import OCRExtractor
from PIL import Image
import io
import logging
import json

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = FastAPI(title="Trustify Analyzer - Complete Content Safety API", version="2.0.0")

# Initialize components
try:
    ocr = OCRExtractor(languages=['en'])
    azure_provider = AzureContentSafetyProvider()
    logger.info("✅ All AI components initialized successfully")
except Exception as e:
    logger.error(f"❌ Failed to initialize AI components: {e}")
    raise

class TextInput(BaseModel):
    text: str
    debug: bool = False

class AnalysisResponse(BaseModel):
    ok: bool
    input_kind: str
    provider: str = "azure"
    analysis_method: str

# ============================================================================
# ORIGINAL TEXT ANALYZER ENDPOINTS (using text_analyzer.py)
# ============================================================================

@app.post("/analyze/text", response_model=dict)
def analyze_text_original(input_data: TextInput):
    """
    Original text analysis using TextAnalyzer (text_analyzer.py)
    More conservative harmful content detection
    """
    logger.info(f"📝 [ORIGINAL] Text analysis request: '{input_data.text[:100]}...' ({len(input_data.text)} chars)")
    
    try:
        result = default_analyzer.analyze(input_data.text)
        
        if input_data.debug:
            logger.info(f"📊 [ORIGINAL] Analysis result: {json.dumps(result, indent=2)}")
        
        logger.info(f"✅ [ORIGINAL] Text analysis completed: {result.get('risk_level', 'Unknown')} risk, harmful: {result.get('is_harmful', False)}")
        
        return {
            "ok": True,
            "input_kind": "text",
            "analysis_method": "original_text_analyzer",
            **result
        }
        
    except Exception as e:
        logger.error(f"❌ [ORIGINAL] Text analysis failed: {str(e)}", exc_info=True)
        return {
            "ok": False,
            "input_kind": "text",
            "analysis_method": "original_text_analyzer",
            "error": f"Analysis failed: {str(e)}",
            "is_harmful": False,
            "risk_level": "Safe",
            "categories": {},
            "confidence_scores": {},
            "provider": "azure"
        }

@app.post("/analyze/screenshot", response_model=dict)
async def analyze_screenshot_original(file: UploadFile = File(...)):
    """
    Original image analysis using TextAnalyzer + OCR
    """
    logger.info(f"📸 [ORIGINAL] Image analysis request: {file.filename} ({file.content_type})")
    
    try:
        # Read and process image
        raw = await file.read()
        logger.info(f"📸 Image data read: {len(raw)} bytes")
        
        # Extract text using OCR
        try:
            img = Image.open(io.BytesIO(raw))
            logger.info(f"📸 Image opened: {img.size} pixels, mode: {img.mode}")
            
            extracted_text = ocr.extract_text(img)
            logger.info(f"📸 OCR extracted text: '{extracted_text[:200]}...' ({len(extracted_text)} chars)")
            
        except Exception as e:
            logger.error(f"❌ OCR extraction failed: {str(e)}")
            extracted_text = f"[OCR Error] {str(e)}"
        
        # Analyze extracted text using original analyzer
        if extracted_text and not extracted_text.startswith("[OCR Error]"):
            analysis_result = default_analyzer.analyze(extracted_text)
            logger.info(f"✅ [ORIGINAL] Image analysis completed: {analysis_result.get('risk_level', 'Unknown')} risk")
        else:
            logger.warning("⚠️ Using default safe result due to OCR error or no text")
            analysis_result = {
                "is_harmful": False,
                "risk_level": "Safe",
                "categories": {},
                "confidence_scores": {},
                "provider": "azure",
                "error": "No text extracted or OCR failed"
            }
        
        return {
            "ok": True,
            "input_kind": "image",
            "analysis_method": "original_text_analyzer",
            "ocr_text": extracted_text,
            **analysis_result
        }
        
    except Exception as e:
        logger.error(f"❌ [ORIGINAL] Screenshot analysis failed: {str(e)}", exc_info=True)
        return {
            "ok": False,
            "input_kind": "image",
            "analysis_method": "original_text_analyzer",
            "error": f"Analysis failed: {str(e)}",
            "ocr_text": "",
            "is_harmful": False,
            "risk_level": "Safe",
            "categories": {},
            "confidence_scores": {},
            "provider": "azure"
        }

# ============================================================================
# ENHANCED CONTENT DETECTOR ENDPOINTS (using content_detector.py)
# ============================================================================

@app.post("/analyze/text/enhanced", response_model=dict)
def analyze_text_enhanced(input_data: TextInput):
    """
    Enhanced text analysis using ContentDetector (content_detector.py)
    More comprehensive harmful content detection with better logging
    """
    logger.info(f"📝 [ENHANCED] Text analysis request: '{input_data.text[:100]}...' ({len(input_data.text)} chars)")
    
    try:
        result = default_detector.analyze_content(input_data.text, debug=input_data.debug)
        logger.info(f"✅ [ENHANCED] Text analysis completed: {result.get('risk_level', 'Unknown')} risk, harmful: {result.get('is_harmful', False)}")
        
        return {
            "ok": True,
            "input_kind": "text",
            "analysis_method": "enhanced_content_detector",
            **result
        }
        
    except Exception as e:
        logger.error(f"❌ [ENHANCED] Text analysis failed: {str(e)}", exc_info=True)
        return {
            "ok": False,
            "input_kind": "text",
            "analysis_method": "enhanced_content_detector",
            "error": f"Analysis failed: {str(e)}",
            "is_harmful": False,
            "risk_level": "Safe",
            "categories": {},
            "confidence_scores": {},
            "provider": "azure"
        }

@app.post("/analyze/screenshot/enhanced", response_model=dict)
async def analyze_screenshot_enhanced(file: UploadFile = File(...)):
    """
    Enhanced image analysis using ContentDetector + OCR
    """
    logger.info(f"📸 [ENHANCED] Image analysis request: {file.filename} ({file.content_type})")
    
    try:
        # Read and process image
        raw = await file.read()
        logger.info(f"📸 Image data read: {len(raw)} bytes")
        
        # Extract text using OCR
        try:
            img = Image.open(io.BytesIO(raw))
            logger.info(f"📸 Image opened: {img.size} pixels, mode: {img.mode}")
            
            extracted_text = ocr.extract_text(img)
            logger.info(f"📸 OCR extracted text: '{extracted_text[:200]}...' ({len(extracted_text)} chars)")
            
        except Exception as e:
            logger.error(f"❌ OCR extraction failed: {str(e)}")
            extracted_text = f"[OCR Error] {str(e)}"
        
        # Analyze extracted text using enhanced detector
        if extracted_text and not extracted_text.startswith("[OCR Error]"):
            analysis_result = default_detector.analyze_content(extracted_text, debug=True)
            logger.info(f"✅ [ENHANCED] Image analysis completed: {analysis_result.get('risk_level', 'Unknown')} risk")
        else:
            logger.warning("⚠️ Using default safe result due to OCR error or no text")
            analysis_result = {
                "is_harmful": False,
                "risk_level": "Safe",
                "categories": {},
                "confidence_scores": {},
                "provider": "azure",
                "error": "No text extracted or OCR failed",
                "text_length": 0
            }
        
        return {
            "ok": True,
            "input_kind": "image",
            "analysis_method": "enhanced_content_detector",
            "ocr_text": extracted_text,
            **analysis_result
        }
        
    except Exception as e:
        logger.error(f"❌ [ENHANCED] Screenshot analysis failed: {str(e)}", exc_info=True)
        return {
            "ok": False,
            "input_kind": "image",
            "analysis_method": "enhanced_content_detector",
            "error": f"Analysis failed: {str(e)}",
            "ocr_text": "",
            "is_harmful": False,
            "risk_level": "Safe",
            "categories": {},
            "confidence_scores": {},
            "provider": "azure"
        }

# ============================================================================
# DIRECT AZURE API ENDPOINTS (using azure_client.py directly)
# ============================================================================

@app.post("/analyze/text/raw-azure", response_model=dict)
def analyze_text_raw_azure(input_data: TextInput):
    """
    Direct Azure Content Safety API analysis (raw results)
    """
    logger.info(f"📝 [RAW-AZURE] Direct Azure analysis request: '{input_data.text[:100]}...' ({len(input_data.text)} chars)")
    
    try:
        result = azure_provider.analyze_text(input_data.text)
        
        if input_data.debug:
            logger.info(f"📊 [RAW-AZURE] Raw Azure result: {json.dumps(result, indent=2)}")
        
        logger.info(f"✅ [RAW-AZURE] Direct Azure analysis completed: {result.get('risk_level', 'Unknown')} risk")
        
        return {
            "ok": True,
            "input_kind": "text",
            "analysis_method": "raw_azure_api",
            "provider": "azure",
            **result
        }
        
    except Exception as e:
        logger.error(f"❌ [RAW-AZURE] Direct Azure analysis failed: {str(e)}", exc_info=True)
        return {
            "ok": False,
            "input_kind": "text",
            "analysis_method": "raw_azure_api",
            "error": f"Azure API failed: {str(e)}",
            "categories": {},
            "confidence_scores": {},
            "risk_level": "Safe",
            "provider": "azure"
        }

# ============================================================================
# UTILITY AND TESTING ENDPOINTS
# ============================================================================

@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy", 
        "service": "Trustify Analyzer",
        "version": "2.0.0",
        "components": {
            "azure_provider": "initialized",
            "ocr_extractor": "initialized",
            "text_analyzer": "initialized",
            "content_detector": "initialized"
        }
    }

@app.get("/test/azure-connection")
def test_azure_connection():
    """Test Azure Content Safety connection with known content"""
    test_cases = [
        {"text": "Hello, this is a nice day!", "expected": "safe"},
        {"text": "I hate you so much, you are stupid and worthless", "expected": "harmful"},
        {"text": "Go kill yourself, nobody likes you", "expected": "harmful"}
    ]
    
    results = []
    for test_case in test_cases:
        try:
            # Test with original analyzer
            original_result = default_analyzer.analyze(test_case["text"])
            
            # Test with enhanced detector
            enhanced_result = default_detector.analyze_content(test_case["text"], debug=False)
            
            # Test with raw Azure
            raw_result = azure_provider.analyze_text(test_case["text"])
            
            results.append({
                "test_text": test_case["text"],
                "expected": test_case["expected"],
                "original_analyzer": {
                    "is_harmful": original_result.get("is_harmful", False),
                    "risk_level": original_result.get("risk_level", "Unknown")
                },
                "enhanced_detector": {
                    "is_harmful": enhanced_result.get("is_harmful", False),
                    "risk_level": enhanced_result.get("risk_level", "Unknown")
                },
                "raw_azure": {
                    "risk_level": raw_result.get("risk_level", "Unknown"),
                    "categories": raw_result.get("categories", {})
                }
            })
            
        except Exception as e:
            results.append({
                "test_text": test_case["text"],
                "expected": test_case["expected"],
                "error": str(e)
            })
    
    return {
        "azure_connection": "tested",
        "timestamp": "now",
        "test_results": results
    }

@app.post("/ocr/extract")
async def extract_text_from_image(file: UploadFile = File(...)):
    """Extract text from image using OCR only (no content analysis)"""
    logger.info(f"📸 [OCR-ONLY] Text extraction request: {file.filename}")
    
    try:
        raw = await file.read()
        img = Image.open(io.BytesIO(raw))
        extracted_text = ocr.extract_text(img)
        
        logger.info(f"✅ [OCR-ONLY] Text extracted: '{extracted_text[:100]}...' ({len(extracted_text)} chars)")
        
        return {
            "ok": True,
            "service": "ocr_extraction",
            "extracted_text": extracted_text,
            "text_length": len(extracted_text),
            "image_info": {
                "size": img.size,
                "mode": img.mode,
                "format": img.format
            }
        }
        
    except Exception as e:
        logger.error(f"❌ [OCR-ONLY] Text extraction failed: {str(e)}")
        return {
            "ok": False,
            "service": "ocr_extraction",
            "error": str(e),
            "extracted_text": "",
            "text_length": 0
        }

@app.get("/")
def root():
    """API information endpoint"""
    return {
        "service": "Trustify Content Analysis API",
        "version": "2.0.0",
        "endpoints": {
            "original_analysis": {
                "text": "/analyze/text",
                "image": "/analyze/screenshot"
            },
            "enhanced_analysis": {
                "text": "/analyze/text/enhanced", 
                "image": "/analyze/screenshot/enhanced"
            },
            "raw_azure": {
                "text": "/analyze/text/raw-azure"
            },
            "utilities": {
                "health": "/health",
                "test": "/test/azure-connection",
                "ocr": "/ocr/extract"
            }
        },
        "description": "Complete content safety analysis with multiple detection methods"
    }
