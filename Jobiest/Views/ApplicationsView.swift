import SwiftUI

/// Applications list with approve / reject actions.
///
/// PUSH NOTE: while on free (Personal Team) signing there is no push
/// notification entitlement. V1 refreshes by polling whenever the screen
/// appears (and via the refresh button). When the paid Apple Developer
/// account is active, replace polling with APNs push.
@MainActor
final class ApplicationsViewModel: ObservableObject {
    @Published var applications: [Application] = []
    @Published var error: String?
    @Published var loading = false

    func load() async {
        loading = true
        error = nil
        do {
            applications = try await APIClient.shared.applications()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    func approve(_ application: Application) async {
        do {
            try await APIClient.shared.approveApplication(id: application.id)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func reject(_ application: Application) async {
        do {
            try await APIClient.shared.rejectApplication(id: application.id)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ApplicationsView: View {
    @StateObject private var model = ApplicationsViewModel()

    var body: some View {
        NavigationStack {
            List {
                if model.loading { ProgressView().frame(maxWidth: .infinity) }
                if let error = model.error {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
                Section {
                    if model.applications.isEmpty && !model.loading {
                        Text("No applications yet. The agent will draft applications for your approval.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(model.applications) { application in
                        row(application)
                    }
                }
            }
            .navigationTitle("Applications")
            .refreshable { await model.load() }
            .task { await model.load() }
        }
    }

    @ViewBuilder
    private func row(_ application: Application) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(application.title ?? "Untitled application").font(.headline)
            Text(application.company ?? "").font(.subheadline).foregroundStyle(.secondary)
            HStack {
                Text(application.status ?? "")
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(statusColor(application.status).opacity(0.15), in: Capsule())
                    .foregroundStyle(statusColor(application.status))
                Spacer()
                if application.status == "DRAFT" {
                    Button("Approve") { Task { await model.approve(application) } }
                        .buttonStyle(.borderedProminent).controlSize(.small)
                    Button("Reject") { Task { await model.reject(application) } }
                        .buttonStyle(.bordered).controlSize(.small)
                }
            }
        }
        .swipeActions {
            if application.status == "DRAFT" {
                Button("Approve") { Task { await model.approve(application) } }.tint(.green)
                Button("Reject") { Task { await model.reject(application) } }.tint(.red)
            }
        }
    }

    private func statusColor(_ status: String?) -> Color {
        switch status {
        case "DRAFT": return .orange
        case "SUBMITTED", "APPLIED": return .blue
        case "APPROVED": return .green
        case "REJECTED", "WITHDRAWN": return .red
        default: return .gray
        }
    }
}
