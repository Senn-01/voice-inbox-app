# Voice Inbox App — Project Roadmap

[Roadmap](projectRoadmap.md) | [Task](currentTask.md) | [Stack](techStack.md) | [Summary](codebaseSummary.md)

## Goals

Create a streamlined voice capture and triage system with:
1. Fast iOS voice recording
2. Automatic transcription (offline-first)
3. GPT-powered classification
4. Simple web UI for review/organization

## Features & Status

| Phase | Feature | Status | Notes |
|-------|---------|--------|-------|
| **Backend** | FastAPI + SQLite + HTMX/Alpine UI | ✅ Complete | Basic functionality implemented |
| **iOS App Structure** | SwiftUI recording interface + Services | ✅ Complete | Basic UI and recording functionality |
| **iOS Core Features** | Local database with GRDB + Sync Service | ✅ Complete | SQLite storage and sync mechanism |
| **Testing & Deployment** | Backend tests and deployment config | ✅ Complete | Pytest and Fly.io configuration |
| **Final Implementation** | Deploy to Fly.io | ✅ Complete | Backend live at https://voice-inbox-api.fly.dev/ |
| **Core ML Integration** | Whisper-tiny Core ML | 🔄 In Progress | Implementing offline transcription |
| **Release** | Final testing and documentation | 📅 Planned | Preparing for v1.0.0 |

## Completion Criteria

**MVP Release:**
- iOS app can record voice memos
- Server-side Whisper transcription
- FastAPI backend with SQLite storage
- Basic HTMX + Alpine.js web interface
- Docker deployment ready

## Current Progress

- ✅ Backend with FastAPI and SQLite
- ✅ Web UI with HTMX and Alpine.js
- ✅ Classification endpoint with GPT-4.1-mini
- ✅ iOS app with SwiftUI recording interface
- ✅ GRDB integration for local storage
- ✅ Synchronization service
- ✅ Testing with pytest for backend
- ✅ Deployment configuration for Fly.io
- ✅ Deployment to Fly.io (https://voice-inbox-api.fly.dev/)
- ✅ Backend Whisper transcription endpoint
- 🔄 iOS integration with backend transcription

## Deployment Instructions

To deploy the backend to Fly.io:

1. Install the Fly CLI: `brew install flyctl`
2. Login to Fly: `fly auth login`
3. Navigate to the backend directory: `cd voice-inbox/backend`
4. Create a volume for data persistence: `fly volumes create voice_inbox_data --size 1`
5. Deploy the app: `fly deploy`
6. Set the OpenAI API key: `fly secrets set OPENAI_API_KEY=your_key_here`

## Next Steps after MVP

1. Widget & Siri shortcut integration
2. Goal-driven daily in-app summary
3. Voice-only triage mode
4. Bidirectional links by UUID

## Version History
- 2023-07-17  v0.1  Initial roadmap based on project spec
- 2023-07-17  v0.2  Updated with implementation progress
- 2023-07-17  v0.3  Updated with GRDB and sync implementation
- 2023-07-17  v0.4  Updated with testing and deployment progress 