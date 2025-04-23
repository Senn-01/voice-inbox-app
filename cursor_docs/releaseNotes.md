# Voice Inbox App — Release Notes

[Roadmap](projectRoadmap.md) | [Task](currentTask.md) | [Stack](techStack.md) | [Summary](codebaseSummary.md)

## Development Versions

### v0.1.0 — Initial Setup (Completed)
- Project structure created
- Core documentation established
- Backend skeleton implementation

### v0.2.0 — Backend Implementation (Completed)
- FastAPI backend with SQLite database
- Basic HTMX + Alpine.js web UI
- `/inbox` and `/items` endpoints
- `/classify/{item_id}` endpoint for GPT-4.1 classification
- Docker configuration

### v0.3.0 — iOS App Structure (Completed)
- Basic SwiftUI interface with recording button
- RecorderViewModel for audio recording
- Placeholder services for transcription and API
- Proper app permissions configuration

### v0.4.0 — iOS Core Features (Completed)
- GRDB integration for local SQLite storage
- Synchronization service implementation
- UI updated with sync status and controls
- Swift Package Manager configuration

### v0.5.0 — Testing & Deployment (Completed)
- Backend tests with pytest
- iOS database tests
- Database paths updated for deployment
- Fly.io configuration added
- Deployment instructions documented

### v0.6.0 — Final Implementation (In Progress)
- Deploy to Fly.io
- Implement Whisper-tiny Core ML integration
- Test full system with real data
- Final documentation updates

### v1.0.0 — MVP Release (Planned)
- Production-ready backend and iOS app
- Complete deployment configuration
- Documented API and functionality
- Ready for user testing

## Production Releases

*No production releases yet*

## Deployment Instructions

To deploy the backend to Fly.io:

1. Install the Fly CLI: `brew install flyctl`
2. Login to Fly: `fly auth login`
3. Navigate to the backend directory: `cd voice-inbox/backend`
4. Create a volume for data persistence: `fly volumes create voice_inbox_data --size 1`
5. Deploy the app: `fly deploy`
6. Set the OpenAI API key: `fly secrets set OPENAI_API_KEY=your_key_here`

## Version History
- 2023-07-17  v0.1  Initial release notes
- 2023-07-17  v0.2  Updated with implementation progress
- 2023-07-17  v0.3  Updated with iOS GRDB and synchronization implementation
- 2023-07-17  v0.4  Updated with testing and deployment progress 