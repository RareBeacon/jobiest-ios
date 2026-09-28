import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            JobsView()
                .tabItem { Label("Jobs", systemImage: "magnifyingglass") }
            ApplicationsView()
                .tabItem { Label("Applications", systemImage: "doc.text.fill") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}
