import SwiftUI
import UIKit

struct ScheduledTaskComposerView: View {
    let source: SourceEntity
    let template: ScheduledSkillTemplate

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var cadence: ScheduleCadence = .daily
    @State private var selectedBranch: String = "main"
    @State private var runTime: Date = Calendar.current.date(
        bySettingHour: 13,
        minute: 0,
        second: 0,
        of: .now
    ) ?? .now
    @State private var showPromptDetails = false
    @State private var copiedPrompt = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: JoolsSpacing.lg) {
                    roleCard
                    scheduleCard
                    handoffCard
                }
                .padding()
            }
            .background(Color.joolsBackground)
            .navigationTitle("Scheduled Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("scheduled.composer")
    }

    private var roleCard: some View {
        VStack(alignment: .leading, spacing: JoolsSpacing.md) {
            HStack(spacing: JoolsSpacing.sm) {
                Image(systemName: template.icon)
                    .font(.title2)
                    .foregroundStyle(template.accent)
                    .frame(width: 40, height: 40)
                    .background(template.accent.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.md))

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.joolsTitle3)
                    Text(template.subtitle)
                        .font(.joolsCaption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text(template.details)
                .font(.joolsBody)
                .foregroundStyle(.secondary)

            DisclosureGroup("Prompt details", isExpanded: $showPromptDetails) {
                Text(template.prompt)
                    .font(.joolsBody)
                    .foregroundStyle(.primary)
                    .padding(.top, JoolsSpacing.sm)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("scheduled.prompt")
            }
            .font(.joolsBody)
            .tint(.secondary)
        }
        .padding()
        .background(Color.joolsSurface)
        .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.lg))
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: JoolsSpacing.md) {
            Text("Schedule")
                .font(.joolsHeadline)

            Picker("Cadence", selection: $cadence) {
                ForEach(ScheduleCadence.allCases) { cadence in
                    Text(cadence.title).tag(cadence)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                VStack(alignment: .leading, spacing: JoolsSpacing.xxs) {
                    Text("Time")
                        .font(.joolsCaption)
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "",
                        selection: $runTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: JoolsSpacing.xxs) {
                    Text("Timezone")
                        .font(.joolsCaption)
                        .foregroundStyle(.secondary)
                    Text(TimeZone.current.identifier)
                        .font(.joolsBody)
                        .multilineTextAlignment(.trailing)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: JoolsSpacing.xxs) {
                Text("Repository")
                    .font(.joolsCaption)
                    .foregroundStyle(.secondary)
                Text("\(source.owner)/\(source.repo)")
                    .font(.joolsBody)
            }

            VStack(alignment: .leading, spacing: JoolsSpacing.xxs) {
                Text("Branch")
                    .font(.joolsCaption)
                    .foregroundStyle(.secondary)
                Menu {
                    ForEach(["main", "master", "develop"], id: \.self) { branch in
                        Button(branch) {
                            selectedBranch = branch
                        }
                    }
                } label: {
                    HStack(spacing: JoolsSpacing.xs) {
                        Image(systemName: "arrow.triangle.branch")
                        Text(selectedBranch)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.joolsBody)
                    .padding(.horizontal, JoolsSpacing.sm)
                    .padding(.vertical, JoolsSpacing.xs)
                    .background(Color.joolsSurfaceElevated)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.joolsSurface)
        .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.lg))
    }

    private var handoffCard: some View {
        VStack(alignment: .leading, spacing: JoolsSpacing.md) {
            Label("Web handoff required", systemImage: "globe")
                .font(.joolsHeadline)

            Text("The official Jules API does not yet expose scheduled-task creation. Jools prepares the task here, then you finish creation in Jules web.")
                .font(.joolsBody)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: JoolsSpacing.xxs) {
                Text("Next steps")
                    .font(.joolsCaption)
                    .foregroundStyle(.secondary)
                Text("1. Copy the prepared prompt.\n2. Open Jules web.\n3. Paste into the Scheduled tab for this repo and choose the same cadence and branch.")
                    .font(.joolsBody)
            }

            HStack(spacing: JoolsSpacing.sm) {
                Button {
                    UIPasteboard.general.string = template.prompt
                    copiedPrompt = true
                } label: {
                    Label(copiedPrompt ? "Copied" : "Copy Prompt", systemImage: copiedPrompt ? "checkmark.circle.fill" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.joolsAccent)
                .accessibilityIdentifier("scheduled.copyPrompt")

                Button {
                    openURL(URL(string: "https://jules.google.com/session")!)
                } label: {
                    Label("Open Jules", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("scheduled.openWeb")
            }
        }
        .padding()
        .background(Color.joolsSurface)
        .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.lg))
    }
}
