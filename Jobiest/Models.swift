import Foundation

// Codable models for the Jobiest API. Field names follow
// API_INTEGRATION_GUIDE.md; adjust after verifying live responses.

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

struct AuthUser: Codable {
    let id: String
    let email: String?
}

struct Profile: Codable {
    let fullName: String?
    let phone: String?
    let targetRoles: [String]?
    let accountStatus: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case phone
        case targetRoles = "target_roles"
        case accountStatus = "account_status"
    }
}

struct Job: Codable, Identifiable {
    let id: String
    let title: String?
    let company: String?
    let location: String?
    let url: String?
    let source: String?
    let isSaved: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case company
        case location
        case url
        case source
        case isSaved = "isSaved"
    }
}

struct Application: Codable, Identifiable {
    let id: String
    let company: String?
    let title: String?
    let status: String?
    let url: String?
    let mode: String?
}

struct Entitlement: Codable {
    let plan: String?
    let aiCreditsRemaining: Int?
    let applicationsRemaining: Int?
    let toolUsesRemaining: Int?

    enum CodingKeys: String, CodingKey {
        case plan
        case aiCreditsRemaining = "ai_credits_remaining"
        case applicationsRemaining = "applications_remaining"
        case toolUsesRemaining = "tool_uses_remaining"
    }
}

struct SavedJobRequest: Codable {
    let jobId: String
}
