import Foundation
import Combine

/// Configuration for the polling service
public enum PollingConfig {
    /// Interval when user is actively viewing a session (3 seconds)
    public static let activeInterval: TimeInterval = 3.0
    /// Interval when user hasn't interacted recently (10 seconds)
    public static let idleInterval: TimeInterval = 10.0
    /// Interval when app is in background (60 seconds)
    public static let backgroundInterval: TimeInterval = 60.0
    /// Time without interaction before switching to idle mode (30 seconds)
    public static let idleThreshold: TimeInterval = 30.0
}

/// Current state of the polling service
public enum PollingState: Sendable {
    case active
    case idle
    case background
    case stopped
}

public enum PollingRefreshReason: String, Sendable {
    case initialLoad
    case foregroundResume
    case userMessageSent
    case planApproved
    case manualRefresh
    case staleRecovery
    case scheduled
}

/// Delegate protocol for receiving polling updates
@MainActor
public protocol PollingServiceDelegate: AnyObject {
    func pollingService(_ service: PollingService, didUpdateSession session: SessionDTO, reason: PollingRefreshReason)
    func pollingService(_ service: PollingService, didUpdateActivities activities: [ActivityDTO], reason: PollingRefreshReason)
    func pollingService(_ service: PollingService, didEncounterError error: Error, reason: PollingRefreshReason)
}

/// Service that manages adaptive polling for session updates
@MainActor
public final class PollingService: ObservableObject {
    // MARK: - Published Properties

    @Published public private(set) var state: PollingState = .stopped
    @Published public private(set) var isPolling: Bool = false
    @Published public private(set) var lastPollTime: Date?

    // MARK: - Properties

    public weak var delegate: PollingServiceDelegate?

    private let api: APIClient
    private var pollingTask: Task<Void, Never>?
    private var pollInFlight = false
    private var queuedReason: PollingRefreshReason?
    private var lastUserInteraction: Date = Date()
    private var activeSessionId: String?
    private var lastActivityCreateTime: Date?
    private var burstIntervals: [TimeInterval] = []

    // MARK: - Initialization

    public init(api: APIClient) {
        self.api = api
    }

    deinit {
        pollingTask?.cancel()
    }

    // MARK: - Public API

    /// Start polling for updates on a specific session
    public func startPolling(sessionId: String, initialActivityCreateTime: Date? = nil) {
        activeSessionId = sessionId
        lastActivityCreateTime = initialActivityCreateTime
        state = .active
        lastUserInteraction = Date()
        restartPollingLoop()
    }

    /// Stop all polling
    public func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        state = .stopped
        isPolling = false
        activeSessionId = nil
        lastActivityCreateTime = nil
        burstIntervals = []
        queuedReason = nil
        pollInFlight = false
    }

    /// Call this when the user interacts with the app
    public func userDidInteract() {
        lastUserInteraction = Date()
        if state == .idle {
            state = .active
            restartPollingLoop()
        }
    }

    /// Trigger an immediate poll without waiting for the next interval
    public func triggerImmediatePoll(reason: PollingRefreshReason = .manualRefresh) {
        guard activeSessionId != nil else { return }
        if reason == .userMessageSent || reason == .planApproved {
            activateBurstMode()
        }
        Task { [weak self] in
            await self?.requestPoll(reason: reason)
        }
    }

    /// Notify the service that the app entered the background
    public func enterBackground() {
        guard state != .stopped else { return }
        state = .background
        restartPollingLoop()
    }

    /// Notify the service that the app entered the foreground
    public func enterForeground() {
        guard state != .stopped else { return }
        state = .active
        lastUserInteraction = Date()
        restartPollingLoop()
    }

    public func updateActivityCursor(_ createTime: Date?) {
        guard let createTime else { return }
        if let existingCreateTime = lastActivityCreateTime {
            lastActivityCreateTime = max(existingCreateTime, createTime)
        } else {
            lastActivityCreateTime = createTime
        }
    }

    // MARK: - Private Methods

    private func restartPollingLoop() {
        pollingTask?.cancel()

        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self, self.activeSessionId != nil else { break }

                self.updateStateIfNeeded()

                // Break out of loop if stopped (avoid Duration.seconds(.infinity) crash)
                guard self.state != .stopped else { break }

                let interval = self.nextInterval()
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await self.requestPoll(reason: .scheduled)
            }
        }
    }

    private func requestPoll(reason: PollingRefreshReason) async {
        guard activeSessionId != nil else { return }

        if pollInFlight {
            if queuedReason == nil || queuedReason == .scheduled {
                queuedReason = reason
            }
            return
        }

        pollInFlight = true
        isPolling = true
        defer {
            isPolling = false
            lastPollTime = Date()
            pollInFlight = false
            if let queuedReason {
                self.queuedReason = nil
                Task { [weak self] in
                    await self?.requestPoll(reason: queuedReason)
                }
            }
        }

        guard let sessionId = activeSessionId else { return }
        await performPoll(sessionId: sessionId, reason: reason)
    }

    private func performPoll(sessionId: String, reason: PollingRefreshReason) async {
        do {
            // Fetch session updates
            let session = try await api.getSession(id: sessionId)
            delegate?.pollingService(self, didUpdateSession: session, reason: reason)

            // Fetch new activities
            let activities = try await api.listAllActivities(
                sessionId: sessionId,
                pageSize: 100,
                createTime: lastActivityCreateTime
            )
            if let latestCreateTime = activities.compactMap(\.createTime).max() {
                updateActivityCursor(latestCreateTime)
            }
            delegate?.pollingService(self, didUpdateActivities: activities, reason: reason)

        } catch {
            delegate?.pollingService(self, didEncounterError: error, reason: reason)
        }
    }

    private func updateStateIfNeeded() {
        let timeSinceInteraction = Date().timeIntervalSince(lastUserInteraction)
        if timeSinceInteraction > PollingConfig.idleThreshold && state == .active {
            state = .idle
        }
    }

    private func activateBurstMode() {
        burstIntervals = [1, 1, 2, 2, 3, 3, 3]
        restartPollingLoop()
    }

    private func nextInterval() -> TimeInterval {
        if state != .background, !burstIntervals.isEmpty {
            return burstIntervals.removeFirst()
        }

        switch state {
        case .active:
            return PollingConfig.activeInterval
        case .idle:
            return PollingConfig.idleInterval
        case .background:
            return PollingConfig.backgroundInterval
        case .stopped:
            return .infinity
        }
    }
}
