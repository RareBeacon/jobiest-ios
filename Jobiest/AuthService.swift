import Foundation

/// Supabase GoTrue auth client. Mirrors the Android app: identity lives with
/// Supabase, business data with jobiest.com. Tokens are persisted in Keychain.
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var userEmail: String?

    private let session = URLSession.shared

    private init() {
        if let email = KeychainStore.get("user_email"), KeychainStore.get("access_token") != nil {
            isAuthenticated = true
            userEmail = email
        }
    }

    // MARK: - Sign in

    func signIn(email: String, password: String) async throws {
        var request = URLRequest(url: Config.authURL("token?grant_type=password"))
        request.httpMethod = "POST"
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email, "password": password])
        let (data, response) = try await session.data(for: request)
        try ensureSuccess(response, data: data)
        let session = try JSONDecoder().decode(AuthSession.self, from: data)
        persist(session: session)
    }

    // MARK: - Sign up

    func signUp(email: String, password: String, fullName: String) async throws {
        var request = URLRequest(url: Config.authURL("signup"))
        request.httpMethod = "POST"
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "email": email,
            "password": password,
            "data": ["full_name": fullName],
        ])
        let (data, response) = try await session.data(for: request)
        try ensureSuccess(response, data: data)
        // Signup may return a session immediately or require email confirmation;
        // if a session came back, store it; otherwise prompt the user to confirm.
        if let session = try? JSONDecoder().decode(AuthSession.self, from: data) {
            persist(session: session)
        }
    }

    // MARK: - Refresh

    /// Refresh the access token using the stored refresh token. Call when an API
    /// request returns 401.
    func refresh() async throws {
        guard let refreshToken = KeychainStore.get("refresh_token") else {
            throw AuthError.notSignedIn
        }
        var request = URLRequest(url: Config.authURL("token?grant_type=refresh_token"))
        request.httpMethod = "POST"
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["refresh_token": refreshToken])
        let (data, response) = try await session.data(for: request)
        try ensureSuccess(response, data: data)
        let session = try JSONDecoder().decode(AuthSession.self, from: data)
        persist(session: session)
    }

    // MARK: - Sign out

    func signOut() {
        KeychainStore.delete("access_token")
        KeychainStore.delete("refresh_token")
        KeychainStore.delete("user_email")
        isAuthenticated = false
        userEmail = nil
    }

    var accessToken: String? { KeychainStore.get("access_token") }

    // MARK: - Private

    private func persist(session: AuthSession) {
        KeychainStore.set(session.accessToken, forKey: "access_token")
        KeychainStore.set(session.refreshToken, forKey: "refresh_token")
        KeychainStore.set(session.user.email ?? "", forKey: "user_email")
        isAuthenticated = true
        userEmail = session.user.email
    }

    private func ensureSuccess(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["msg"]
                ?? (try? JSONDecoder().decode([String: String].self, from: data))?["error_description"]
                ?? String(data: data, encoding: .utf8) ?? "Request failed"
            throw AuthError.server(message)
        }
    }
}

enum AuthError: LocalizedError {
    case notSignedIn
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "Not signed in."
        case .server(let message): return message
        }
    }
}
