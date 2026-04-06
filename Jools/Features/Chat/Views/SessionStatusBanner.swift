import SwiftUI
import JoolsKit

/// A prominent banner showing the current session status with contextual messaging
struct SessionStatusBanner: View {
    let state: SessionState
    let syncState: SessionSyncState
    let isPolling: Bool
    let lastUpdatedAt: Date?
    let currentStepTitle: String?
    let currentStepDescription: String?
    let onRetry: () -> Void

    @State private var dotCount = 1
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        if let config = bannerConfig {
            VStack(alignment: .leading, spacing: JoolsSpacing.xs) {
                HStack(spacing: JoolsSpacing.sm) {
                    if config.showSpinner {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(config.foregroundColor)
                    } else {
                        Image(systemName: config.icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(config.foregroundColor)
                    }

                    HStack(spacing: 0) {
                        Text(config.message)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(config.foregroundColor)

                        if config.animateDots {
                            Text(String(repeating: ".", count: dotCount))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(config.foregroundColor)
                                .frame(width: 20, alignment: .leading)
                        }
                    }

                    Spacer()

                    if isPolling && config.showPollingIndicator {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Live")
                                .font(.caption2)
                                .foregroundStyle(config.foregroundColor.opacity(0.8))
                        }
                    }
                }

                if let currentStepTitle {
                    Text(currentStepTitle)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                        .accessibilityIdentifier("chat.current-step-title")
                }

                if let currentStepDescription, !currentStepDescription.isEmpty {
                    Text(currentStepDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: JoolsSpacing.sm) {
                    Text(syncFooterText)
                        .font(.caption2)
                        .foregroundStyle(config.foregroundColor.opacity(0.85))

                    Spacer()

                    if syncState.canRetry {
                        Button("Tap to retry", action: onRetry)
                            .font(.caption.weight(.semibold))
                            .buttonStyle(.plain)
                            .foregroundStyle(config.foregroundColor)
                            .accessibilityIdentifier("chat.retry")
                    }
                }
            }
            .padding(.horizontal, JoolsSpacing.md)
            .padding(.vertical, JoolsSpacing.sm)
            .background(config.backgroundColor)
            .accessibilityIdentifier("chat.status-banner")
            .onReceive(timer) { _ in
                if config.animateDots {
                    dotCount = (dotCount % 3) + 1
                }
            }
        }
    }

    private var syncFooterText: String {
        switch syncState {
        case .idle:
            if let lastUpdatedAt {
                return "Last updated \(lastUpdatedAt.formatted(.relative(presentation: .named))) • Pull to refresh"
            }
            return "Pull to refresh"
        case .syncing:
            if let lastUpdatedAt {
                return "Syncing… Last updated \(lastUpdatedAt.formatted(.relative(presentation: .named)))"
            }
            return "Syncing…"
        case .stale(let message), .failed(let message):
            return message
        }
    }

    private var bannerConfig: BannerConfig? {
        switch state {
        case .running, .inProgress:
            return BannerConfig(
                message: "Jules is working",
                icon: "gearshape.2.fill",
                backgroundColor: Color.joolsAccent.opacity(0.15),
                foregroundColor: Color.joolsAccent,
                showSpinner: true,
                animateDots: true,
                showPollingIndicator: true
            )

        case .queued:
            return BannerConfig(
                message: "Session queued, starting soon",
                icon: "clock.fill",
                backgroundColor: Color.orange.opacity(0.15),
                foregroundColor: Color.orange,
                showSpinner: true,
                animateDots: true,
                showPollingIndicator: true
            )

        case .awaitingUserInput:
            return BannerConfig(
                message: "Jules needs your input",
                icon: "bubble.left.fill",
                backgroundColor: Color.joolsAwaiting.opacity(0.15),
                foregroundColor: Color.joolsAwaiting
            )

        case .awaitingPlanApproval:
            return BannerConfig(
                message: "Review and approve the plan",
                icon: "doc.text.fill",
                backgroundColor: Color.joolsAwaiting.opacity(0.15),
                foregroundColor: Color.joolsAwaiting
            )

        case .completed:
            return BannerConfig(
                message: "Session completed",
                icon: "checkmark.circle.fill",
                backgroundColor: Color.joolsSuccess.opacity(0.15),
                foregroundColor: Color.joolsSuccess
            )

        case .failed:
            return BannerConfig(
                message: "Session encountered an error",
                icon: "exclamationmark.triangle.fill",
                backgroundColor: Color.joolsError.opacity(0.15),
                foregroundColor: Color.joolsError
            )

        case .cancelled:
            return BannerConfig(
                message: "Session was cancelled",
                icon: "xmark.circle.fill",
                backgroundColor: Color.secondary.opacity(0.15),
                foregroundColor: Color.secondary
            )

        case .unspecified:
            return BannerConfig(
                message: "Jules is starting up",
                icon: "hourglass",
                backgroundColor: Color.joolsAccent.opacity(0.15),
                foregroundColor: Color.joolsAccent,
                showSpinner: true,
                animateDots: true,
                showPollingIndicator: true
            )
        }
    }
}

private struct BannerConfig {
    let message: String
    let icon: String
    let backgroundColor: Color
    let foregroundColor: Color
    var showSpinner: Bool = false
    var animateDots: Bool = false
    var showPollingIndicator: Bool = false
}

#Preview("Session Status Banners") {
    VStack(spacing: 0) {
        SessionStatusBanner(
            state: .running,
            syncState: .syncing,
            isPolling: true,
            lastUpdatedAt: .now.addingTimeInterval(-10),
            currentStepTitle: "Provide the summary to the user",
            currentStepDescription: "Reply to the user directly in chat with the latest findings.",
            onRetry: {}
        )
        SessionStatusBanner(
            state: .awaitingPlanApproval,
            syncState: .idle,
            isPolling: false,
            lastUpdatedAt: .now.addingTimeInterval(-42),
            currentStepTitle: "Review the generated plan",
            currentStepDescription: "Approve the plan to let Jules continue.",
            onRetry: {}
        )
        SessionStatusBanner(
            state: .completed,
            syncState: .stale(message: "Showing the last synced timeline. Pull to refresh or tap to retry."),
            isPolling: false,
            lastUpdatedAt: .now.addingTimeInterval(-120),
            currentStepTitle: "Session completed",
            currentStepDescription: nil,
            onRetry: {}
        )
    }
    .background(Color.joolsBackground)
}
