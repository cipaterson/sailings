import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case message(String)
    case validation([String])
    case transport(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .message(let text):
            return text
        case .validation(let errors):
            return errors.joined(separator: "\n")
        case .transport:
            return "Couldn't reach the server. Check your connection and that the server is running."
        case .decoding:
            return "The server sent something unexpected."
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let session = URLSession(configuration: .default)
    private var token: String?

    func setToken(_ token: String?) {
        self.token = token
    }

    // MARK: - Endpoints

    func login(emailAddress: String, password: String) async throws -> LoginResponse {
        try await send(.post, "/session", body: ["email_address": emailAddress, "password": password])
    }

    func logout() async throws {
        _ = try await raw(.delete, "/session", body: nil)
    }

    func profile() async throws -> Profile {
        try await send(.get, "/profile")
    }

    func voyages() async throws -> [Voyage] {
        try await send(.get, "/sailings")
    }

    func voyage(id: Int) async throws -> Voyage {
        try await send(.get, "/sailings/\(id)")
    }

    func registrations() async throws -> [Registration] {
        try await send(.get, "/registrations")
    }

    /// `climbing` follows the Rails encoding: 1 = Yes, 2 = No.
    func register(voyageID: Int, comment: String?, climbing: Int?) async throws -> Registration {
        var body: [String: Any] = [:]
        if let comment, !comment.isEmpty { body["comment"] = comment }
        if let climbing { body["climbing"] = climbing }
        return try await send(.post, "/sailings/\(voyageID)/registrations", body: body)
    }

    func cancel(registrationID: Int) async throws {
        _ = try await raw(.delete, "/registrations/\(registrationID)", body: nil)
    }

    // MARK: - Plumbing

    private enum Method: String {
        case get = "GET", post = "POST", delete = "DELETE"
    }

    private func send<T: Decodable>(_ method: Method, _ path: String, body: [String: Any]? = nil) async throws -> T {
        let data = try await raw(method, path, body: body)
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func raw(_ method: Method, _ path: String, body: [String: Any]?) async throws -> Data {
        guard let url = URL(string: Config.apiRoot + path) else {
            throw APIError.message("Bad URL: \(path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.message("Unexpected response from the server.")
        }

        switch http.statusCode {
        case 200..<300:
            return data
        case 401:
            throw APIError.unauthorized
        case 422:
            throw APIError.validation(Self.validationErrors(in: data) ?? ["That didn't work."])
        default:
            throw APIError.message(Self.errorMessage(in: data) ?? "Request failed (HTTP \(http.statusCode)).")
        }
    }

    /// Rails sends `{"error": "..."}` for single failures and `{"errors": [...]}` for validation.
    private static func errorMessage(in data: Data) -> String? {
        struct Payload: Decodable { let error: String }
        return try? JSONDecoder().decode(Payload.self, from: data).error
    }

    private static func validationErrors(in data: Data) -> [String]? {
        struct Payload: Decodable { let errors: [String] }
        return try? JSONDecoder().decode(Payload.self, from: data).errors
    }

    /// The API mixes two date shapes: full ISO-8601 timestamps (departs_at) and
    /// bare calendar dates (expires_on, last_sailed). A single built-in strategy
    /// handles only one, so try both.
    ///
    /// These are parse *strategies* (value types) rather than DateFormatter
    /// instances on purpose: JSONDecoder may call this closure concurrently, and
    /// formatters are reference types that are not thread-safe.
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            let dateOnly = Date.ISO8601FormatStyle(timeZone: .gmt).year().month().day()

            if let date = try? Date(text, strategy: .iso8601) { return date }
            if let date = try? Date(text, strategy: dateOnly) { return date }
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unrecognised date: \(text)")
            )
        }
        return decoder
    }()
}
