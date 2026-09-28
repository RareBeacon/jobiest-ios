import SwiftUI

@main
struct JobiestApp: App {
    @StateObject private var auth = AuthService.shared

    var body: some Scene {
        WindowGroup {
            if auth.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
