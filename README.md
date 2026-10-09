# FaceMatch

A face similarity matching prototype built with **Flutter**, **FastAPI**, and **InsightFace**. The application captures a selfie using the phone's front camera, accepts a reference image from the gallery, and compares the two faces to produce a similarity score and a `MATCH` or `NO_MATCH` result.

## Features

- Front-camera selfie capture with a face guide overlay.
- Retake selfies and select or replace reference images from the gallery.
- Face detection and validation for exactly one face per image.
- Face embeddings generated using InsightFace's `buffalo_l` model.
- Cosine similarity calculation between face embeddings.
- Similarity score and match decision displayed in the app.
- FastAPI backend with JSON responses and error handling.

## Technology Stack

| Component | Technology |
|---|---|
| Mobile application | Flutter, Dart |
| Backend API | Python, FastAPI |
| Face analysis | InsightFace (`buffalo_l`) |
| Image processing | OpenCV, NumPy |
| API communication | HTTP multipart/form-data |
| API server | Uvicorn |

## Architecture

The Flutter application runs on an Android phone. It sends the captured selfie and selected reference image to the FastAPI backend, which runs on the development computer.

The backend detects faces, generates embeddings, calculates cosine similarity, and returns the comparison result to the app.

See [`docs/architecture.md`](docs/architecture.md) for the architecture diagram.

## Project Structure

```text
FaceMatch/
├── .gitignore
├── README.md
├── docs/
│   └── architecture.md
├── facematch_app/
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── linux/
│   ├── windows/
│   ├── macos/
│   └── pubspec.yaml
└── facematch_backend/
    ├── app/
    │   ├── __init__.py
    │   ├── main.py
    │   └── face_matcher.py
    └── requirements.txt
```

## Prerequisites

- Python installed on the computer running the backend.
- Flutter SDK and Dart installed.
- Android SDK and a physical Android device or emulator.
- Git.
- An internet connection for initial dependency and face-model downloads, when required.

## Backend Setup

Open a terminal in the project root and run:

```powershell
cd facematch_backend

python -m venv venv

.\venv\Scripts\Activate.ps1

pip install -r requirements.txt
```

If PowerShell blocks virtual-environment activation, use a terminal configured to activate Python environments or follow the Python environment instructions for your system.

Start the API server:

```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

The backend should now be available on port `8000`.

Useful endpoints:

- `GET /` — API health check.
- `POST /match` — compares the submitted images.
- `/docs` — interactive API documentation provided by FastAPI.

For example, the health check can be opened at `http://127.0.0.1:8000/` on the computer running the server.

The InsightFace model may need to download its model files the first time it runs.

## Flutter Setup

Open a separate terminal:

```powershell
cd facematch_app

flutter pub get
```

Configure the application to use the backend URL through the `API_BASE_URL` Dart environment variable.

For a physical Android phone, replace `YOUR_LAPTOP_LAN_IP` with the computer's current private LAN IP address:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_LAPTOP_LAN_IP:8000
```

For an Android emulator, the host computer is commonly reachable through:

```text
http://10.0.2.2:8000
```

The app and computer must be able to communicate over the network. For a physical device, they will generally need to be on the same Wi-Fi network. Windows Firewall may need an appropriate rule to allow the backend connection.

**Development note:** These examples use plain HTTP for local development. Do not expose the development server directly to the public internet.

## API Reference

### `POST /match`

Accepts two image files as multipart form data.

| Field | Type | Description |
|---|---|---|
| `selfie` | File | Selfie image captured in the app |
| `reference` | File | Reference image selected from the gallery |

Example successful response:

```json
{
  "success": true,
  "similarity": 0.65,
  "score": 81,
  "result": "MATCH"
}
```

The values above are illustrative and do not represent a guaranteed output for any particular pair of images.

The `similarity` value represents cosine similarity between the generated face embeddings. The `score` is a normalized, clamped presentation score. `result` indicates whether the similarity meets the configured match threshold.

The backend returns HTTP `400` for image-validation errors and HTTP `500` for unexpected server errors.

## Similarity Scoring

The prototype uses cosine similarity to compare the two face embeddings.

The current backend uses:

- Match threshold: `0.40`
- Score reference: `0.80`

The presentation score is calculated as:

```text
score = round((similarity / 0.80) * 100)
score is clamped to the range 0–100
```

A result is labelled `MATCH` when cosine similarity is at least `0.40`; otherwise, it is labelled `NO_MATCH`.

**Important:** The displayed score is not a probability, identity confidence percentage, or proof that two images belong to the same person. The threshold and score mapping are prototype settings and have not been established as suitable for security-critical use.

## Limitations

- The current setup uses a backend running on a development computer.
- The backend performs face analysis on the CPU.
- Image quality, lighting, face angle, occlusion, and detection quality can affect results.
- The match threshold has not been validated for a specific real-world population or use case.
- This prototype should not be used for authentication, access control, surveillance, or other high-stakes identity decisions.

## Privacy and Security

- Use only images you have permission to process.
- Do not commit personal test photos, private datasets, credentials, or local configuration files.
- Uploaded images are read into memory by the current API handler for processing. Avoid adding image logging or persistent storage without explicitly reviewing the privacy implications.
- The local development configuration uses HTTP and is not intended for production deployment.
- Production use would require a security and privacy review, secure transport, appropriate access controls, and validated matching performance.

## License

No license has been specified yet. All rights and permissions remain with their respective owners unless a license is added to this repository.