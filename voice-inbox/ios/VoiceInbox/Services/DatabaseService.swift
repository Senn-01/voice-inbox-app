import Foundation
import GRDB

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
    
    private var dbQueue: DatabaseQueue?
    
    private init() {
        setupDatabase()
    }
    
    /// Create a test instance with an in-memory database for unit testing
    static func testInstance() -> DatabaseService {
        let service = DatabaseService()
        
        do {
            // Use an in-memory database for testing
            service.dbQueue = try DatabaseQueue(configuration: Configuration())
            try service.performMigrations()
        } catch {
            print("Failed to create test database: \(error.localizedDescription)")
        }
        
        return service
    }
    
    // MARK: - Setup
    
    private func setupDatabase() {
        do {
            // Get the database file path in the Application Support directory
            let fileManager = FileManager.default
            let dbDirectory = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dbPath = dbDirectory.appendingPathComponent("voiceinbox.sqlite")
            
            // Create a database connection
            dbQueue = try DatabaseQueue(path: dbPath.path)
            
            // Perform initial migrations
            try performMigrations()
        } catch {
            print("Database setup failed: \(error.localizedDescription)")
        }
    }
    
    private func performMigrations() throws {
        guard let dbQueue = dbQueue else { throw DatabaseError.setupFailed }
        
        try dbQueue.write { db in
            // Create the recordings table if it doesn't exist
            try db.create(table: "recordings", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("text", .text).notNull()
                t.column("audio_url", .text)
                t.column("tag", .text)
                t.column("pending", .boolean).notNull().defaults(to: true)
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("synced", .boolean).notNull().defaults(to: false)
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Save a recording to the local database
    func saveRecording(_ recording: Recording) async throws {
        guard let dbQueue = dbQueue else { throw DatabaseError.setupFailed }
        
        // Convert the Recording model to a record dictionary
        var record: [String: Any] = [
            "id": recording.id,
            "text": recording.text,
            "pending": recording.pending,
            "created_at": recording.createdAt
        ]
        
        if let audioURL = recording.audioURL?.absoluteString {
            record["audio_url"] = audioURL
        }
        
        if let tag = recording.tag {
            record["tag"] = tag
        }
        
        // Insert into database
        try dbQueue.write { db in
            try db.execute(sql: """
                INSERT INTO recordings (id, text, audio_url, tag, pending, created_at, synced)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    recording.id,
                    recording.text,
                    recording.audioURL?.absoluteString,
                    recording.tag,
                    recording.pending,
                    recording.createdAt,
                    false
                ]
            )
        }
    }
    
    /// Get all recordings from the local database
    func getAllRecordings() async throws -> [Recording] {
        guard let dbQueue = dbQueue else { throw DatabaseError.setupFailed }
        
        return try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM recordings ORDER BY created_at DESC")
            
            return rows.compactMap { row in
                guard let id = row["id"] as? String,
                      let text = row["text"] as? String,
                      let createdAt = row["created_at"] as? Date else {
                    return nil
                }
                
                let audioURLString = row["audio_url"] as? String
                let audioURL = audioURLString != nil ? URL(string: audioURLString!) : nil
                let tag = row["tag"] as? String
                let pending = (row["pending"] as? Bool) ?? true
                
                return Recording(
                    id: id,
                    text: text,
                    audioURL: audioURL,
                    tag: tag,
                    pending: pending,
                    createdAt: createdAt
                )
            }
        }
    }
    
    /// Get recordings that need to be synced with the server
    func getUnsynced() async throws -> [Recording] {
        guard let dbQueue = dbQueue else { throw DatabaseError.setupFailed }
        
        return try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM recordings WHERE synced = 0")
            
            return rows.compactMap { row in
                guard let id = row["id"] as? String,
                      let text = row["text"] as? String,
                      let createdAt = row["created_at"] as? Date else {
                    return nil
                }
                
                let audioURLString = row["audio_url"] as? String
                let audioURL = audioURLString != nil ? URL(string: audioURLString!) : nil
                let tag = row["tag"] as? String
                let pending = (row["pending"] as? Bool) ?? true
                
                return Recording(
                    id: id,
                    text: text,
                    audioURL: audioURL,
                    tag: tag,
                    pending: pending,
                    createdAt: createdAt
                )
            }
        }
    }
    
    /// Mark a recording as synced
    func markAsSynced(id: String) async throws {
        guard let dbQueue = dbQueue else { throw DatabaseError.setupFailed }
        
        try dbQueue.write { db in
            try db.execute(sql: "UPDATE recordings SET synced = 1 WHERE id = ?", arguments: [id])
        }
    }
    
    /// Update a recording's tag and pending status
    func updateRecording(id: String, tag: String?, pending: Bool?) async throws {
        guard let dbQueue = dbQueue else { throw DatabaseError.setupFailed }
        
        try dbQueue.write { db in
            var updates: [String] = []
            var arguments: [Any] = []
            
            if let tag = tag {
                updates.append("tag = ?")
                arguments.append(tag)
            }
            
            if let pending = pending {
                updates.append("pending = ?")
                arguments.append(pending)
            }
            
            // Only update if there are fields to update
            if !updates.isEmpty {
                updates.append("synced = 0") // Need to sync again after update
                let query = "UPDATE recordings SET \(updates.joined(separator: ", ")) WHERE id = ?"
                arguments.append(id)
                
                try db.execute(sql: query, arguments: arguments)
            }
        }
    }
} 