import Foundation

/// One line saying a push reached this device, written where the app will
/// read it on its next launch.
///
/// The question this answers is the one a missing alert raises first: did
/// APNs deliver it at all? Without it the app only ever learns about pushes
/// the user tapped, so "it never arrived" and "it arrived and was swiped
/// away" look the same.
///
/// The line carries identifiers only — the alert's id, its channel, and the
/// APNs request id. Never the title or body: those name places, and this ends
/// up in a log the user may share.
enum NotificationDeliveryBreadcrumb {
    static let tag = "push"
    static let maxFieldLength = 64

    /// The log line for a push whose payload is `userInfo`.
    ///
    /// The server publishes straight to APNs with the alert's fields in a
    /// `content` object (sometimes as a JSON string — see
    /// `NotificationTap.fromData` on the Dart side, which reads the same
    /// shapes), with the producer's own map in `payload` beside it. Each field
    /// is looked for in those places, nearest first, and left out when absent.
    static func message(
        userInfo: [AnyHashable: Any],
        requestIdentifier: String,
        categoryIdentifier: String
    ) -> String {
        let content = object(userInfo["content"])
        let payload = object(content["payload"] ?? userInfo["payload"])
        let id = text(payload["id"] ?? content["id"] ?? userInfo["id"])
        let channel = text(
            content["channelKey"] ?? payload["channel"] ?? userInfo["channel"]
        )
        var parts = ["delivered"]
        if let id { parts.append("id=\(id)") }
        if let channel { parts.append("channel=\(channel)") }
        if let category = text(categoryIdentifier) {
            parts.append("category=\(category)")
        }
        if let request = text(requestIdentifier) {
            parts.append("apns=\(request)")
        }
        return parts.joined(separator: " ")
    }

    /// Records the breadcrumb for a push received at `time`.
    static func record(
        _ request: UNNotificationRequestLike,
        time: Date,
        log: NativeLog?
    ) {
        log?.record(
            level: .info,
            tag: tag,
            message: message(
                userInfo: request.userInfo,
                requestIdentifier: request.identifier,
                categoryIdentifier: request.categoryIdentifier
            ),
            time: time
        )
    }

    private static func object(_ raw: Any?) -> [String: Any] {
        if let dictionary = raw as? [String: Any] { return dictionary }
        guard
            let string = raw as? String,
            let data = string.data(using: .utf8),
            let decoded = try? JSONSerialization.jsonObject(with: data),
            let dictionary = decoded as? [String: Any]
        else {
            return [:]
        }
        return dictionary
    }

    /// A field as a short single token, or nil when there is nothing to say.
    /// Whitespace is collapsed so one value cannot pose as two fields.
    private static func text(_ raw: Any?) -> String? {
        let value: String
        switch raw {
        case let string as String: value = string
        case let number as NSNumber: value = number.stringValue
        default: return nil
        }
        let token = value.split(whereSeparator: { $0.isWhitespace }).joined(separator: "_")
        guard !token.isEmpty else { return nil }
        return String(token.prefix(maxFieldLength))
    }
}

/// The three things the breadcrumb reads off a `UNNotificationRequest`, so a
/// test can hand it a payload without constructing one.
protocol UNNotificationRequestLike {
    var identifier: String { get }
    var userInfo: [AnyHashable: Any] { get }
    var categoryIdentifier: String { get }
}
