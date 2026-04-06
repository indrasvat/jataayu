import SwiftUI

/// Root view that handles authentication state and main navigation
struct RootView: View {
    @EnvironmentObject private var dependencies: AppDependency
    @Environment(\.scenePhase) private var scenePhase
    @State private var coordinator = AppCoordinator()

    var body: some View {
        Group {
            if dependencies.isAuthenticated {
                MainTabView()
                    .environment(coordinator)
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: dependencies.isAuthenticated)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                dependencies.pollingService.enterForeground()
            case .background:
                dependencies.pollingService.enterBackground()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}

/// Main tab bar view for authenticated users
struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard
        case sessions
        case settings

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .sessions: return "Sessions"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .sessions: return "bubble.left.and.bubble.right"
            case .settings: return "gear"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(Tab.dashboard.title, systemImage: Tab.dashboard.icon)
                }
                .tag(Tab.dashboard)
                .accessibilityIdentifier("tab.dashboard")

            SessionsListView()
                .tabItem {
                    Label(Tab.sessions.title, systemImage: Tab.sessions.icon)
                }
                .tag(Tab.sessions)
                .accessibilityIdentifier("tab.sessions")

            SettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
                .accessibilityIdentifier("tab.settings")
        }
        .tint(.joolsAccent)
    }
}

#Preview {
    RootView()
        .environmentObject(AppDependency())
}
