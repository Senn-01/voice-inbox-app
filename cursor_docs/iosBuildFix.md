# iOS Build Issues: Fixing GRDB Problems

[Roadmap](projectRoadmap.md) | [Task](currentTask.md) | [Stack](techStack.md) | [Summary](codebaseSummary.md)

This guide provides solutions for the GRDB build issues in the Voice Inbox iOS app.

## Option 1: Use a Specific GRDB Version

This approach maintains the existing codebase with minimal changes.

### Step 1: Remove Current GRDB Package

1. Open the project in Xcode
2. Click on the project file in the navigator
3. Go to the "Package Dependencies" tab
4. Select GRDB.swift and click the "-" button to remove it
5. Click "Remove Package" when prompted

### Step 2: Clean the Build Folder

1. Hold Option key (⌥) and click Product → Clean Build Folder... (⌥⇧⌘K)
2. Close Xcode completely

### Step 3: Clear Derived Data (Terminal)

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm/
```

### Step 4: Re-add GRDB with Specific Version

1. Reopen Xcode
2. Click File → Add Packages...
3. Enter URL: `https://github.com/groue/GRDB.swift.git`
4. Choose "Exact Version" (not "Up to Next Major")
5. Type `6.15.0` in the version field
6. Ensure your app target is selected in "Add to Target"
7. Click "Add Package"

### Step 5: Update Package.swift (if needed)

If you're using a Package.swift file, update the dependency:

```swift
dependencies: [
    .package(url: "https://github.com/groue/GRDB.swift.git", exact: "6.15.0"),
    // other dependencies...
],
```

## Option 2: Switch to SQLite.swift

This is a more radical change but uses a simpler library that may have fewer build issues.

### Step 1: Remove GRDB

Follow steps 1-3 from Option 1 above.

### Step 2: Add SQLite.swift

1. Open Xcode
2. Click File → Add Packages...
3. Enter URL: `https://github.com/stephencelis/SQLite.swift.git`
4. Choose "Up to Next Major Version" starting with "0.14.1"
5. Ensure your app target is selected in "Add to Target"
6. Click "Add Package"

### Step 3: Replace DatabaseService Implementation

Replace the existing `DatabaseService.swift` with this simplified version:

```swift
import Foundation
import SQLite

class DatabaseService {
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
    
    // For testing
    static func testInstance() -> DatabaseService {
        let service = DatabaseService()
        service.db = try? Connection(.inMemory)
        try? service.createTable()
        return service
    }
    
    private func setupDatabase() {
        do {
            // Get database file path
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
    
    // MARK: - Public Methods
    
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
    
    func getAllRecordings() async throws -> [Recording] {
        guard let db = db else { throw DatabaseError.setupFailed }
        
        var result: [Recording] = []
        
        let query = recordings.order(createdAt.desc)
        for row in try db.prepare(query) {
            let audioURL = row[audioURL].flatMap { URL(string: $0) }
            
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
    
    func getUnsynced() async throws -> [Recording] {
        guard let db = db else { throw DatabaseError.setupFailed }
        
        var result: [Recording] = []
        
        let query = recordings.filter(synced == false)
        for row in try db.prepare(query) {
            let audioURL = row[audioURL].flatMap { URL(string: $0) }
            
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
    
    func markAsSynced(id idValue: String) async throws {
        guard let db = db else { throw DatabaseError.setupFailed }
        
        let recordToUpdate = recordings.filter(id == idValue)
        try db.run(recordToUpdate.update(synced <- true))
    }
    
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

enum DatabaseError: Error {
    case setupFailed
    case migrationFailed
    case insertFailed
    case fetchFailed
    case updateFailed
}
```

### Step 4: Update Package.swift (if needed)

If you're using a Package.swift file, update it:

```swift
dependencies: [
    .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1"),
    // other dependencies...
],
targets: [
    .target(
        name: "VoiceInbox",
        dependencies: [
            .product(name: "SQLite", package: "SQLite.swift"),
            // other dependencies...
        ],
    ),
]
```

## Troubleshooting

### If Both Options Fail

1. **Create New Project**: Create a new empty SwiftUI project and migrate your code gradually
2. **SPM vs CocoaPods**: Try using CocoaPods instead of Swift Package Manager:
   ```ruby
   # Podfile
   pod 'GRDB.swift', '~> 6.15.0'
   ```
3. **Minimal Approach**: Start with just the core functionality without database libraries

### Common Issues

- **Linker Errors**: Ensure target membership is correct for all files
- **Architecture Issues**: Check deployment target and supported architectures
- **Missing Symbols**: Make sure you're using public APIs from the library

## Version History
- 2023-04-23 v1.0 Initial guide for fixing GRDB build issues 