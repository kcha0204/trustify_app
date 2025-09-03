import os
import requests
import json
from dotenv import load_dotenv

load_dotenv()

SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")


def test_sign_upload():
    url = "https://oqjeucsmquvsitfqjsry.supabase.co/functions/v1/sign-upload"
    data = {"sessionId": "test-session-123"}

    print("Testing sign-upload with no auth...")
    r1 = requests.post(url, headers={'Content-Type': 'application/json'}, data=json.dumps(data))
    print(f"No Auth: {r1.status_code} - {r1.text}")

    print("\nTesting sign-upload with Anon Key...")
    r2 = requests.post(url, headers={
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}'
    }, data=json.dumps(data))
    print(f"Anon Key: {r2.status_code} - {r2.text}")

    print("\nTesting sign-upload with Service Role Key...")
    r3 = requests.post(url, headers={
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY}'
    }, data=json.dumps(data))
    print(f"Service Role: {r3.status_code} - {r3.text}")


if __name__ == "__main__":
    test_sign_upload()
