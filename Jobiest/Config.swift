import Foundation

/// Central configuration. The anon key is Supabase's public client key (the same
/// one embedded in the website and the Android app); it is safe to ship in the
/// binary. The service-role key must NEVER be embedded in any client.
enum Config {
    static let supabaseBaseURL = URL(string: "https://cbxloutahmalorumaihc.supabase.co/auth/v1")!
    static let apiBaseURL = URL(string: "https://jobiest.com/api")!

    // TODO: paste the public anon key here (same value as the Android app).
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNieGxvdXRhaG1hbG9ydW1haWhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg4NzI4NDAsImV4cCI6MjEwNDQ0ODg0MH0.GP3wwoQMy1T0B6kop2Z9otN_iaZ7ntly2qNsqNWm5rg"

    static func authURL(_ path: String) -> URL {
        supabaseBaseURL.appendingPathComponent(path)
    }

    static func apiURL(_ path: String) -> URL {
        apiBaseURL.appendingPathComponent(path)
    }
}
