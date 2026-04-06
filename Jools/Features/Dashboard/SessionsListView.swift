import SwiftUI
import SwiftData
import JoolsKit

/// List view showing all sessions
struct SessionsListView: View {
    @EnvironmentObject private var dependencies: AppDependency
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionEntity.updatedAt, order: .reverse) private var sessions: [SessionEntity]
    @State private var searchText: String = ""
    @State private var isLoading = false

    private var filteredSessions: [SessionEntity] {
        if searchText.isEmpty {
            return sessions
        }
        return sessions.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.prompt.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredSessions, id: \.id) { session in
                    NavigationLink {
                        ChatView(session: session)
                    } label: {
                        SessionListRow(session: session)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("session.row.\(session.id)")
                }
            }
            .listStyle(.plain)
            .navigationTitle("Sessions")
            .searchable(text: $searchText, prompt: "Search sessions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { Task { await refreshSessions() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                    .accessibilityIdentifier("sessions.refresh")
                }
            }
            .refreshable {
                await refreshSessions()
            }
            .overlay {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Pull to refresh or create a session on jules.google.com")
                    )
                } else if filteredSessions.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
        .task {
            guard !dependencies.isUITestMode else { return }
            await refreshSessions()
        }
    }

    private func refreshSessions() async {
        guard !dependencies.isUITestMode else { return }
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await dependencies.apiClient.listSessions()
            syncSessions(response.allItems)
            try modelContext.save()
        } catch {
            print("Failed to refresh sessions: \(error)")
        }
    }

    private func syncSessions(_ dtos: [SessionDTO]) {
        for dto in dtos {
            let descriptor = FetchDescriptor<SessionEntity>(
                predicate: #Predicate { $0.id == dto.id }
            )

            if let existing = try? modelContext.fetch(descriptor).first {
                existing.title = dto.title ?? "Untitled"
                existing.prompt = dto.prompt
                existing.stateRaw = dto.state ?? SessionState.unspecified.rawValue
                existing.updatedAt = dto.updateTime ?? Date()

                if let output = dto.outputs?.first?.pullRequest {
                    existing.prURL = output.url
                    existing.prTitle = output.title
                    existing.prDescription = output.description
                }
            } else {
                let entity = SessionEntity(from: dto)
                modelContext.insert(entity)
            }
        }
    }
}

struct SessionListRow: View {
    let session: SessionEntity

    var body: some View {
        VStack(alignment: .leading, spacing: JoolsSpacing.xs) {
            HStack {
                Text(session.title)
                    .font(.joolsHeadline)
                    .lineLimit(1)

                Spacer()

                SessionStateBadge(state: session.state)
            }

            Text(session.prompt)
                .font(.joolsBody)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Image(systemName: "folder")
                    .font(.caption2)
                Text(session.sourceId.replacingOccurrences(of: "sources/", with: ""))
                    .font(.joolsCaption)

                Spacer()

                Text(session.updatedAt, style: .relative)
                    .font(.joolsCaption)
            }
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, JoolsSpacing.xs)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("session.row.content.\(session.id)")
    }
}

#Preview {
    NavigationStack {
        SessionsListView()
    }
}
