import Foundation
import AVFoundation
import Combine

@MainActor
final class RecorderViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    // Published properties
    @Published var isRecording = false
    @Published var statusMessage = "Tap to record"
    @Published var recentRecordings: [Recording] = []
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published var syncStatus: String = "Ready"
    
    // Private properties
    private var recorder: AVAudioRecorder?
    private var currentRecordingURL: URL?
    private var cancellables = Set<AnyCancellable>()
    
    // Services
    private let databaseService = DatabaseService.shared
    private let syncService = SyncService.shared
    
    override init() {
        super.init()
        setupAudioSession()
        subscribeToSyncStatus()
        loadRecentRecordings()
    }
    
    // MARK: - Public Methods
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func manualSync() {
        Task {
            await syncService.synchronize()
        }
    }
    
    func refreshRecordings() {
        loadRecentRecordings()
    }
    
    // MARK: - Private Methods
    
    private func subscribeToSyncStatus() {
        syncService.syncStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                switch status {
                case .idle:
                    self?.syncStatus = "Ready"
                case .syncing:
                    self?.syncStatus = "Syncing..."
                case .success(let message):
                    self?.syncStatus = "Synced: \(message)"
                    self?.loadRecentRecordings()
                case .failure(let message):
                    self?.syncStatus = "Error: \(message)"
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            showError("Could not set up audio session: \(error.localizedDescription)")
        }
    }
    
    private func startRecording() {
        // Check permissions first
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            guard let self = self else { return }
            
            guard allowed else {
                self.showError("Microphone access denied. Please enable in Settings.")
                return
            }
            
            Task { @MainActor in
                do {
                    // Create a unique file URL in the temp directory
                    let fileName = "\(UUID().uuidString).m4a"
                    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                    self.currentRecordingURL = fileURL
                    
                    // Recording settings (8kHz mono AAC)
                    let settings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatMPEG4AAC,
                        AVSampleRateKey: 8000.0,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
                    ]
                    
                    // Create and configure the recorder
                    self.recorder = try AVAudioRecorder(url: fileURL, settings: settings)
                    self.recorder?.delegate = self
                    
                    // Start recording
                    self.recorder?.record()
                    self.isRecording = true
                    self.statusMessage = "Recording..."
                } catch {
                    self.showError("Could not start recording: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func stopRecording() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        statusMessage = "Processing..."
    }
    
    private func loadRecentRecordings() {
        Task {
            do {
                // Load recordings from local database
                let recordings = try await databaseService.getAllRecordings()
                await MainActor.run {
                    self.recentRecordings = recordings
                }
            } catch {
                await MainActor.run {
                    self.showError("Failed to load recordings: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            statusMessage = "Tap to record"
            
            guard flag, let url = currentRecordingURL else {
                showError("Recording failed")
                return
            }
            
            // Process the recording (transcribe and save)
            processRecording(url: url)
        }
    }
    
    private func processRecording(url: URL) {
        Task {
            do {
                // 1. Transcribe the audio
                let text = try await TranscriptionService.shared.transcribe(audioURL: url)
                
                // 2. Create a Recording object
                let recording = Recording(
                    id: UUID().uuidString,
                    text: text,
                    audioURL: url,
                    tag: nil,
                    pending: true,
                    createdAt: Date()
                )
                
                // 3. Save to local database
                try await databaseService.saveRecording(recording)
                
                // 4. Add to recent recordings (re-fetch from database)
                await loadRecentRecordings()
                
                // 5. Update UI
                await MainActor.run {
                    self.statusMessage = "Transcription complete"
                }
                
                // 6. Trigger a sync
                await syncService.synchronize()
            } catch {
                await MainActor.run {
                    self.showError("Processing failed: \(error.localizedDescription)")
                }
            }
        }
    }
} 