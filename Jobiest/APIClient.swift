import Foundation

/// Jobiest REST client (https://jobiest.com/api). All business calls carry the
/// Supabase access token as a Bearer token, exactly like the Android app.
/// Contract: API_INTEGRATION_GUIDE.md. NOTE: verify field names against live
/// responses with a dedicated TEST ACCOUNT as screens get wired up.
final class APIClient {
    static let shared = APIClient()
    private let session = URLSession.shared

    private func request<T: Decodable>(_ path: String, method: String = "GET", body: [String: Any]? = nil, query: [URLQueryItem]? = nil) async throws -> T {
        guard let token = AuthService.shared.accessToken else { throw AuthError.notSignedIn }
        var components = URLComponents(url: Config.apiURL(path), resolvingAgainstBaseURL: false)!
        if let query { components.queryItems = query }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.transport }
        if http.statusCode == 401 {
            // Access token expired: refresh once and retry.
            try await AuthService.shared.refresh()
            return try await request(path, method: method, body: body, query: query)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.server(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    // MARK: - Profile & preferences

    func profile() async throws -> Profile { try await request("profile") }
    func entitlements() async throws -> Entitlement { try await request("entitlements") }
    func updateProfile(fullName: String, phone: String, targetRoles: [String]) async throws -> Profile {
        try await request("profile", method: "POST", body: [
            "full_name": fullName, "phone": phone, "target_roles": targetRoles,
        ])
    }

    // MARK: - Jobs

    func searchJobs(query: String, location: String? = nil, page: Int = 1, limit: Int = 20) async throws -> [Job] {
        var queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: String(limit))]
        if let location { queryItems.append(URLQueryItem(name: "location", value: location)) }
        return try await request("jobs", query: queryItems)
    }

    func savedJobs() async throws -> [Job] { try await request("saved-jobs") }

    func saveJob(id: String) async throws {
        let _: [String: String] = try await request("saved-jobs", method: "POST", body: ["jobId": id])
    }

    func unsaveJob(id: String) async throws {
        let _: [String: String] = try await request("saved-jobs", method: "DELETE", query: [URLQueryItem(name: "jobId", value: id)])
    }

    // MARK: - Applications

    func applications() async throws -> [Application] { try await request("applications") }

    func approveApplication(id: String) async throws {
        let _: [String: String] = try await request("applications/\(id)/approve", method: "POST")
    }

    func rejectApplication(id: String) async throws {
        let _: [String: String] = try await request("applications/\(id)/reject", method: "POST")
    }

    func withdrawApplication(id: String) async throws {
        let _: [String: String] = try await request("applications/\(id)/withdraw", method: "POST")
    }

    /// Direct the agent at any career link (the "target" flow).
    func targetApplication(url: String) async throws {
        let _: [String: String] = try await request("applications/target", method: "POST", body: ["url": url])
    }

    // MARK: - ATS scan

    func atsScan(resumeText: String, jobDescription: String) async throws -> [String: String] {
        try await request("ats/scan", method: "POST", body: [
            "resumeText": resumeText, "jobDescription": jobDescription,
        ])
    }
}

enum APIError: LocalizedError {
    case transport
    case server(Int, String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .transport: return "Network request failed."
        case .server(let code, let body): return "Server error \(code): \(body.prefix(200))"
        case .decoding(let detail): return "Unexpected response: \(detail.prefix(200))"
        }
    }
}
