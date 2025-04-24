import Foundation

actor TranscriptionService {
    static let shared = TranscriptionService()
    
    private let apiService = APIService.shared
    
    private init() {}
    
    func transcribe(audioURL: URL) async throws -> String {
        do {
            // Use backend transcription service
            return try await transcribeWithBackend(audioURL: audioURL)
        } catch {
            // Fall back to OpenAI API directly as a backup option
            print("Backend transcription failed: \(error.localizedDescription)")
            print("Falling back to OpenAI API...")
            return try await transcribeWithOpenAI(audioURL: audioURL)
        }
    }
    
    private func transcribeWithBackend(audioURL: URL) async throws -> String {
        // Create URL request to our backend /transcribe endpoint
        let url = URL(string: "\(apiService.baseURL)/transcribe")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Prepare multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Add audio file
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        
        // Read the audio file
        let audioData = try Data(contentsOf: audioURL)
        data.append(audioData)
        data.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Set the data
        request.httpBody = data
        
        // Make the request
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw TranscriptionError.serverError(errorMessage)
        }
        
        // Parse JSON response
        do {
            let result = try JSONDecoder().decode(TranscriptionResponse.self, from: responseData)
            return result.text
        } catch {
            throw TranscriptionError.decodingError
        }
    }
    
    private func transcribeWithOpenAI(audioURL: URL) async throws -> String {
        // In a real implementation, this would use the OpenAI API directly
        // as a fallback when backend is unavailable
        
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        guard !apiKey.isEmpty else {
            throw TranscriptionError.missingAPIKey
        }
        
        // OpenAI API implementation would go here
        // Currently a placeholder
        return "Placeholder OpenAI transcription"
    }
}

// Helper structures for transcription
enum TranscriptionError: Error {
    case networkError
    case serverError(String)
    case decodingError
    case missingAPIKey
}

struct TranscriptionResponse: Decodable {
    let text: String
} 