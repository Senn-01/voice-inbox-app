# Voice Inbox App — Test Plan

[Roadmap](projectRoadmap.md) | [Task](currentTask.md) | [Stack](techStack.md) | [Summary](codebaseSummary.md)

## Testing Strategy

The Voice Inbox App will be tested across multiple layers to ensure reliability:

1. **Unit Testing**
   - iOS components with XCTest
   - Backend endpoints with pytest

2. **Integration Testing**
   - API endpoint functionality
   - Database operations
   - Transcription service

3. **Manual Testing**
   - User flows
   - Edge cases
   - Performance and resource usage

## Test Matrix

### Backend Tests

| Test Category | Test Case | Priority | Status |
|---------------|-----------|----------|--------|
| **API** | POST to `/inbox` | High | 📅 Planned |
| **API** | POST to `/classify/{item_id}` | High | 📅 Planned |
| **API** | GET `/items` | High | 📅 Planned |
| **Database** | SQLite connections | High | 📅 Planned |
| **Database** | Concurrent operations | Medium | 📅 Planned |
| **OpenAI** | Classification API | High | 📅 Planned |
| **Error Handling** | Invalid requests | Medium | 📅 Planned |
| **Security** | API key protection | High | 📅 Planned |

### iOS Tests

| Test Category | Test Case | Priority | Status |
|---------------|-----------|----------|--------|
| **Recording** | Audio capture | High | 📅 Planned |
| **Recording** | Permissions handling | High | 📅 Planned |
| **Transcription** | Whisper Core ML | High | 📅 Planned |
| **Transcription** | OpenAI fallback | Medium | 📅 Planned |
| **Database** | Local SQLite operations | Medium | 📅 Planned |
| **Network** | API communication | High | 📅 Planned |
| **UI** | SwiftUI components | Medium | 📅 Planned |

### Manual Test Checklist

- [ ] App permissions request properly on first launch
- [ ] Audio recording works with acceptable quality
- [ ] Transcription is accurate for typical voice input
- [ ] Recordings save correctly to local DB
- [ ] Data successfully syncs to backend
- [ ] Web UI displays all inbox items correctly
- [ ] Classification works with expected tags
- [ ] App works in offline mode (except for sync)
- [ ] Cold start performance is acceptable

## Performance Testing

- Recording memory usage
- Transcription time (Core ML vs API)
- API response times
- Web UI rendering performance

## Security Testing

- OpenAI API key storage
- Backend authentication
- Data transmission security
- SQLite file permissions

## Version History
- 2023-07-17  v0.1  Initial test plan documentation 