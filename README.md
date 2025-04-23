# Voice Inbox App

Capture voice thoughts on iOS, auto-transcribe, then triage from a ultra-thin FastAPI + SQLite web UI.

## Project Overview

Voice Inbox is an iOS app paired with a FastAPI backend that allows users to:
- Record voice memos on their iOS device
- Automatically transcribe the audio using Whisper (on-device or via API)
- Store recordings locally with synchronization to the backend
- Classify and organize notes using GPT-4.1-mini
- Review and triage notes from a simple web interface

## Repository Structure

- `/voice-inbox/` - Main project folder
  - `/backend/` - FastAPI server with SQLite database
  - `/ios/` - iOS SwiftUI app
- `/cursor_docs/` - Project documentation

## Technology Stack

- **iOS**: SwiftUI, Combine, GRDB (SQLite), AVFoundation
- **Backend**: FastAPI, SQLite, OpenAI API
- **Web UI**: HTMX + Alpine.js
- **Deployment**: Docker, Fly.io

## Getting Started

See the individual README files in the respective directories:
- [iOS App README](voice-inbox/ios/README.md) (coming soon)
- [Backend README](voice-inbox/README.md)

## Documentation

Detailed documentation is available in the `cursor_docs/` directory:
- [Project Roadmap](cursor_docs/projectRoadmap.md)
- [Current Task](cursor_docs/currentTask.md)
- [Tech Stack](cursor_docs/techStack.md)
- [Codebase Summary](cursor_docs/codebaseSummary.md)
- [Test Plan](cursor_docs/testPlan.md)
- [Release Notes](cursor_docs/releaseNotes.md)

## License

MIT 