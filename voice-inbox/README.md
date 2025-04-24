# Voice Inbox App

Capture voice thoughts on iOS, auto-transcribe, then triage from a ultra-thin FastAPI + SQLite web UI.

**GitHub Repository**: [https://github.com/Senn-01/voice-inbox-app](https://github.com/Senn-01/voice-inbox-app)

**Live Demo**: [https://voice-inbox-api.fly.dev/](https://voice-inbox-api.fly.dev/)

## Project Structure

- **`backend/`**: FastAPI server with SQLite database and Whisper transcription
- **`ios/`**: iOS SwiftUI app with backend API integration
- **`cursor_docs/`**: Project documentation

## API Endpoints

- **`/`**: Web UI for viewing and managing voice notes
- **`/inbox`**: POST endpoint for adding new notes (multipart/form-data with text and optional audio)
- **`/transcribe`**: POST endpoint for transcribing audio (multipart/form-data with audio file)
- **`/classify/{item_id}`**: POST endpoint for classifying notes using GPT-4.1-mini

**Note**: The `/transcribe` endpoint requires a POST request with an audio file, not a GET request:
```bash
curl -F "audio=@sample.m4a" https://voice-inbox-api.fly.dev/transcribe
```

## Backend Setup

1. Navigate to the backend directory:
   ```
   cd backend
   ```

2. Create a virtual environment (optional but recommended):
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```
   pip install -r requirements.txt
   pip install git+https://github.com/openai/whisper.git
   ```

4. Create a `.env` file with your OpenAI API key:
   ```
   OPENAI_API_KEY=your_openai_api_key_here
   ```

5. Run the server:
   ```
   uvicorn api:app --reload
   ```

6. Open your browser to [http://localhost:8000](http://localhost:8000)

## Docker Deployment

1. Build the Docker image:
   ```
   cd backend
   docker build -t voice-inbox-backend .
   ```

2. Run the container:
   ```
   docker run -p 8000:8000 --env-file .env -v ./data:/app/data voice-inbox-backend
   ```

## Fly.io Deployment

The app is deployed on Fly.io at [https://voice-inbox-api.fly.dev/](https://voice-inbox-api.fly.dev/).

### Automatic Deployment

Use our deployment script for a simpler process:

1. Navigate to the backend directory: `cd voice-inbox/backend`
2. Make the script executable: `chmod +x deploy-to-fly.sh`
3. Run the script: `./deploy-to-fly.sh`

The script will:
- Check if flyctl is installed
- Verify login status
- Create a Fly.io app if needed
- Create a volume if needed
- Prompt for your OpenAI API key if not set
- Deploy the application
- Open the app in your browser

### Manual Deployment

To deploy your own instance manually:

1. Install the Fly CLI: `brew install flyctl`
2. Login: `fly auth login`
3. Navigate to the backend directory: `cd voice-inbox/backend`
4. Create a Fly app: `fly launch --name voice-inbox-api`
5. Create a volume: `fly volumes create voice_inbox_data --size 1 --app voice-inbox-api`
6. Deploy: `fly deploy`
7. Set API key: `fly secrets set OPENAI_API_KEY=your_key_here`

### Troubleshooting

If you encounter issues with deployment:

- **"App not found" error**: Make sure to create the app first with `fly launch` before creating volumes or setting secrets
- **Database connection issues**: Verify the volume is correctly mounted in `fly.toml`
- **Whisper model loading issues**: If you see memory errors, try increasing VM memory in `fly.toml` or switching to the "tiny" model
- **Deployment failures**: Check logs with `fly logs` for detailed error messages

For more detailed troubleshooting, see [Fly.io Deployment Guide](cursor_docs/flyioDeployment.md) in the documentation.

## iOS App

The iOS app includes:
- SwiftUI interface for voice recording
- Backend API integration for transcription and storage
- Local SQLite database using GRDB
- Synchronization with backend

## Features

- Record voice memos on iOS
- Server-side transcription using Whisper
- GPT-4.1-mini for smart classification
- Simple web UI for review and organization

## Database

The app uses SQLite for both the iOS app and backend:
- Backend: SQLite database stored in a persistent Fly.io volume
- iOS: Local SQLite database using GRDB with synchronization

## Documentation

See the `cursor_docs/` directory for detailed project documentation. 