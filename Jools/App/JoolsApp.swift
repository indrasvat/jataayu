import SwiftUI
import SwiftData

/// Main entry point for the Jools iOS app
@main
struct JoolsApp: App {
    @StateObject private var dependencies = AppDependency()
    @StateObject private var themeSettings = ThemeSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dependencies)
                .environmentObject(themeSettings)
                .modelContainer(dependencies.modelContainer)
                .preferredColorScheme(themeSettings.preferredColorScheme)
        }
    }
}
