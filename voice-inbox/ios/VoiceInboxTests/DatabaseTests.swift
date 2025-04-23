import XCTest
@testable import VoiceInbox
import GRDB

class DatabaseTests: XCTestCase {
    var databaseService: DatabaseService!
    
    override func setUp() {
        super.setUp()
        // Create a test database service that uses an in-memory database
        databaseService = DatabaseService.testInstance()
    }
    
    override func tearDown() {
        databaseService = nil
        super.tearDown()
    }
    
    func testSaveAndRetrieveRecording() async throws {
        // Create a test recording
        let recording = Recording(
            id: UUID().uuidString,
            text: "Test recording",
            audioURL: URL(string: "file:///test.m4a"),
            tag: nil,
            pending: true,
            createdAt: Date()
        )
        
        // Save to database
        try await databaseService.saveRecording(recording)
        
        // Retrieve all recordings
        let recordings = try await databaseService.getAllRecordings()
        
        // Verify
        XCTAssertEqual(recordings.count, 1)
        XCTAssertEqual(recordings[0].id, recording.id)
        XCTAssertEqual(recordings[0].text, recording.text)
    }
    
    func testMarkAsSynced() async throws {
        // Create and save a test recording
        let recording = Recording(
            id: UUID().uuidString,
            text: "Test recording",
            audioURL: nil,
            tag: nil,
            pending: true,
            createdAt: Date()
        )
        
        try await databaseService.saveRecording(recording)
        
        // Get unsynced recordings
        var unsynced = try await databaseService.getUnsynced()
        XCTAssertEqual(unsynced.count, 1)
        
        // Mark as synced
        try await databaseService.markAsSynced(id: recording.id)
        
        // Verify no unsynced recordings remain
        unsynced = try await databaseService.getUnsynced()
        XCTAssertEqual(unsynced.count, 0)
    }
    
    func testUpdateRecording() async throws {
        // Create and save a test recording
        let recording = Recording(
            id: UUID().uuidString,
            text: "Test recording",
            audioURL: nil,
            tag: nil,
            pending: true,
            createdAt: Date()
        )
        
        try await databaseService.saveRecording(recording)
        
        // Update with a tag
        try await databaseService.updateRecording(id: recording.id, tag: "Test Tag", pending: false)
        
        // Retrieve and verify
        let recordings = try await databaseService.getAllRecordings()
        XCTAssertEqual(recordings.count, 1)
        XCTAssertEqual(recordings[0].tag, "Test Tag")
        XCTAssertEqual(recordings[0].pending, false)
    }
} 