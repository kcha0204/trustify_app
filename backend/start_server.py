#!/usr/bin/env python3
"""
Startup script for Trustify Content Analysis Server
"""
import os
import sys
import subprocess
from pathlib import Path


# Requires: AI server at ai_module/ai_api.py (on :8081), Uvicorn, Python 3.9+, dashboard_api.py in backend

def check_env_file():
    """Check if .env file exists and has required variables"""
    env_path = Path(__file__).parent / '.env'
    if not env_path.exists():
        print("❌ .env file not found!")
        print("Please create backend/.env with your Azure Content Safety credentials:")
        print("AZURE_CONTENT_SAFETY_KEY=your_key_here")
        print("AZURE_CONTENT_SAFETY_ENDPOINT=https://your-resource.cognitiveservices.azure.com")
        return False
    
    # Read .env file and check for placeholder values
    env_content = env_path.read_text()
    if 'YOUR_KEY' in env_content or '<your-resource>' in env_content:
        print("❌ Please update .env file with your actual Azure credentials!")
        print("Current .env file contains placeholder values.")
        return False
    
    print("✅ .env file found and configured")
    return True

def check_dependencies():
    """Check if all required Python packages are installed"""
    try:
        import fastapi
        import uvicorn
        import azure.ai.contentsafety
        import easyocr
        import PIL
        print("✅ All Python dependencies are installed")
        return True
    except ImportError as e:
        print(f"❌ Missing dependency: {e}")
        print("Run: pip install -r requirements.txt")
        return False

def main():
    print("🚀 Starting Trustify Content Analysis Server...")
    print("="*50)
    
    # Change to backend directory
    backend_dir = Path(__file__).parent
    os.chdir(backend_dir)
    
    # Check requirements
    if not check_env_file():
        sys.exit(1)
    
    if not check_dependencies():
        sys.exit(1)
    
    print("✅ All checks passed!")
    print("🌐 Starting server on http://0.0.0.0:8080")
    print("📱 Flutter app should use http://118.138.91.225:8080 for real device")
    print("📱 For Android emulator, use http://10.0.2.2:8080")
    print("="*50)
    
    # Start the server
    try:
        # Start AI FastAPI app
        ai_server = subprocess.Popen(
            [sys.executable, "-m", "uvicorn", "ai_module.ai_api:app", "--host", "0.0.0.0", "--port",
             "8081"]
        )
        # Start dashboard API with Uvicorn
        dash_server = subprocess.Popen(
            [sys.executable, "-m", "uvicorn", "dashboard_api:app", "--host", "0.0.0.0", "--port",
             "8080"]
        )
        try:
            ai_server.wait()
            dash_server.wait()
        finally:
            ai_server.terminate()
            dash_server.terminate()
    except KeyboardInterrupt:
        print("\n👋 Server stopped by user")
    except subprocess.CalledProcessError as e:
        print(f"❌ Server failed to start: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()