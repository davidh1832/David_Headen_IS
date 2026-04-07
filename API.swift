//
//  API.swift
//  TestMHCB
//
//  Created by David Headen on 12/14/25.
//

import Foundation

// API Integration
class ChatbotAPI {
    
    private let baseURL = "http://127.0.0.1:8000"
    private var chatRequestCount = 0
    private var quoteRequestCount = 0

    func getChatbotResponse(userInput: String, userID: String) async throws -> String {
        
        chatRequestCount += 1
        let currentRequest = chatRequestCount
        
        guard let url = URL(string: "\(baseURL)/chat") else {
            throw NSError(domain: "ChatbotAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let requestBody: [String: Any] = [
            "user_input": userInput,
            "user_id": userID
        ]

        let data = try JSONSerialization.data(withJSONObject: requestBody)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        // Start round trip timer
        let startTime = Date()

        let (responseData, response) = try await URLSession.shared.data(for: request)

        // Stop timer and log
        let fullMs = Date().timeIntervalSince(startTime) * 1000
        print("\n Chat Endpoint Timings")
        print("  full ms: \(String(format: "%.2f", fullMs))ms")

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorString = String(data: responseData, encoding: .utf8) ?? "Unknown server error"
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw NSError(
                domain: "ChatbotAPI",
                code: statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(statusCode): \(errorString.prefix(200)). Check FastAPI console."]
            )
        }

        guard let responseText = String(data: responseData, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) else {
            throw NSError(domain: "ChatbotAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response text."])
        }

        return responseText
    }

    func getReligiousQuote(userInput: String, source: String) async throws -> QuoteResponse {
        
        quoteRequestCount += 1
        let currentRequest = quoteRequestCount
        
        guard let url = URL(string: "\(baseURL)/quote") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "user_input": userInput,
            "source": source
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Start round trip timer
        let startTime = Date()

        let (data, response) = try await URLSession.shared.data(for: request)

        // Stop timer and log
        let fullMs = Date().timeIntervalSince(startTime) * 1000
        print("\n Quote Endpoint Timings")
        print("  full ms: \(String(format: "%.2f", fullMs))ms")

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Server Error", code: (response as? HTTPURLResponse)?.statusCode ?? 500)
        }

        return try JSONDecoder().decode(QuoteResponse.self, from: data)
    }
}
