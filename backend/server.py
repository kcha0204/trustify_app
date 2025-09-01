from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
from ai_module.text_analyzer import default_analyzer
from ai_module.utils.ocr_extractor import OCRExtractor
from PIL import Image
import io

app = FastAPI(title="Trustify Analyzer")
ocr = OCRExtractor(languages=['en'])  # add langs if needed

class TextIn(BaseModel):
    text: str

@app.post("/analyze/text")
def analyze_text(inp: TextIn):
    res = default_analyzer.analyze(inp.text)
    return {"ok": True, "input_kind": "text", **res}

@app.post("/analyze/screenshot")
async def analyze_screenshot(file: UploadFile = File(...)):
    raw = await file.read()
    # OCR
    try:
        txt = ocr.extract_text(Image.open(io.BytesIO(raw)))
    except Exception as e:
        txt = f"[OCR Error] {e}"
    res = default_analyzer.analyze(txt if txt else "")
    return {
        "ok": True,
        "input_kind": "image",
        "ocr_text": txt,
        **res
    }
