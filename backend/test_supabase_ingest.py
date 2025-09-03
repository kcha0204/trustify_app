import os
import requests
from dotenv import load_dotenv

load_dotenv()

SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY").strip()
SUPABASE_BASE_URL = "https://oqjeucsmquvsitfqjsry.supabase.co/functions/v1"

headers = {
    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    "Content-Type": "application/json"
}

json_data = {
    "report_id": "7fb5ae78-783e-4242-87ff-88cdabce1678",
    "media_id": "6b1ef18a-696e-4520-8e8d-6d42fa35c245",
    "text": "This is a totally new test phrase 9xA47X_unique_check_2024!"
}

url = f"{SUPABASE_BASE_URL}/ingest-text"

if __name__ == "__main__":
    print("Sending ingest-text request to Supabase...")
    r = requests.post(url, json=json_data, headers=headers)
    print(f"Status: {r.status_code}")
    print("Response:")
    print(r.text)
