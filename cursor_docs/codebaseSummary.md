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
   - Whisper-tiny Core ML transcribes audio on-device
   - Falls back to OpenAI API if needed
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
| OpenAI API | Transcription fallback, classification | openai.com |
| Whisper-tiny | On-device transcription | huggingface.co |
| HTMX | HTML-based AJAX | htmx.org |
| Alpine.js | Minimal JavaScript framework | alpinejs.dev |
| GRDB | Swift SQLite wrapper | github.com/groue/GRDB.swift |
| FastAPI | Python API framework | fastapi.tiangolo.com |

## Additional Documentation

- [Project-spec.md](Project-spec.md) - Original project specification
- [advices.md](advices.md) - Implementation notes and warnings

## Version History
- 2023-07-17  v0.1  Initial codebase structure documentation 