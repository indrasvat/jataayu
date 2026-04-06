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
                    if config.showsMascot {
                        PixelJulesMascot(mood: config.mascotMood)
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)
                    } else if config.showSpinner {
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
                return "\(freshnessLabel(for: lastUpdatedAt)) • Pull to refresh"
            }
            return "Pull to refresh"
        case .syncing:
            if let lastUpdatedAt {
                return "Syncing… \(freshnessLabel(for: lastUpdatedAt))"
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
                showPollingIndicator: true,
                showsMascot: true,
                mascotMood: .working
            )

        case .queued:
            return BannerConfig(
                message: "Session queued, starting soon",
                icon: "clock.fill",
                backgroundColor: Color.orange.opacity(0.15),
                foregroundColor: Color.orange,
                showSpinner: true,
                animateDots: true,
                showPollingIndicator: true,
                showsMascot: true,
                mascotMood: .queued
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
                showPollingIndicator: true,
                showsMascot: true,
                mascotMood: .starting
            )
        }
    }

    private func freshnessLabel(for date: Date) -> String {
        let elapsed = Date().timeIntervalSince(date)

        switch elapsed {
        case ..<30:
            return "Updated just now"
        case ..<90:
            return "Updated about a minute ago"
        case ..<3600:
            let minutes = max(1, Int(elapsed / 60))
            return "Updated \(minutes) min ago"
        default:
            return "Updated \(date.formatted(.relative(presentation: .named)))"
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
    var showsMascot: Bool = false
    var mascotMood: PixelJulesMascot.Mood = .working
}

private struct PixelJulesMascot: View {
    enum Mood {
        case starting
        case queued
        case working
    }

    let mood: Mood

    @State private var isFloating = false

    private let activeCells: [(x: Int, y: Int, role: Role)] = [
        (4, 0, .highlight), (5, 0, .highlight),
        (3, 1, .highlight), (4, 1, .head), (5, 1, .head), (6, 1, .highlight),
        (2, 2, .highlight), (3, 2, .head), (4, 2, .head), (5, 2, .head), (6, 2, .head), (7, 2, .highlight),
        (2, 3, .highlight), (3, 3, .head), (4, 3, .eye), (5, 3, .eye), (6, 3, .head), (7, 3, .highlight),
        (2, 4, .head), (3, 4, .head), (4, 4, .head), (5, 4, .head), (6, 4, .head), (7, 4, .head),
        (3, 5, .tentacle), (4, 5, .head), (5, 5, .head), (6, 5, .tentacle),
        (2, 6, .tentacle), (3, 6, .tentacle), (4, 6, .head), (5, 6, .head), (6, 6, .tentacle), (7, 6, .tentacle),
        (1, 7, .tentacle), (2, 7, .tentacle), (4, 7, .tentacle), (5, 7, .tentacle), (7, 7, .tentacle), (8, 7, .tentacle),
    ]

    var body: some View {
        GeometryReader { geometry in
            let gridSize = 9
            let cellSize = min(geometry.size.width, geometry.size.height) / CGFloat(gridSize)
            let pixelSize = cellSize * 0.9

            ZStack {
                ForEach(Array(activeCells.enumerated()), id: \.offset) { _, cell in
                    RoundedRectangle(cornerRadius: cellSize * 0.2, style: .continuous)
                        .fill(color(for: cell.role))
                        .frame(width: pixelSize, height: pixelSize)
                        .overlay {
                            RoundedRectangle(cornerRadius: cellSize * 0.2, style: .continuous)
                                .stroke(Color.white.opacity(cell.role == .eye ? 0 : 0.12), lineWidth: cellSize * 0.05)
                        }
                        .offset(
                            x: CGFloat(cell.x) * cellSize + (cellSize - pixelSize) / 2,
                            y: CGFloat(cell.y) * cellSize + (cellSize - pixelSize) / 2
                        )
                }

                sparkle
            }
            .frame(width: CGFloat(gridSize) * cellSize, height: CGFloat(gridSize) * cellSize)
            .offset(y: isFloating ? -2 : 2)
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 6)
            .animation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true), value: isFloating)
            .onAppear {
                isFloating = true
            }
        }
    }

    @ViewBuilder
    private var sparkle: some View {
        switch mood {
        case .starting:
            Image(systemName: "sparkle")
                .font(.system(size: 6, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.9))
                .offset(x: 11, y: -8)
        case .queued:
            Image(systemName: "clock.fill")
                .font(.system(size: 6, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.9))
                .offset(x: 11, y: -8)
        case .working:
            Image(systemName: "ellipsis")
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(Color.white.opacity(0.9))
                .offset(x: 12, y: -8)
        }
    }

    private func color(for role: Role) -> Color {
        switch role {
        case .head:
            switch mood {
            case .starting:
                return Color.joolsAccentLight
            case .queued:
                return Color.orange
            case .working:
                return Color.joolsAccent
            }
        case .highlight:
            return Color.white.opacity(0.95)
        case .tentacle:
            switch mood {
            case .starting:
                return Color.joolsAccent
            case .queued:
                return Color.orange.opacity(0.85)
            case .working:
                return Color.joolsAccentDark
            }
        case .eye:
            return Color.black.opacity(0.78)
        }
    }

    private enum Role {
        case head
        case highlight
        case tentacle
        case eye
    }
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
