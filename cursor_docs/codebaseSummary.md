# Voice Inbox App — Codebase Summary

[Roadmap](projectRoadmap.md) | [Task](currentTask.md) | [Stack](techStack.md) | [Summary](codebaseSummary.md)

## Project Structure

```
voice-inbox/
├── backend/                 # FastAPI server
│   ├── api.py               # Main API endpoints
│   ├── database.py          # SQLite connection handling
│   ├── models.py            # Data models
│   ├── templates/           # HTMX templates
│   ├── requirements.txt     # Python dependencies
│   └── Dockerfile           # Backend container
│
├── ios/                     # iOS SwiftUI app
│   ├── VoiceInbox/          # Main app code
│   │   ├── Views/           # SwiftUI views
│   │   ├── ViewModels/      # MVVM view models
│   │   ├── Models/          # Data models
│   │   ├── Services/        # API, recording, transcription
│   │   └── Utils/           # Helpers
│   └── VoiceInboxTests/     # Unit tests
│
└── cursor_docs/             # Project documentation
    ├── projectRoadmap.md    # Goals and roadmap
    ├── currentTask.md       # Current tasks and progress
    ├── techStack.md         # Technology decisions
    ├── codebaseSummary.md   # This file
    ├── testPlan.md          # Testing approach
    └── releaseNotes.md      # Version changes
```

## Data Flow

1. **Capture**
   - User records audio in iOS app
   - AVAudioRecorder creates AAC file
   - SwiftUI updates UI state via ViewModel

2. **Transcribe**
   - iOS app sends audio file to backend `/transcribe` endpoint
   - Backend uses Whisper to transcribe audio
   - Transcription result returned to iOS app
   - Text stored in local SQLite via GRDB

3. **Persist**
   - iOS app POSTs data to backend `/inbox` endpoint
   - FastAPI processes request and stores in SQLite
   - Audio file optionally saved on server

4. **Review/Sort**
   - User views inbox in web UI via HTMX
   - Classifies notes via GPT-4.1-mini
   - Tags, edits, archives items

## External Dependencies

| Dependency | Purpose | Source |
|------------|---------|--------|
| OpenAI API | Classification | openai.com |
| Whisper | Backend transcription | github.com/openai/whisper |
| HTMX | HTML-based AJAX | htmx.org |
| Alpine.js | Minimal JavaScript framework | alpinejs.dev |
| GRDB | Swift SQLite wrapper | github.com/groue/GRDB.swift |
| FastAPI | Python API framework | fastapi.tiangolo.com |

## Additional Documentation

- [Project-spec.md](Project-spec.md) - Original project specification
- [advices.md](advices.md) - Implementation notes and warnings

## Version History
- 2023-07-17  v0.1  Initial codebase structure documentation 

## Deployment

### Backend API
- Deployed to Fly.io at `https://voice-inbox-api.fly.dev/`
- Complete with Whisper transcription endpoint
- Using Docker containerization with Python 3.11
- Includes FFmpeg for audio processing
- 1GB persistent volume for SQLite database storage
- Environment variables configured via Fly.io secrets
- Deployment steps documented in `currentTask.md`
- Potential issues and solutions documented in troubleshooting section

### iOS App
- Will be distributed via TestFlight for testing
- Production distribution will use App Store Connect
- Currently configured to use backend transcription

### Monitoring
- Basic logging implemented via Fly.io built-in logs
- Can view logs with `fly logs` command
- Health check endpoint planned

## Troubleshooting

### Fly.io Deployment
- If app shows as "suspended": Use `fly apps restart <app-name>`
- If machines show as "stopped": Use `fly machines start <machine-id>`
- If deployment fails: Check logs with `fly logs`
- Performance issues: Consider upgrading machine size

## Version History
- 2023-07-17  v0.1  Initial codebase structure documentation
- 2023-07-18  v0.2  Updated with deployed backend information 