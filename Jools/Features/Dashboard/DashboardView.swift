import SwiftUI
import SwiftData

/// Main dashboard view showing sources and recent sessions
struct DashboardView: View {
    @EnvironmentObject private var dependencies: AppDependency
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionEntity.updatedAt, order: .reverse) private var sessions: [SessionEntity]
    @Query private var sources: [SourceEntity]

    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JoolsSpacing.lg) {
                    // Usage Stats Card
                    UsageStatsCard(
                        tasksUsed: viewModel.tasksUsedToday,
                        tasksLimit: viewModel.dailyTaskLimit
                    )

                    // Sources Section
                    if !sources.isEmpty {
                        SourcesSection(sources: sources)
                    }

                    // Recent Sessions Section
                    if !sessions.isEmpty {
                        RecentSessionsSection(sessions: Array(sessions.prefix(5)))
                    }

                    // Empty State
                    if sessions.isEmpty && sources.isEmpty {
                        EmptyDashboardView()
                    }
                }
                .padding()
            }
            .navigationTitle("Jools")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.refresh(using: dependencies, modelContext: modelContext) }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshAsync(using: dependencies, modelContext: modelContext)
            }
        }
        .task {
            await viewModel.refreshAsync(using: dependencies, modelContext: modelContext)
        }
    }
}

// MARK: - Supporting Views

struct UsageStatsCard: View {
    let tasksUsed: Int
    let tasksLimit: Int

    private var progress: Double {
        guard tasksLimit > 0 else { return 0 }
        return Double(tasksUsed) / Double(tasksLimit)
    }

    private var isNearLimit: Bool {
        progress > 0.8
    }

    var body: some View {
        VStack(alignment: .leading, spacing: JoolsSpacing.sm) {
            HStack {
                Text("Today's Usage")
                    .font(.joolsHeadline)
                Spacer()
                Text("\(tasksUsed)/\(tasksLimit)")
                    .font(.joolsBody)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(isNearLimit ? .joolsWarning : .joolsAccent)

            if isNearLimit {
                Text("You're approaching your daily limit")
                    .font(.joolsCaption)
                    .foregroundStyle(Color.joolsWarning)
            }
        }
        .padding()
        .background(Color.joolsSurface)
        .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.md))
    }
}

struct SourcesSection: View {
    let sources: [SourceEntity]

    private let columns = [
        GridItem(.flexible(), spacing: JoolsSpacing.sm),
        GridItem(.flexible(), spacing: JoolsSpacing.sm),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: JoolsSpacing.sm) {
            HStack {
                Text("Sources")
                    .font(.joolsHeadline)
                Spacer()
                Text("\(sources.count)")
                    .font(.joolsCaption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: JoolsSpacing.sm) {
                ForEach(sources, id: \.id) { source in
                    SourceCard(source: source)
                }
            }
        }
    }
}

struct SourceCard: View {
    let source: SourceEntity
    @State private var showCreateSession = false

    var body: some View {
        Button {
            showCreateSession = true
        } label: {
            HStack(spacing: JoolsSpacing.sm) {
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundStyle(Color.joolsAccent)
                    .frame(width: 36, height: 36)
                    .background(Color.joolsAccent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.sm))

                VStack(alignment: .leading, spacing: 2) {
                    Text(source.repo)
                        .font(.joolsBody)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(source.owner)
                        .font(.joolsCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundStyle(Color.joolsAccent.opacity(0.6))
            }
            .padding(JoolsSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.joolsSurface)
            .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.md))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showCreateSession) {
            CreateSessionView(source: source)
        }
    }
}

struct RecentSessionsSection: View {
    let sessions: [SessionEntity]

    var body: some View {
        VStack(alignment: .leading, spacing: JoolsSpacing.sm) {
            HStack {
                Text("Recent Sessions")
                    .font(.joolsHeadline)
                Spacer()
                NavigationLink("See All") {
                    SessionsListView()
                }
                .font(.joolsCaption)
            }

            ForEach(sessions, id: \.id) { session in
                SessionRow(session: session)
            }
        }
    }
}

struct SessionRow: View {
    let session: SessionEntity

    var body: some View {
        NavigationLink {
            ChatView(session: session)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: JoolsSpacing.xxs) {
                    Text(session.title)
                        .font(.joolsBody)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(session.prompt)
                        .font(.joolsCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                SessionStateBadge(state: session.state)
            }
            .padding()
            .background(Color.joolsSurface)
            .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.md))
        }
        .buttonStyle(.plain)
    }
}

struct EmptyDashboardView: View {
    var body: some View {
        VStack(spacing: JoolsSpacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Sessions Yet")
                .font(.joolsTitle3)

            Text("Connect a repository and create your first session")
                .font(.joolsBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, JoolsSpacing.xxl)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppDependency())
}
