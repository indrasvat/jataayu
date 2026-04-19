import Foundation

/// HTTP methods supported by the Jules API
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// API endpoints for the Jules API
public enum Endpoint: Sendable {
    // Sources
    case sources(pageToken: String?)
    case source(id: String)

    // Sessions
    case sessions(pageSize: Int, pageToken: String?)
    case session(id: String)
    case createSession
    case deleteSession(id: String)
    case approvePlan(sessionId: String)
    case sendMessage(sessionId: String)

    // Activities
    case activities(sessionId: String, pageSize: Int, pageToken: String?, createTime: Date?, fields: String?)
    case activity(sessionId: String, activityId: String)

    /// Compact `fields=` mask for `listActivities`. Omits the one
    /// field that explodes response size on sessions with large
    /// changesets: `artifacts.changeSet.gitPatch.unidiffPatch`.
    /// Measured on a real dorikin session: including `unidiffPatch`
    /// → 874 MB / 92 s for 100 activities. Excluding it → 25 KB /
    /// 7 s. Same session, same activities. The diff is fetched
    /// separately via the single-activity `get` endpoint when the
    /// user opens the diff viewer.
    public static let compactActivitiesMask = "activities(name,id,createTime,originator,description,userMessaged,agentMessaged,planGenerated,planApproved,progressUpdated,sessionCompleted,sessionFailed,artifacts(bashOutput(command,output,exitCode),changeSet(source,gitPatch(baseCommitId,suggestedCommitMessage)))),nextPageToken"

    /// The URL path for this endpoint
    public var path: String {
        switch self {
        case .sources(let pageToken):
            var path = "sources"
            if let token = pageToken {
                path += "?pageToken=\(token)"
            }
            return path

        case .source(let id):
            return "sources/\(id)"

        case .sessions(let pageSize, let pageToken):
            var path = "sessions?pageSize=\(pageSize)"
            if let token = pageToken {
                path += "&pageToken=\(token)"
            }
            return path

        case .session(let id):
            return "sessions/\(id)"

        case .createSession:
            return "sessions"

        case .deleteSession(let id):
            return "sessions/\(id)"

        case .approvePlan(let sessionId):
            return "sessions/\(sessionId):approvePlan"

        case .sendMessage(let sessionId):
            return "sessions/\(sessionId):sendMessage"

        case .activities(let sessionId, let pageSize, let pageToken, let createTime, let fields):
            var components = URLComponents()
            components.path = "sessions/\(sessionId)/activities"
            var queryItems = [URLQueryItem(name: "pageSize", value: String(pageSize))]
            if let token = pageToken {
                queryItems.append(URLQueryItem(name: "pageToken", value: token))
            }
            if let createTime {
                queryItems.append(URLQueryItem(name: "createTime", value: Self.activitiesTimestampString(from: createTime)))
            }
            if let fields {
                queryItems.append(URLQueryItem(name: "fields", value: fields))
            }
            components.queryItems = queryItems
            return components.string ?? "sessions/\(sessionId)/activities?pageSize=\(pageSize)"

        case .activity(let sessionId, let activityId):
            return "sessions/\(sessionId)/activities/\(activityId)"
        }
    }

    /// The HTTP method for this endpoint
    public var method: HTTPMethod {
        switch self {
        case .sources, .source, .sessions, .session, .activities, .activity:
            return .get
        case .createSession, .approvePlan, .sendMessage:
            return .post
        case .deleteSession:
            return .delete
        }
    }

    private static func activitiesTimestampString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
