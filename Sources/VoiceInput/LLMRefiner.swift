import Foundation

// MARK: - LLMRefiner

/// OpenAI-compatible API client for speech text refinement.
///
/// Sends transcribed text to an LLM for conservative correction and returns the refined text.
/// Called after speech recognition stops, before text injection.
final class LLMRefiner {

    // MARK: - UserDefaults Keys

    private static let keyApiBaseUrl = "llmApiBaseUrl"
    private static let keyApiKey = "llmApiKey"
    private static let keyModel = "llmModel"
    private static let keyEnabled = "llmEnabled"

    // MARK: - Static Configuration

    /// Base URL for the LLM API. Defaults to `"https://api.openai.com"`.
    static var apiBaseUrl: String {
        get {
            UserDefaults.standard.string(forKey: keyApiBaseUrl)
                ?? "https://api.openai.com"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyApiBaseUrl)
        }
    }

    /// API key for authentication. Defaults to `""`.
    static var apiKey: String {
        get {
            UserDefaults.standard.string(forKey: keyApiKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyApiKey)
        }
    }

    /// Model identifier. Defaults to `"gpt-4o-mini"`.
    static var model: String {
        get {
            UserDefaults.standard.string(forKey: keyModel) ?? "gpt-4o-mini"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyModel)
        }
    }

    /// Whether LLM refinement is enabled. Defaults to `false`.
    static var isEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: keyEnabled) as? Bool ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyEnabled)
        }
    }

    /// Returns `true` if both `apiKey` and `apiBaseUrl` are non-empty.
    static var isConfigured: Bool {
        !apiKey.isEmpty && !apiBaseUrl.isEmpty
    }

    // MARK: - System Prompt

    private static let systemPrompt = """
        You are a speech recognition text correction assistant. Your task is to conservatively fix obvious speech recognition errors in both Chinese and English text:
        1. Chinese homophone errors (e.g., '配森'→'Python', '杰森'→'JSON')
        2. English technical terms mistakenly converted to Chinese (e.g., '阿尔法狗'→'AlphaGo')
        3. Obvious context mismatches

        ⚠️ Critical rules:
        - ONLY fix obvious recognition errors
        - NEVER rewrite, polish, remove, or restructure any content that looks correct
        - If the input looks correct, return it unchanged
        - Do not add any explanations or extra text
        - Return ONLY the corrected text itself

        ⚠️ 重要规则：
        - 只修正明显的识别错误
        - 绝对不要重写、润色、删减或重组任何看起来正确的内容
        - 如果输入看起来正确，原样返回
        - 不要添加任何解释或额外文字
        - 只返回校正后的文本本身
        """

    // MARK: - Refine

    /// Sends text to the LLM for conservative correction.
    ///
    /// - Parameter text: The transcribed speech text to refine.
    /// - Returns: The refined text. If the LLM is not configured or not enabled, returns the original text unchanged.
    /// - Throws: `RefineError` if the request fails or the response is malformed.
    static func refine(text: String) async throws -> String {
        guard isConfigured, isEnabled else {
            Logger.llm.debug("LLM refinement skipped (not configured or disabled)")
            return text
        }
        
        Logger.llm.info("Sending text to LLM for refinement (\(text.count) chars)")

        let requestBody = ChatCompletionRequest(
            model: model,
            messages: [
                Message(role: "system", content: systemPrompt),
                Message(role: "user", content: text)
            ],
            temperature: 0.1,
            maxTokens: 500
        )

        let url = URL(string: "\(apiBaseUrl)/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        Logger.llm.debug("Sending request to \(apiBaseUrl)/v1/chat/completions")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.llm.error("Invalid response type from LLM server")
            throw RefineError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            Logger.llm.error("HTTP error \(httpResponse.statusCode): \(body.prefix(200))")
            throw RefineError.httpError(
                statusCode: httpResponse.statusCode,
                body: body
            )
        }

        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        guard let content = chatResponse.choices.first?.message.content else {
            Logger.llm.error("No content in LLM response")
            throw RefineError.malformedResponse
        }

        Logger.llm.info("LLM refinement completed successfully")

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Test Connection

    /// Sends a minimal test request to verify the API connection.
    ///
    /// - Returns: The LLM's response to "Hello".
    /// - Throws: `RefineError` if the request fails or the response is malformed.
    static func testConnection() async throws -> String {
        Logger.llm.info("Testing LLM connection to \(apiBaseUrl)")
        
        let requestBody = ChatCompletionRequest(
            model: model,
            messages: [
                Message(role: "user", content: "Hello")
            ],
            temperature: 0.1,
            maxTokens: 50
        )

        let url = URL(string: "\(apiBaseUrl)/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        Logger.llm.debug("Sending test request...")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.llm.error("Test connection: Invalid response type")
            throw RefineError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            Logger.llm.error("Test connection: HTTP error \(httpResponse.statusCode)")
            throw RefineError.httpError(
                statusCode: httpResponse.statusCode,
                body: body
            )
        }

        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        guard let content = chatResponse.choices.first?.message.content else {
            Logger.llm.error("Test connection: No content in response")
            throw RefineError.malformedResponse
        }
        
        Logger.llm.info("Test connection successful")

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Errors

    enum RefineError: LocalizedError {
        case invalidResponse
        case httpError(statusCode: Int, body: String)
        case malformedResponse

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from LLM server."
            case .httpError(let statusCode, let body):
                return "LLM request failed with HTTP \(statusCode): \(body)"
            case .malformedResponse:
                return "LLM returned a malformed response — could not extract refined text."
            }
        }
    }
}

// MARK: - Codable Models

/// A single message in a chat completion request.
private struct Message: Codable {
    let role: String
    let content: String
}

/// Request body for the OpenAI-compatible chat completions endpoint.
private struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}

/// Response body from the OpenAI-compatible chat completions endpoint.
private struct ChatCompletionResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: MessageContent
    }

    struct MessageContent: Codable {
        let content: String?
    }
}
