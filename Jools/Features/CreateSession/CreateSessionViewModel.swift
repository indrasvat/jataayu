import SwiftUI
import SwiftData
import JoolsKit

/// Session mode matching Jules web UI options
enum SessionMode: String, CaseIterable, Identifiable {
    case interactivePlan = "interactive"
    case review = "review"
    case start = "start"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .interactivePlan: return "Interactive plan"
        case .review: return "Review"
        case .start: return "Start"
        }
    }

    var description: String {
        switch self {
        case .interactivePlan:
            return "Chat with Jules to understand goals before planning and approval"
        case .review:
            return "Generate plan and wait for approval"
        case .start:
            return "Get started without plan approval"
        }
    }

    var icon: String {
        switch self {
        case .interactivePlan: return "bubble.left.and.bubble.right"
        case .review: return "doc.text.magnifyingglass"
        case .start: return "play.fill"
        }
    }

    /// Maps to API's requirePlanApproval field
    var requirePlanApproval: Bool {
        switch self {
        case .interactivePlan, .review: return true
        case .start: return false
        }
    }
}

/// View model for creating a new Jules session
@MainActor
final class CreateSessionViewModel: ObservableObject {
    // MARK: - State

    @Published var prompt: String = ""
    @Published var title: String = ""
    @Published var selectedBranch: String = "main"
    @Published var availableBranches: [String] = ["main", "master", "develop"]
    @Published var sessionMode: SessionMode = .interactivePlan
    @Published var autoCreatePR: Bool = true

    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var showError: Bool = false
    @Published var showModeSheet: Bool = false

    @Published var createdSession: SessionEntity?

    // MARK: - Source Info

    let source: SourceEntity

    // MARK: - Dependencies

    private var apiClient: APIClient?
    private var modelContext: ModelContext?

    // MARK: - Computed

    var canCreate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    var effectiveTitle: String {
        title.isEmpty ? String(prompt.prefix(50)) : title
    }

    var sourceDisplayName: String {
        "\(source.owner)/\(source.repo)"
    }

    // MARK: - Initialization

    init(
        source: SourceEntity,
        initialPrompt: String = "",
        initialTitle: String = "",
        initialSessionMode: SessionMode = .interactivePlan
    ) {
        self.source = source
        self.prompt = initialPrompt
        self.title = initialTitle
        self.sessionMode = initialSessionMode
    }

    func configure(apiClient: APIClient, modelContext: ModelContext) {
        self.apiClient = apiClient
        self.modelContext = modelContext
    }

    // MARK: - Actions

    func createSession() async {
        guard canCreate, let apiClient, let modelContext else { return }

        isLoading = true
        defer { isLoading = false }

        HapticManager.shared.lightImpact()

        do {
            // Build source context - use proper source name format
            let sourceName = "sources/\(source.id)"

            let request = CreateSessionRequest(
                prompt: prompt,
                sourceContext: SourceContextDTO(
                    source: sourceName,
                    githubRepoContext: GitHubRepoContextDTO(startingBranch: selectedBranch)
                ),
                title: effectiveTitle,
                automationMode: autoCreatePR ? "AUTO_CREATE_PR" : nil,
                requirePlanApproval: sessionMode.requirePlanApproval
            )

            let sessionDTO = try await apiClient.createSession(request)

            // Save to SwiftData
            let session = SessionEntity(from: sessionDTO)
            modelContext.insert(session)
            try? modelContext.save()

            createdSession = session

            HapticManager.shared.success()

        } catch {
            self.error = error.localizedDescription
            self.showError = true
            HapticManager.shared.error()
        }
    }
}
