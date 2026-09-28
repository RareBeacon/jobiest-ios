import SwiftUI

@MainActor
final class JobsViewModel: ObservableObject {
    @Published var query = ""
    @Published var jobs: [Job] = []
    @Published var saved: [Job] = []
    @Published var error: String?
    @Published var loading = false

    func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        loading = true
        error = nil
        do {
            jobs = try await APIClient.shared.searchJobs(query: query)
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    func loadSaved() async {
        do {
            saved = try await APIClient.shared.savedJobs()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleSaved(_ job: Job) async {
        do {
            if job.isSaved == true {
                try await APIClient.shared.unsaveJob(id: job.id)
            } else {
                try await APIClient.shared.saveJob(id: job.id)
            }
            await search()
            await loadSaved()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct JobsView: View {
    @StateObject private var model = JobsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Search jobs (role, keyword)", text: $model.query)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { Task { await model.search() } }
                        Button("Go") { Task { await model.search() } }
                            .buttonStyle(.borderedProminent)
                    }
                }
                if model.loading { ProgressView().frame(maxWidth: .infinity) }
                if let error = model.error {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
                Section("Results") {
                    ForEach(model.jobs) { job in
                        row(job)
                    }
                }
                Section("Saved") {
                    if model.saved.isEmpty {
                        Text("No saved jobs yet.").foregroundStyle(.secondary)
                    }
                    ForEach(model.saved) { job in
                        row(job)
                    }
                }
            }
            .navigationTitle("Jobs")
            .task { await model.loadSaved() }
        }
    }

    @ViewBuilder
    private func row(_ job: Job) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(job.title ?? "Untitled role").font(.headline)
            Text([job.company, job.location].compactMap { $0 }.joined(separator: " - "))
                .font(.subheadline).foregroundStyle(.secondary)
            HStack {
                if let source = job.source {
                    Text(source).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.fill.tertiary, in: Capsule())
                }
                Spacer()
                Button {
                    Task { await model.toggleSaved(job) }
                } label: {
                    Image(systemName: job.isSaved == true ? "bookmark.fill" : "bookmark")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
