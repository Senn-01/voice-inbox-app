import SwiftUI

struct ContentView: View {
    @StateObject private var recorderVM = RecorderViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status bar
                HStack {
                    Text("Status: \(recorderVM.syncStatus)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: recorderVM.manualSync) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Status text
                Text(recorderVM.statusMessage)
                    .font(.headline)
                    .foregroundColor(recorderVM.isRecording ? .red : .primary)
                    .animation(.default, value: recorderVM.isRecording)
                
                // Record button
                Button(action: recorderVM.toggleRecording) {
                    Image(systemName: recorderVM.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(recorderVM.isRecording ? .red : .blue)
                        .padding()
                        .animation(.default, value: recorderVM.isRecording)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Recent recordings list
                VStack(alignment: .leading) {
                    HStack {
                        Text("Recent Recordings")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: recorderVM.refreshRecordings) {
                            Image(systemName: "arrow.clockwise.circle")
                                .font(.headline)
                        }
                    }
                    .padding(.horizontal)
                    
                    if recorderVM.recentRecordings.isEmpty {
                        VStack(spacing: 10) {
                            Spacer()
                            Image(systemName: "mic.slash")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No recordings yet")
                                .foregroundColor(.secondary)
                            Text("Tap the microphone to start recording")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        List {
                            ForEach(recorderVM.recentRecordings) { recording in
                                RecordingRow(recording: recording)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .frame(maxHeight: 300)
            }
            .padding()
            .navigationTitle("Voice Inbox")
            .alert(isPresented: $recorderVM.showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(recorderVM.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct RecordingRow: View {
    let recording: Recording
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recording.text)
                .font(.body)
                .lineLimit(2)
            
            HStack {
                Text(recording.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(recording.createdAt, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let tag = recording.tag {
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                SyncStatusView(isPending: recording.pending)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SyncStatusView: View {
    let isPending: Bool
    
    var body: some View {
        Image(systemName: isPending ? "clock" : "checkmark.circle")
            .foregroundColor(isPending ? .orange : .green)
            .font(.caption)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 