import Foundation

public struct ResponseDecodingDiagnostic: Error, LocalizedError, Sendable {
    public struct ActivitySample: Sendable {
        public let id: String
        public let createTime: String?
    }

    public let endpointPath: String
    public let statusCode: Int
    public let responseSize: Int
    public let topLevelKeys: [String]
    public let activitySamples: [ActivitySample]
    public let underlyingDescription: String

    public var errorDescription: String? {
        var parts: [String] = [
            "Failed to decode response for \(endpointPath)",
            "HTTP \(statusCode)",
            "\(responseSize) bytes"
        ]

        if !topLevelKeys.isEmpty {
            parts.append("keys: \(topLevelKeys.joined(separator: ", "))")
        }

        if !activitySamples.isEmpty {
            let samples = activitySamples
                .map { "\($0.id)@\($0.createTime ?? "unknown")" }
                .joined(separator: ", ")
            parts.append("activity samples: \(samples)")
        }

        parts.append("underlying: \(underlyingDescription)")
        return parts.joined(separator: " | ")
    }
}

/// Errors that can occur during network operations with the Jules API
public enum NetworkError: Error, LocalizedError, Sendable {
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case serverError(Int)
    case invalidResponse
    case apiError(String)
    case unknown(Int)
    case noAPIKey
    case encodingFailed
    case decodingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Invalid API key. Please check your credentials."
        case .forbidden:
            return "Access denied. You don't have permission for this action."
        case .notFound:
            return "Resource not found."
        case .rateLimited:
            return "You've reached your usage limit. Please try again later or upgrade your plan."
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        case .invalidResponse:
            return "Invalid response from server."
        case .apiError(let message):
            return message
        case .unknown(let code):
            return "Unknown error (\(code))."
        case .noAPIKey:
            return "No API key configured. Please add your Jules API key."
        case .encodingFailed:
            return "Failed to encode request."
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }

    public var isRetryable: Bool {
        switch self {
        case .serverError, .unknown:
            return true
        case .rateLimited:
            return true // With backoff
        default:
            return false
        }
    }
}

/// API error response structure from Jules API
public struct APIErrorResponse: Codable, Sendable {
    public let error: APIError

    public struct APIError: Codable, Sendable {
        public let code: Int
        public let message: String
        public let status: String?
    }
}
