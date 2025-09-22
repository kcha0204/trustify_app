# Trustify – Teen Cyber Safety Platform

A Flutter app that helps teenagers identify and respond to cyberbullying, harmful content, and
online risks. Trustify uses Azure services end‑to‑end: secure serverless APIs, managed identity
access to data, and content safety.

## What’s inside

* AI Content Detection (Text & Images) via Azure Functions + Azure Content Safety
* Ask Ally conversational mentor via Azure Q&A Function
* Victoria Cyber Dashboard (VCAMS) with real data from Azure SQL through Azure Functions
* Gamified UI/UX, quizzes, audio cues, and a teen-first visual language

## Key Features

* AI Content Detection: Text and image analysis with actionable feedback
* Screenshot Analysis: OCR + safety analysis for social media screenshots
* Teen‑friendly UX: Compact data summaries, analysis chips, and trend/breakdown narratives
* Real‑time Dashboard: Statewide trend and breakdown charts with live, filter‑aware analysis
* Secure by default: All APIs require function keys; no hardcoded secrets in code

## Prerequisites

### Frontend

* Flutter SDK 3.9+
* Android Studio or VS Code
* Android device/emulator or iOS simulator

### Azure (already provisioned for this app)

* Azure Functions (Python) for:
    - Content Analysis API
    - Q&A API
    - VCAMS Data API (reads Azure SQL via Managed Identity)
* Azure SQL Database with VCAMS table/view:
  `state, indicator, subdivision_type, subdivision_value, year, value`

## Setup Instructions

### 1) Clone
```bash
git clone <your-repo-url>
cd trustify_app
```

### 2) Environment (.env)

The app reads configuration from a Flutter‑bundled `.env` file. Update the values if your Azure
hostnames/keys change.

`./.env` (already referenced in `pubspec.yaml` assets):
```
# Azure Functions — Content Analysis
FUNC_ANALYSIS_BASE=https://<your-analysis-func>.azurewebsites.net
FUNC_ANALYSIS_HOST_KEY=<FUNCTION_KEY>

# Azure Functions — Q&A (Ask Ally)
FUNC_QA_BASE=https://<your-qa-func>.azurewebsites.net
FUNC_QA_HOST_KEY=<FUNCTION_KEY>

# Azure Functions — VCAMS Data API
VCAMS_API_BASE=https://<your-vcams-func>.azurewebsites.net/api/v1
VCAMS_API_KEY=<FUNCTION_KEY>
```

These are used by the Flutter services:

- `lib/services/azure_api.dart` (analysis)
- `lib/services/azure_qna_api.dart` (Ask Ally)
- `lib/services/vcams_api.dart` (dashboard)

No Supabase is used. All data and AI are served from Azure Functions.

### 3) Install Flutter dependencies
```bash
# From project root
flutter pub get
```

### 4) Run the app
```bash
flutter run
```

## Using the app

### Content Detection (Scan & Protect)

Open the app → Scan & Protect → Paste text or pick an image. The app uploads to the Azure Analysis
Function (securely with a function key), and displays AI‑driven feedback within seconds.

### Text Analysis:
1. Paste text in the input field
2. Tap **"Analyze"**
3. View detailed results with risk categories

### Image Analysis:
1. Tap **"Use Camera"** or **"Pick Photo"**
2. Select/capture an image
3. Tap **"Analyze"**
4. View OCR text and safety analysis

### Interpret Results
**Risk Levels:**
- **Safe**: No harmful content detected
- **Low**: Minor concerns, monitor content
- **Medium**: Potentially harmful, take precautions
- **High**: Serious threats, seek help immediately

**Categories Analyzed:**
- Hate 
- Self-harm 
- Sexual Abuse
- Violence


## Services (in the app)

* `lib/services/azure_api.dart` – wraps the Azure Analysis Function (text/image)
* `lib/services/azure_qna_api.dart` – Ask Ally Q&A Function client
* `lib/services/vcams_api.dart` – VCAMS Data API client (indicators, series, breakdown)

## Victoria Cyber Dashboard

The dashboard pulls data from Azure SQL via the VCAMS Azure Function. In‑app, it:

- Lists indicators and breakdown types
- Shows Statewide trend by year
- Shows single‑year breakdown (bar or pie depending on count)
- Displays legend/axis boxes and engaging teen‑friendly analysis that updates live with filters

Optional (for web testing only): a Dash prototype is available in `backend/dashboard/scripts/`:

```bash
cd backend/dashboard/scripts
pip install -r requirements.txt
python dashboard_server.py
```

This is NOT required for the Flutter app.

## Troubleshooting

**API 401/403**

- Ensure the function key in `.env` matches Azure Functions → App Keys

**VCAMS SQL timeout / HYT00**

- Confirm Azure Function has Managed Identity enabled
- In Azure SQL DB, create user from external provider and grant `db_datareader` + `SELECT` on the
  table/view
- SQL Server firewall must allow Azure services or your function’s VNet
- Check `SQL_SERVER`, `SQL_DB`, `SQL_SCHEMA`, `SQL_TABLE` app settings on the Function App

## Future Enhancements

* [ ] Multiple language support
* [ ] Offline mode for basic detection
* [ ] Parent/teacher dashboard
* [ ] Real‑time chat guidance & reporting

## Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support
For support and questions:
- Create an issue on GitHub
- Check Azure Functions and Azure Content Safety documentation

## Acknowledgments

* Azure Functions, Azure Content Safety, and Azure SQL
* Flutter team and the open source community

## License

This project is licensed under the MIT License - see the LICENSE file for details.
