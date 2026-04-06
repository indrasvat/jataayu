import SwiftUI

enum AppColorScheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var swiftUIColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

@MainActor
final class ThemeSettings: ObservableObject {
    private static let storageKey = "colorScheme"

    @Published private(set) var colorScheme: AppColorScheme

    private let overrideColorScheme: AppColorScheme?

    init(defaults: UserDefaults = .standard, processInfo: ProcessInfo = .processInfo) {
        let environment = processInfo.environment
        self.overrideColorScheme = environment["JOOLS_UI_TEST_COLOR_SCHEME"].flatMap(AppColorScheme.init(rawValue:))

        let storedValue = defaults.string(forKey: Self.storageKey)
        let storedScheme = storedValue.flatMap(AppColorScheme.init(rawValue:)) ?? .system
        self.colorScheme = overrideColorScheme ?? storedScheme
    }

    var preferredColorScheme: ColorScheme? {
        colorScheme.swiftUIColorScheme
    }

    var isOverriddenForTesting: Bool {
        overrideColorScheme != nil
    }

    func update(_ scheme: AppColorScheme, defaults: UserDefaults = .standard) {
        defaults.set(scheme.rawValue, forKey: Self.storageKey)
        guard overrideColorScheme == nil else { return }
        colorScheme = scheme
    }
}
