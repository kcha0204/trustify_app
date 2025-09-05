# Trustify - Teen Cyber Safety Platform

A comprehensive Flutter app with AI-powered content detection using Azure Content Safety APIs to
help teenagers identify and respond to cyberbullying, harmful content, and online threats.

## Features

- AI Content Detection: Analyze text and images for harmful content using Azure Content Safety
- Screenshot Analysis: OCR + Content analysis for social media screenshots
- Gaming UI: Teen-friendly interface with cyber/gaming aesthetics
- Real-time Analysis: Instant feedback on potentially harmful content
- Detailed Results: Category-wise risk assessment and confidence scores

## Architecture
### Frontend (Flutter)

- Modular structure with separate pages and services
- Gaming-themed UI designed for teenagers
- Image picker for camera/gallery integration
- HTTP client for backend communication

### Backend (Python + FastAPI)

- Azure Content Safety integration for text analysis
- EasyOCR for extracting text from images
- RESTful API with async processing
- Environment-based configuration

## Prerequisites
### For Backend:
- Python 3.8 or higher
- Azure Content Safety resource (Azure Portal)
- Internet connection for AI API calls

### For Frontend:
- Flutter SDK 3.0+
- Android Studio / VS Code
- Android device or emulator

## Setup Instructions
### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd trustify_app
```

### 2. Backend Setup
#### a) Install Python Dependencies
```bash
cd backend
pip install -r requirements.txt
```

#### b) Configure Azure Credentials
1. Go to [Azure Portal](https://portal.azure.com)
2. Create a new **Content Safety** resource
3. Copy the **Key** and **Endpoint**
4. Create `.env` file in the `backend` directory:
```bash
# Copy the example file
cp .env.example .env
```
Edit `.env` file:
```
AZURE_CONTENT_SAFETY_KEY=your_actual_azure_key_here
AZURE_CONTENT_SAFETY_ENDPOINT=https://your-resource-name.cognitiveservices.azure.com
```

#### c) Test Backend Setup
```bash
python start_server.py
```
The server should start on `http://localhost:8080`

### 3. Frontend Setup
#### a) Install Flutter Dependencies
```bash
# From project root
flutter pub get
```

#### b) Configure Network Access
**For Android Emulator:**
- The app is pre-configured to use `http://10.0.2.2:8080`
- This should work automatically

**For Real Android Device:**
1. Find your computer's IP address:
    - Windows: `ipconfig`
    - Mac/Linux: `ifconfig`
2. Update `lib/launch/content_detection_page.dart`:

```dart
const String kAnalyzerBaseUrl = 'http://YOUR_COMPUTER_IP:8080';
```

#### c) Run the App
```bash
flutter run
```

## Usage
### 1. Start Backend Server
```bash
cd backend
python start_server.py
```

### 2. Launch Flutter App
- Open the app on your device/emulator
- Navigate to **"SCAN & PROTECT"**

### 3. Analyze Content
#### Text Analysis:
1. Paste text in the input field
2. Tap **"Analyze"**
3. View detailed results with risk categories

#### Image Analysis:
1. Tap **"Use Camera"** or **"Pick Photo"**
2. Select/capture an image
3. Tap **"Analyze"**
4. View OCR text and safety analysis

### 4. Interpret Results
**Risk Levels:**

- **Safe**: No harmful content detected
- **Low**: Minor concerns, monitor content
- **Medium**: Potentially harmful, take precautions
- **High**: Serious threats, seek help immediately

**Categories Analyzed:**
- Hate speech
- Self-harm content
- Sexual content
- Violence
- Harassment

## Development
### Backend API Endpoints
#### Analyze Text
```bash
POST /analyze/text
Content-Type: application/json

{
  "text": "Your text content here"
}
```

#### Analyze Screenshot
```bash
POST /analyze/screenshot
Content-Type: multipart/form-data

file: <image_file>
```

### Adding New Features
1. **New AI Providers**: Add to `backend/ai_module/providers/`
2. **UI Components**: Create in `lib/launch/` or `lib/widgets/`
3. **Services**: Add to `lib/services/`

## Troubleshooting
### Backend Issues
**"Missing Azure credentials"**
- Ensure `.env` file exists with valid Azure keys
- Check Azure resource is active

**"Import errors"**
- Run: `pip install -r requirements.txt`
- Ensure Python 3.8+

**"Server won't start"**
- Check port 8080 is available
- Try: `python -m uvicorn server:app --host 0.0.0.0 --port 8080`

### Frontend Issues
**"Network connection failed"**
- Ensure backend server is running
- Check IP address configuration for real devices
- Verify firewall allows port 8080

**"Image picker not working"**
- Check camera/storage permissions
- Test on real device (emulator camera is limited)

**"Build errors"**
- Run: `flutter clean && flutter pub get`
- Check Flutter SDK version

## Testing
### Test Scenarios
#### Safe Content:
- "Have a great day!"
- "What's your favorite movie?"

#### Potentially Harmful:
- "You're so stupid"
- "I hate you"
- "Kill yourself"

#### Screenshots:
- Social media posts with text
- Chat conversations
- Memes with text overlays

## Security & Privacy
- **No data storage**: Content is analyzed in real-time, not stored
- **Azure Content Safety**: Enterprise-grade AI with privacy protections
- **Local processing**: OCR and image handling done locally when possible
- **HTTPS ready**: Easy to configure SSL for production

## Future Enhancements
- [ ] Multiple language support
- [ ] Offline mode for basic detection
- [ ] Reporting and blocking features
- [ ] Parent/teacher dashboard
- [ ] Machine learning model training
- [ ] Real-time chat monitoring

## Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Support
For support and questions:
- Create an issue on GitHub
- Contact the development team
- Check Azure Content Safety documentation

## Acknowledgments
- Azure Content Safety API for AI-powered content analysis
- EasyOCR for optical character recognition
- Flutter team for the amazing framework
- Open source community for various packages used
