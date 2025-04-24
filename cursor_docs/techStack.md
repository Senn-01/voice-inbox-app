# Voice Inbox App — Tech Stack

[Roadmap](projectRoadmap.md) | [Task](currentTask.md) | [Stack](techStack.md) | [Summary](codebaseSummary.md)

## Technology Stack

| Layer | Technology | Version |
|-------|------------|---------|
| **Mobile App** | SwiftUI + Combine | iOS 15+ |
| **Mobile DB** | SQLite via GRDB | 6.x |
| **Transcription** | Whisper (backend) | OpenAI Whisper "tiny" |
| **Backend** | FastAPI | 0.111.0 |
| **Server DB** | SQLite | 3.x |
| **LLM** | OpenAI API (GPT-4.1-mini) | Latest |
| **Web UI** | HTMX + Alpine.js | 1.9.8, 3.x |
| **Deployment** | Docker + Fly.io | Python 3.11 slim |

## Architecture Overview

1. **iOS App**: 
   - SwiftUI for UI components
   - MVVM architecture pattern
   - AVAudioRecorder for voice capture
   - Combine for reactive programming
   - GRDB for SQLite interactions
   - HTTP multipart/form-data for audio upload

2. **Backend**:
   - FastAPI for API endpoints
   - Whisper for speech-to-text transcription
   - SQLite for data storage
   - OpenAI API for classification
   - HTMX + Alpine.js for web UI
   - FFmpeg for audio processing

3. **Deployment**:
   - Docker containerization
   - Fly.io for hosting

## Decision Records

| Date | Decision | Alternatives | Reasoning |
|------|----------|--------------|-----------|
| 2023-07-17 | SQLite for backend | PostgreSQL, Supabase | Simplicity for MVP; single-user focused; zero-config |
| 2023-07-17 | Backend Whisper | Whisper-tiny Core ML | Simpler iOS app; consistent transcriptions; less device battery usage |
| 2023-07-17 | HTMX + Alpine.js | React, Vue | No build step; simpler development; lighter-weight |
| 2023-07-17 | FastAPI | Flask, Django | Async support; modern API design; type hints |
| 2023-07-17 | Fly.io | Heroku, Vercel | Simple deployment; volume support for SQLite persistence |
| 2023-07-18 | Python 3.11 | Python 3.12 | Better compatibility with Whisper and dependencies |

## Docker Configuration
- Python 3.11 slim base image
- FFmpeg for audio processing
- Git for Whisper installation
- 1GB memory allocation for transcription

## Security Considerations

- HTTPS for all API communications
- Basic authentication for web UI (MVP)
- OpenAI API key stored in environment variables / secrets
- SQLite database file permissions set appropriately

## Version History
- 2023-07-17  v0.1  Initial tech stack documentation
- 2023-07-18  v0.2  Updated with deployed Whisper configuration 