import os
import requests
import json
from dotenv import load_dotenv

load_dotenv()
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY").strip()
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY").strip()
SUPABASE_BASE_URL = "https://oqjeucsmquvsitfqjsry.supabase.co/functions/v1"


def sign_upload(session_id, mime="image/jpeg", bucket="session-uploads", path_prefix="tmp"):
    url = f"{SUPABASE_BASE_URL}/sign-upload"
    body = {
        "sessionId": session_id,
        "bucket": bucket,
        "mime": mime,
        "pathPrefix": path_prefix
    }
    headers = {
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json"
    }
    r = requests.post(url, headers=headers, data=json.dumps(body))
    r.raise_for_status()
    return r.json()


def sign_read(path, bucket="session-uploads", expires_sec=600):
    url = f"{SUPABASE_BASE_URL}/sign-read"
    body = {
        "path": path,
        "bucket": bucket,
        "expiresSec": expires_sec
    }
    headers = {
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json"
    }
    r = requests.post(url, headers=headers, data=json.dumps(body))
    r.raise_for_status()
    return r.json()


def moderate_text(report_id, text, media_id=None, chunk_id=None, output_type="FourSeverityLevels"):
    url = f"{SUPABASE_BASE_URL}/moderate-text"
    body = {
        "report_id": report_id,
        "text": text,
        "media_id": media_id,
        "chunk_id": chunk_id,
        "outputType": output_type
    }
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }
    r = requests.post(url, headers=headers, data=json.dumps(body))
    r.raise_for_status()
    return r.json()


def moderate_image(report_id, path, bucket="session-uploads", expires_sec=180, media_id=None):
    url = f"{SUPABASE_BASE_URL}/moderate-image"
    body = {
        "report_id": report_id,
        "path": path,
        "bucket": bucket,
        "expiresSec": expires_sec,
        "media_id": media_id
    }
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }
    r = requests.post(url, headers=headers, data=json.dumps(body))
    r.raise_for_status()
    return r.json()


def ocr_extract(path=None, image_url=None, bucket="session-uploads", expires_sec=600):
    url = f"{SUPABASE_BASE_URL}/ocr-extract"
    if image_url is not None:
        body = {"imageUrl": image_url}
    elif path is not None:
        body = {"bucket": bucket, "path": path, "expiresSec": expires_sec}
    else:
        raise ValueError("You must provide either image_url or path")
    headers = {
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json"
    }
    r = requests.post(url, headers=headers, data=json.dumps(body))
    r.raise_for_status()
    return r.json()


def ingest_text(report_id, text, media_id=None, lang="en"):
    url = f"{SUPABASE_BASE_URL}/ingest-text"
    body = {
        "report_id": report_id,
        "text": text,
        "lang": lang
    }
    # Only add media_id if it's not None
    if media_id is not None:
        body["media_id"] = media_id

    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }
    r = requests.post(url, headers=headers, data=json.dumps(body))
    r.raise_for_status()
    return r.json()


def search(query_text, k=5, report_id=None, min_score=0):
    url = f"{SUPABASE_BASE_URL}/search"
    body = {
        "query_text": query_text,
        "k": k,
        "report_id": report_id,
        "min_score": min_score
    }
    headers = {"Authorization": f"Bearer {SUPABASE_ANON_KEY}", "Content-Type": "application/json"}
    r = requests.post(url, headers=headers, data=json.dumps(body))
    r.raise_for_status()
    return r.json()


def process_screenshot(report_id, path, bucket="session-uploads", mime="image/jpeg"):
    url = f"{SUPABASE_BASE_URL}/process-screenshot"
    body = {
        "report_id": report_id,
        "bucket": bucket,
        "path": path,
        "mime": mime
    }
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }
    r = requests.post(url, headers=headers, data=json.dumps(body))
    r.raise_for_status()
    return r.json()

# Usage example (uncomment and edit as needed):
# print(sign_upload("mysession-abc123"))
# print(sign_read("tmp/mysession-abc123/myfile.jpeg"))
# print(moderate_text("report-uuid", "Test message!"))
# print(moderate_image("report-uuid", "tmp/mysession-abc123/myfile.jpeg"))
# print(ocr_extract(path="tmp/mysession-abc123/myfile.jpeg"))
# print(ingest_text("report-uuid", "Test message!"))
# print(search("drawing competition"))
# print(process_screenshot("report-uuid", "tmp/mysession-abc123/myfile.jpeg"))
