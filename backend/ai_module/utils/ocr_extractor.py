import easyocr
import io
from PIL import Image
from typing import Union

class OCRExtractor:
    def __init__(self, languages=None):
        # English only by default; add 'hi','es',... as needed
        self.reader = easyocr.Reader(languages or ['en'], gpu=False)

    def extract_text(self, image: Union[str, Image.Image, bytes]) -> str:
        if isinstance(image, bytes):
            img = Image.open(io.BytesIO(image))
        elif isinstance(image, str):
            img = image  # path is ok for easyocr
        elif isinstance(image, Image.Image):
            img = image
        else:
            raise ValueError("image must be path, PIL.Image, or bytes")
        result = self.reader.readtext(img, detail=0)
        return "\n".join(result).strip()
