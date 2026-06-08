//
//  GeminiService.swift
//  isola_test
//

import Foundation

struct GeminiAPIMessage {
    let role: String  // "user" or "model"
    let text: String
}

enum GeminiError: LocalizedError {
    case networkError(Int)
    case parseError
    case apiKeyNotConfigured

    var errorDescription: String? {
        switch self {
        case .networkError(let code): return "網路錯誤 (\(code))"
        case .parseError: return "無法解析回應"
        case .apiKeyNotConfigured: return "Gemini API 金鑰尚未設定"
        }
    }
}

actor GeminiService {
    static let apiKey = "AIzaSyB3mfX7cqA-iAZ8rue34pCxVD5thbq9d10"

    private let model = "gemini-3.1-flash-lite"

    func generateContent(
        messages: [GeminiAPIMessage],
        systemPrompt: String,
        maxTokens: Int = 500
    ) async throws -> String {
        guard GeminiService.apiKey != "YOUR_GEMINI_API_KEY" else {
            throw GeminiError.apiKeyNotConfigured
        }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(GeminiService.apiKey)"
        guard let url = URL(string: urlString) else { throw GeminiError.parseError }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let contents: [[String: Any]] = messages.map { msg in
            ["role": msg.role, "parts": [["text": msg.text]]]
        }

        let body: [String: Any] = [
            "systemInstruction": ["parts": [["text": systemPrompt]]],
            "contents": contents,
            "generationConfig": [
                "temperature": 0.85,
                "maxOutputTokens": maxTokens,
                "topP": 0.95
            ],
            "safetySettings": [
                ["category": "HARM_CATEGORY_HARASSMENT",        "threshold": "BLOCK_MEDIUM_AND_ABOVE"],
                ["category": "HARM_CATEGORY_HATE_SPEECH",       "threshold": "BLOCK_MEDIUM_AND_ABOVE"],
                ["category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"],
                ["category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw GeminiError.networkError(0)
        }
        guard http.statusCode == 200 else {
            throw GeminiError.networkError(http.statusCode)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let first = candidates.first,
            let content = first["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let text = parts.first?["text"] as? String
        else {
            throw GeminiError.parseError
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
