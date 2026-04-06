import SwiftUI
import SwiftData
import JoolsKit

/// View for creating a new Jules session, matching the web UI
struct CreateSessionView: View {
    let source: SourceEntity
    @EnvironmentObject private var dependencies: AppDependency
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateSessionViewModel
    @FocusState private var promptFocused: Bool

    init(
        source: SourceEntity,
        initialPrompt: String = "",
        initialTitle: String = "",
        initialSessionMode: SessionMode = .interactivePlan
    ) {
        self.source = source
        _viewModel = StateObject(
            wrappedValue: CreateSessionViewModel(
                source: source,
                initialPrompt: initialPrompt,
                initialTitle: initialTitle,
                initialSessionMode: initialSessionMode
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Source header
                SourceHeader(name: viewModel.sourceDisplayName)

                Divider()

                // Main content
                ScrollView {
                    VStack(spacing: JoolsSpacing.lg) {
                        // Prompt input
                        PromptInput(
                            prompt: $viewModel.prompt,
                            isFocused: $promptFocused
                        )

                        // Options bar
                        OptionsBar(viewModel: viewModel)

                        // Advanced options (collapsed)
                        AdvancedOptionsSection(viewModel: viewModel)
                    }
                    .padding()
                }

                Divider()

                // Bottom action bar
                BottomActionBar(viewModel: viewModel) {
                    Task {
                        await viewModel.createSession()
                    }
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay(message: "Creating session...")
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.error ?? "An error occurred")
            }
            .sheet(isPresented: $viewModel.showModeSheet) {
                SessionModeSheet(selectedMode: $viewModel.sessionMode)
                    .presentationDetents([.medium])
            }
            .navigationDestination(item: $viewModel.createdSession) { session in
                ChatView(session: session)
            }
            .onAppear {
                viewModel.configure(apiClient: dependencies.apiClient, modelContext: modelContext)
                promptFocused = true
            }
        }
    }
}

// MARK: - Source Header

private struct SourceHeader: View {
    let name: String

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(Color.joolsAccent)

            Text(name)
                .font(.joolsBody)
                .fontWeight(.medium)

            Spacer()
        }
        .padding()
        .background(Color.joolsSurface)
    }
}

// MARK: - Prompt Input

private struct PromptInput: View {
    @Binding var prompt: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: JoolsSpacing.xs) {
            TextField(
                "What should Jules work on?",
                text: $prompt,
                axis: .vertical
            )
            .font(.joolsBody)
            .lineLimit(4...12)
            .focused(isFocused)
            .padding()
            .background(Color.joolsSurface)
            .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.md))

            Text("Be specific about what you want Jules to accomplish.")
                .font(.joolsCaption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Options Bar

private struct OptionsBar: View {
    @ObservedObject var viewModel: CreateSessionViewModel

    var body: some View {
        HStack(spacing: JoolsSpacing.sm) {
            // Branch picker
            Menu {
                ForEach(viewModel.availableBranches, id: \.self) { branch in
                    Button(branch) {
                        viewModel.selectedBranch = branch
                    }
                }
            } label: {
                HStack(spacing: JoolsSpacing.xxs) {
                    Image(systemName: "arrow.triangle.branch")
                    Text(viewModel.selectedBranch)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .font(.joolsCaption)
                .padding(.horizontal, JoolsSpacing.sm)
                .padding(.vertical, JoolsSpacing.xs)
                .background(Color.joolsSurface)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            // Session mode picker
            Button {
                viewModel.showModeSheet = true
            } label: {
                HStack(spacing: JoolsSpacing.xxs) {
                    Image(systemName: viewModel.sessionMode.icon)
                    Text(viewModel.sessionMode.title)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .font(.joolsCaption)
                .padding(.horizontal, JoolsSpacing.sm)
                .padding(.vertical, JoolsSpacing.xs)
                .background(Color.joolsAccent.opacity(0.15))
                .foregroundStyle(Color.joolsAccent)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Advanced Options

private struct AdvancedOptionsSection: View {
    @ObservedObject var viewModel: CreateSessionViewModel
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup("Advanced Options", isExpanded: $isExpanded) {
            VStack(spacing: JoolsSpacing.md) {
                // Title input
                VStack(alignment: .leading, spacing: JoolsSpacing.xxs) {
                    Text("Session Title (optional)")
                        .font(.joolsCaption)
                        .foregroundStyle(.secondary)

                    TextField("Auto-generated from prompt", text: $viewModel.title)
                        .font(.joolsBody)
                        .padding()
                        .background(Color.joolsSurface)
                        .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.sm))
                }

                // Auto PR toggle
                Toggle(isOn: $viewModel.autoCreatePR) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-create Pull Request")
                            .font(.joolsBody)
                        Text("Automatically create a PR when session completes")
                            .font(.joolsCaption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(Color.joolsAccent)
            }
            .padding(.top, JoolsSpacing.sm)
        }
        .font(.joolsBody)
        .tint(.secondary)
    }
}

// MARK: - Bottom Action Bar

private struct BottomActionBar: View {
    @ObservedObject var viewModel: CreateSessionViewModel
    let onSubmit: () -> Void

    var body: some View {
        HStack {
            // Mode summary
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.sessionMode.title)
                    .font(.joolsCaption)
                    .fontWeight(.medium)
                Text(viewModel.sessionMode == .start ? "No approval needed" : "Plan approval required")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Submit button
            Button(action: onSubmit) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title)
                    .foregroundStyle(viewModel.canCreate ? Color.joolsAccent : Color.secondary)
            }
            .disabled(!viewModel.canCreate)
        }
        .padding()
        .background(.bar)
    }
}

// MARK: - Session Mode Sheet

private struct SessionModeSheet: View {
    @Binding var selectedMode: SessionMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(SessionMode.allCases) { mode in
                    Button {
                        selectedMode = mode
                        HapticManager.shared.selection()
                        dismiss()
                    } label: {
                        HStack(spacing: JoolsSpacing.md) {
                            Image(systemName: mode.icon)
                                .font(.title2)
                                .foregroundStyle(selectedMode == mode ? Color.joolsAccent : .secondary)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.title)
                                    .font(.joolsBody)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)

                                Text(mode.description)
                                    .font(.joolsCaption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.joolsAccent)
                            }
                        }
                        .padding(.vertical, JoolsSpacing.xs)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Session Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: JoolsSpacing.md) {
                ProgressView()
                    .scaleEffect(1.2)

                Text(message)
                    .font(.joolsBody)
                    .foregroundStyle(.white)
            }
            .padding(JoolsSpacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.lg))
        }
    }
}

#Preview {
    CreateSessionView(source: SourceEntity(
        id: "github/owner/repo",
        name: "sources/github/owner/repo",
        owner: "owner",
        repo: "repo"
    ))
    .environmentObject(AppDependency())
}
