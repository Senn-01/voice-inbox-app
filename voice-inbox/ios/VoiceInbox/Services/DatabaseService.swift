import Foundation
import SQLite

/// Error type for database operations
enum DatabaseError: Error {
    case setupFailed
    case migrationFailed
    case insertFailed
    case fetchFailed
    case updateFailed
}

/// Service that handles local database operations
final class DatabaseService {
    static let shared = DatabaseService()
    
    private var db: Connection?
    
    // Table and column definitions
    private let recordings = Table("recordings")
    private let id = Expression<String>("id")
    private let text = Expression<String>("text")
    private let audioURL = Expression<String?>("audio_url")
    private let tag = Expression<String?>("tag")
    private let pending = Expression<Bool>("pending")
    private let createdAt = Expression<Date>("created_at")
    private let synced = Expression<Bool>("synced")
    
    private init() {
        setupDatabase()
    }
    
    /// Create a test instance with an in-memory database for unit testing
    static func testInstance() -> DatabaseService {
        let service = DatabaseService()
        service.db = try? Connection(.inMemory)
        try? service.createTable()
        return service
    }
    
    // MARK: - Setup
    
    private func setupDatabase() {
        do {
            // Get the database file path in the Application Support directory
            let fileManager = FileManager.default
            let dbDirectory = try fileManager.url(for: .applicationSupportDirectory, 
                                                 in: .userDomainMask, 
                                                 appropriateFor: nil, 
                                                 create: true)
            let dbPath = dbDirectory.appendingPathComponent("voiceinbox.sqlite").path
            
            // Create connection and table
            db = try Connection(dbPath)
            try createTable()
        } catch {
            print("Database setup failed: \(error.localizedDescription)")
        }
    }
    
    private func createTable() throws {
        guard let db = db else { throw DatabaseError.setupFailed }
        
        try db.run(recordings.create(ifNotExists: true) { table in
            table.column(id, primaryKey: true)
            table.column(text)
            table.column(audioURL)
            table.column(tag)
            table.column(pending, defaultValue: true)
            table.column(createdAt)
            table.column(synced, defaultValue: false)
        })
    }
    
    // MARK: - CRUD Operations
    
    /// Save a recording to the local database
    func saveRecording(_ recording: Recording) async throws {
        guard let db = db else { throw DatabaseError.setupFailed }
        
        let insert = recordings.insert(
            id <- recording.id,
            text <- recording.text,
            audioURL <- recording.audioURL?.absoluteString,
            tag <- recording.tag,
            pending <- recording.pending,
            createdAt <- recording.createdAt,
            synced <- false
        )
        
        try db.run(insert)
    }
    
    /// Get all recordings from the local database
    func getAllRecordings() async throws -> [Recording] {
        guard let db = db else { throw DatabaseError.setupFailed }
        
        var result: [Recording] = []
        
        let query = recordings.order(createdAt.desc)
        for row in try db.prepare(query) {
            let audioURLString = row[audioURL]
            let audioURL = audioURLString.flatMap { URL(string: $0) }
            
            let recording = Recording(
                id: row[id],
                text: row[text],
                audioURL: audioURL,
                tag: row[tag],
                pending: row[pending],
                createdAt: row[createdAt]
            )
            
            result.append(recording)
        }
        
        return result
    }
    
    /// Get recordings that need to be synced with the server
    func getUnsynced() async throws -> [Recording] {
        guard let db = db else { throw DatabaseError.setupFailed }
        
        var result: [Recording] = []
        
        let query = recordings.filter(synced == false)
        for row in try db.prepare(query) {
            let audioURLString = row[audioURL]
            let audioURL = audioURLString.flatMap { URL(string: $0) }
            
            let recording = Recording(
                id: row[id],
                text: row[text],
                audioURL: audioURL,
                tag: row[tag],
                pending: row[pending],
                createdAt: row[createdAt]
            )
            
            result.append(recording)
        }
        
        return result
    }
    
    /// Mark a recording as synced
    func markAsSynced(id idValue: String) async throws {
        guard let db = db else { throw DatabaseError.setupFailed }
        
        let recordToUpdate = recordings.filter(id == idValue)
        try db.run(recordToUpdate.update(synced <- true))
    }
    
    /// Update a recording's tag and pending status
    func updateRecording(id idValue: String, tag tagValue: String?, pending pendingValue: Bool?) async throws {
        guard let db = db else { throw DatabaseError.setupFailed }
        
        let recordToUpdate = recordings.filter(id == idValue)
        var updates = [Setter]()
        
        if let tagValue = tagValue {
            updates.append(tag <- tagValue)
        }
        
        if let pendingValue = pendingValue {
            updates.append(pending <- pendingValue)
        }
        
        if !updates.isEmpty {
            updates.append(synced <- false)
            try db.run(recordToUpdate.update(updates))
        }
    }
} 