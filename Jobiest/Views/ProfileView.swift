import SwiftUI

struct ProfileView: View {
    @StateObject private var auth = AuthService.shared
    @State private var profile: Profile?
    @State private var entitlement: Entitlement?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("Email", value: auth.userEmail ?? "")
                    LabeledContent("Name", value: profile?.fullName ?? "-")
                    if let roles = profile?.targetRoles, !roles.isEmpty {
                        LabeledContent("Target roles", value: roles.joined(separator: ", "))
                    }
                }
                if let entitlement {
                    Section("Plan") {
                        LabeledContent("Plan", value: entitlement.plan ?? "-")
                        if let credits = entitlement.aiCreditsRemaining {
                            LabeledContent("AI generations left today", value: String(credits))
                        }
                        if let applications = entitlement.applicationsRemaining {
                            LabeledContent("Applications left", value: String(applications))
                        }
                    }
                }
                if let error {
                    Section { Text(error).font(.footnote).foregroundStyle(.red) }
                }
                // NOTE: no billing or upgrade links in the app (Apple rule 3.1.1).
                // Subscriptions are managed on the website.
                Section {
                    Button("Sign out", role: .destructive) { auth.signOut() }
                }
            }
            .navigationTitle("Profile")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        error = nil
        do {
            profile = try await APIClient.shared.profile()
            entitlement = try await APIClient.shared.entitlements()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
