import os
import requests
from dotenv import load_dotenv

load_dotenv()

SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
SUPABASE_BASE_URL = "https://oqjeucsmquvsitfqjsry.supabase.co/functions/v1"

HEADERS_CLIENT = {
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json"
}
HEADERS_SERVER = {
    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    "Content-Type": "application/json"
}


# If you ever need privileged ops, use SUPABASE_SERVICE_ROLE_KEY (not for client-side!)


def search(report_id, query):
    url = f"{SUPABASE_BASE_URL}/search"
    body = {"report_id": report_id, "q": query}
    resp = requests.post(url, json=body, headers=HEADERS_CLIENT)
    resp.raise_for_status()
    return resp.json()


def ingest_text(report_id, text, media_id=None):
    url = f"{SUPABASE_BASE_URL}/ingest-text"
    body = {
        "report_id": report_id,
        "media_id": media_id,
        "text": text
    }
    resp = requests.post(url, json=body, headers=HEADERS_SERVER)
    resp.raise_for_status()
    return resp.json()


def process_screenshot(report_id, bucket, path, mime):
    url = f"{SUPABASE_BASE_URL}/process-screenshot"
    body = {
        "report_id": report_id,
        "bucket": bucket,
        "path": path,
        "mime": mime
    }
    resp = requests.post(url, json=body, headers=HEADERS_SERVER)
    resp.raise_for_status()
    return resp.json()

# Example usage (uncomment and fill params to test)
# result = search('<uuid>', 'drawing competition')
# print(result)
# result = ingest_text('<uuid>', 'Test text chunk.', media_id=None)
# print(result)
# result = process_screenshot('<uuid>', 'session-uploads', 'tmp/demo-001/yourfile.jpeg', 'image/jpeg')
# print(result)
