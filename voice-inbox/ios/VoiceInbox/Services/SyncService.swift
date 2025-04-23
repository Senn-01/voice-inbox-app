import Foundation
import Combine

class SyncService {
    static let shared = SyncService()
    
    private let apiService = APIService.shared
    private let databaseService = DatabaseService.shared
    
    private var syncTimer: Timer?
    private var isCurrentlySyncing = false
    
    // Sync status publisher that views can subscribe to
    private let syncStatusSubject = CurrentValueSubject<SyncStatus, Never>(.idle)
    var syncStatus: AnyPublisher<SyncStatus, Never> {
        syncStatusSubject.eraseToAnyPublisher()
    }
    
    private init() {
        startPeriodicSync()
    }
    
    // MARK: - Public Methods
    
    /// Start the sync service with periodic syncing
    func startPeriodicSync() {
        // Cancel any existing timer
        syncTimer?.invalidate()
        
        // Create a new timer that fires every 5 minutes
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.synchronize()
            }
        }
        
        // Perform an initial sync
        Task {
            await synchronize()
        }
    }
    
    /// Stop periodic syncing
    func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    /// Manually trigger a sync operation
    func synchronize() async {
        // Avoid concurrent sync operations
        guard !isCurrentlySyncing else { return }
        
        isCurrentlySyncing = true
        syncStatusSubject.send(.syncing)
        
        do {
            // Get recordings that need to be synced
            let unsynced = try await databaseService.getUnsynced()
            
            if unsynced.isEmpty {
                syncStatusSubject.send(.success("No items to sync"))
                isCurrentlySyncing = false
                return
            }
            
            // Sync each recording with the server
            for recording in unsynced {
                do {
                    // Get the audio URL from the recording if it exists
                    let audioURL = recording.audioURL
                    
                    // Upload to server
                    try await apiService.uploadRecording(recording, audioURL: audioURL)
                    
                    // Mark as synced in local database
                    try await databaseService.markAsSynced(id: recording.id)
                } catch {
                    // Continue with other recordings even if one fails
                    print("Failed to sync recording \(recording.id): \(error.localizedDescription)")
                }
            }
            
            // Update the sync status
            syncStatusSubject.send(.success("Synced \(unsynced.count) items"))
        } catch {
            syncStatusSubject.send(.failure(error.localizedDescription))
        }
        
        isCurrentlySyncing = false
    }
    
    /// Fetch all recordings from the backend and update local database
    func fetchFromServer() async {
        guard !isCurrentlySyncing else { return }
        
        isCurrentlySyncing = true
        syncStatusSubject.send(.syncing)
        
        do {
            // Fetch recordings from server
            let serverRecordings = try await apiService.fetchRecentRecordings()
            
            // For a full implementation, we would merge these with local recordings
            // For simplicity in this MVP, we just log them
            print("Fetched \(serverRecordings.count) recordings from server")
            
            syncStatusSubject.send(.success("Fetched \(serverRecordings.count) items"))
        } catch {
            syncStatusSubject.send(.failure(error.localizedDescription))
        }
        
        isCurrentlySyncing = false
    }
}

/// Status of the synchronization process
enum SyncStatus {
    case idle
    case syncing
    case success(String)
    case failure(String)
} 