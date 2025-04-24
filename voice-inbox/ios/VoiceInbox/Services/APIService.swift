import Foundation

enum APIError: Error {
    case networkError
    case decodingError
    case serverError(String)
    case unexpectedResponse
}

class APIService {
    static let shared = APIService()
    
    let baseURL = "https://voice-inbox-api.fly.dev"
    
    private init() {}
    
    func uploadRecording(_ recording: Recording, audioURL: URL) async throws {
        let url = URL(string: "\(baseURL)/inbox")!
        
        // Create multipart form data
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Add text field
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"text\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(recording.text)\r\n".data(using: .utf8)!)
        
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
            throw APIError.networkError
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    func fetchRecentRecordings() async throws -> [Recording] {
        let url = URL(string: "\(baseURL)/items")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
        
        do {
            let recordings = try JSONDecoder().decode([Recording].self, from: data)
            return recordings
        } catch {
            throw APIError.decodingError
        }
    }
} 