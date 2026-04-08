import Foundation

enum BuildInfo {
    static let gitSHA = bundleValue(for: "JOOLS_GIT_SHA")
    static let gitBranch = bundleValue(for: "JOOLS_GIT_BRANCH")
    static let buildDate = bundleValue(for: "JOOLS_BUILD_DATE")
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    static var fullVersion: String {
        "\(version) (\(build))"
    }

    static var debugDescription: String {
        "\(fullVersion) • \(gitSHA) • \(gitBranch)"
    }

    private static func bundleValue(for key: String) -> String {
        Bundle.main.infoDictionary?[key] as? String ?? "unknown"
    }
}
