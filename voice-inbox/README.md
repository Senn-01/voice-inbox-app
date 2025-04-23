# Voice Inbox App

Capture voice thoughts on iOS, auto-transcribe, then triage from a ultra-thin FastAPI + SQLite web UI.

## Project Structure

- **`backend/`**: FastAPI server with SQLite database
- **`ios/`**: iOS SwiftUI app (to be implemented)
- **`cursor_docs/`**: Project documentation

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
   docker run -p 8000:8000 --env-file .env -v ./audio:/app/audio voice-inbox-backend
   ```

## iOS App (Coming Soon)

The iOS app will be implemented in the next phase.

## Features

- Record voice memos on iOS
- Automatic transcription using Whisper Core ML
- Fallback to OpenAI API for transcription
- GPT-4.1-mini for smart classification
- Simple web UI for review and organization

## Documentation

See the `cursor_docs/` directory for detailed project documentation. 