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
    "bucket": "session-uploads",
    "path": "tmp/demo-001/test-upload-4352.jpg",
    "mime": "image/jpg"
}

url = f"{SUPABASE_BASE_URL}/process-screenshot"

if __name__ == "__main__":
    print("Sending process-screenshot request to Supabase...")
    r = requests.post(url, json=json_data, headers=headers)
    print(f"Status: {r.status_code}")
    print("Response:")
    print(r.text)
