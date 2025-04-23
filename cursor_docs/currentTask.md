# Voice Inbox App — Current Task

[Roadmap](projectRoadmap.md) | [Task](currentTask.md) | [Stack](techStack.md) | [Summary](codebaseSummary.md)

## Current Objective

Set up the project structure and implement the MVP components:

1. Create the FastAPI backend with SQLite database
2. Build the iOS SwiftUI recording interface
3. Implement the transcription service
4. Create the basic web UI with HTMX + Alpine.js
5. Add tests and deployment configuration

## Context

We're starting from the project specification in `Project-spec.md` and implementing the MVP phase. Based on the advice in `advices.md`, we'll need to be careful about several potential issues including permissions, concurrency, and error handling.

## Next Steps

1. **Backend Setup** (Completed)
   - [x] Create project directory structure
   - [x] Initialize FastAPI application
   - [x] Create SQLite database schema
   - [x] Implement `/inbox` endpoint
   - [x] Implement `/classify` endpoint
   - [x] Add error handling for API calls
   - [x] Create HTMX + Alpine.js interface
   - [x] Create Dockerfile for deployment

2. **iOS App** (Completed)
   - [x] Create Xcode project structure
   - [x] Implement recording functionality
   - [x] Add microphone permissions
   - [x] Create transcription service placeholder
   - [x] Create API service placeholder
   - [x] Implement local database with GRDB
   - [x] Implement synchronization service
   - [x] Update UI to show sync status

3. **Testing & Deployment** (Completed)
   - [x] Create backend tests with pytest
   - [x] Create iOS database tests
   - [x] Update database paths for deployment
   - [x] Add Fly.io configuration

4. **Final Steps** (Current Focus)
   - [ ] Deploy to Fly.io
   - [ ] Implement Whisper-tiny Core ML integration
   - [ ] Test full system with real data
   - [ ] Final documentation updates

## Recent Progress

The backend implementation has been completed with the following features:
- FastAPI server with SQLite database
- `/inbox` endpoint for adding new items
- `/classify/{item_id}` endpoint for GPT-4.1 classification
- Basic HTMX + Alpine.js web interface
- Docker configuration for deployment
- Tests with pytest
- Fly.io deployment configuration

iOS app has been fully structured with:
- Basic SwiftUI interface with recording button
- RecorderViewModel to handle audio recording
- TranscriptionService with placeholder implementation
- APIService with placeholder implementation
- DatabaseService using GRDB for local SQLite storage
- SyncService to handle synchronization with the backend
- UI updated to show sync status and controls
- Unit tests for database operations

The next step is to deploy the backend to Fly.io and finalize the iOS app by implementing the Whisper-tiny Core ML integration.

## Deployment Instructions

To deploy the backend to Fly.io:

1. Install the Fly CLI: `brew install flyctl`
2. Login to Fly: `fly auth login`
3. Navigate to the backend directory: `cd voice-inbox/backend`
4. Create a volume for data persistence: `fly volumes create voice_inbox_data --size 1`
5. Deploy the app: `fly deploy`
6. Set the OpenAI API key: `fly secrets set OPENAI_API_KEY=your_key_here`

## Version History
- 2023-07-17  v0.1  Initial task list created
- 2023-07-17  v0.2  Updated with backend implementation progress
- 2023-07-17  v0.3  Updated with iOS app structure progress
- 2023-07-17  v0.4  Updated with GRDB and sync service implementation
- 2023-07-17  v0.5  Updated with testing and deployment progress 