import uuid
from supabase_functions_api import (
    sign_upload,
    sign_read,
    moderate_text,
    moderate_image,
    ocr_extract,
    ingest_text,
    search,
    process_screenshot,
)


def safe_call(func_name, func, *args, **kwargs):
    try:
        result = func(*args, **kwargs)
        print(f"{func_name} SUCCESS:")
        print(result)
        return result
    except Exception as e:
        print(f"{func_name} ERROR: {e}")
        if hasattr(e, 'response') and hasattr(e.response, 'text'):
            print(f"Response: {e.response.text}")
        return None

def main():
    print("\n-- SIGN UPLOAD --")
    session_id = f"testsession-{uuid.uuid4()}"
    sign_upload_resp = safe_call("sign_upload", sign_upload, session_id)
    if not sign_upload_resp:
        return
    path = sign_upload_resp["path"]

    print("\n-- SIGN READ --")
    sign_read_resp = safe_call("sign_read", sign_read, path)

    print("\n-- MODERATE TEXT --")
    rep_id = str(uuid.uuid4())
    moderate_text_resp = safe_call("moderate_text", moderate_text, rep_id,
                                   "This is a moderation test text unique phrase XJ092!")

    print("\n-- INGEST TEXT --")
    ingest_text_resp = safe_call("ingest_text", ingest_text, rep_id,
                                 "This is an ingestion test phrase ZY882!")

    print("\n-- SEARCH --")
    search_resp = safe_call("search", search, "ingestion test phrase ZY882")

    print("\n-- PROCESS SCREENSHOT --")
    process_screenshot_resp = safe_call("process_screenshot", process_screenshot, rep_id, path)

    print("\n-- MODERATE IMAGE --")
    moderate_image_resp = safe_call("moderate_image", moderate_image, rep_id, path)

    print("\n-- OCR EXTRACT --")
    ocr_extract_resp = safe_call("ocr_extract", ocr_extract, path=path)

    bucket = "session-uploads"
    path = "tmp/demo-001/test_image1.jpg"
    report_id = "7fb5ae78-783e-4242-87ff-88cdabce1678"  # use existing report, or random for new

    print("\n-- OCR EXTRACT --")
    ocr_result = ocr_extract(path=path, bucket=bucket)
    print(ocr_result)

    print("\n-- PROCESS SCREENSHOT --")
    process_result = process_screenshot(report_id, path, bucket=bucket, mime="image/jpeg")
    print(process_result)

    print("\n-- MODERATE IMAGE --")
    modimg_result = moderate_image(report_id, path, bucket=bucket)
    print(modimg_result)


if __name__ == "__main__":
    main()
