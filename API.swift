//
//  API.swift
//  TestMHCB
//
//  Created by David Headen on 12/14/25.
//

import Foundation

// This code is the front-end API Integration, which enables asynchronous requests between front-end UI and the backend logic
class ChatbotAPI {
    
    private let baseURL = "http://127.0.0.1:8000" 
   
    
    // Mental Health message request
    func getChatbotResponse(userInput: String, userID: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat") else { //chat endpoint
            throw NSError(domain: "ChatbotAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        // send user input and user id to backend as json body
        let body: [String: Any] = [
            "user_input": userInput,
            "user_id": userID
        ]

        let data = try JSONSerialization.data(withJSONObject: body)
        
        //http post request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        
        
        let (responseData, response) = try await URLSession.shared.data(for: request)// sending

        // verify response is valid http and return 200
        // If not, status code and server error message are extracted and throw an error
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorString = String(data: responseData, encoding: .utf8) ?? "Unknown server error"
            throw NSError(
                domain: "ChatbotAPI",
                code: statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(statusCode): \(errorString.prefix(200)). Check FastAPI console."]
            )
        }
        
        // Decode mental health response from  /chat pipeline as a string
        guard let responseText = String(data: responseData, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) else {
            throw NSError(domain: "ChatbotAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not decode response text."])
        }

        return responseText
    }
    // Religious quote message request
    func ReligiousQuote(userInput: String, source: String) async throws -> quote_response {
        guard let url = URL(string: "\(baseURL)/quote") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Pass in user input and the source chosen by the user as json body
        let body: [String: Any] = [
            "user_input": userInput,
            "source": source
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        

        let (data, response) = try await URLSession.shared.data(for: request)// sending

        
        //http
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Server Error", code: (response as? HTTPURLResponse)?.statusCode ?? 500)
        }

        return try JSONDecoder().decode(quote_response.self, from: data) // Json data -> struct (Quote, chapter, source)
    }
}
