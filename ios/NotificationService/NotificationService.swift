import Foundation
import UserNotifications

/// Leaves a delivery breadcrumb for every push, and changes nothing about it.
///
/// iOS runs this only for a push whose `aps` carries `"mutable-content": 1`
/// together with an alert. Without that flag the push is shown exactly as
/// before and this never starts — it is the backend that turns it on, one
/// payload field, and nothing in the app needs to change when it does.
///
/// **The content handed back is always the content received.** An alert in
/// this app is safety information, and an extension that edits, delays or
/// drops one is a way to lose it. So the order is fixed: the write is started
/// on a background queue, and the content goes back as soon as the write
/// finishes or `deliveryDeadline` passes, whichever is first — the write
/// takes milliseconds, the deadline is a ceiling on what a wedged file
/// coordinator can cost. iOS allows about 30 seconds; this uses a fraction of
/// one. If iOS calls `serviceExtensionTimeWillExpire` anyway, the content goes
/// back there, still unchanged.
///
/// The breadcrumb goes into the app group's native log ring, which the app
/// drains into `Log` at launch (`importNativeLogs` in bootstrap) — the same
/// path the widgets already write through.
final class NotificationService: UNNotificationServiceExtension {
    static let deliveryDeadline: TimeInterval = 0.2

    private let lock = NSLock()
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var content: UNNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        let received = Date()
        lock.lock()
        self.contentHandler = contentHandler
        content = request.content
        lock.unlock()

        // Strong captures on purpose. If this object went away before either
        // block ran, the handler would never be called, and iOS would hold the
        // alert for the rest of its budget before showing it — the delay this
        // class exists not to cause. The deadline block runs on time whatever
        // the write does, so nothing is held for longer than that.
        DispatchQueue.global(qos: .userInitiated).asyncAfter(
            deadline: .now() + Self.deliveryDeadline
        ) {
            self.deliver()
        }
        DispatchQueue.global(qos: .utility).async {
            NotificationDeliveryBreadcrumb.record(
                request,
                time: received,
                log: FileNativeLog.appGroup()
            )
            self.deliver()
        }
    }

    override func serviceExtensionTimeWillExpire() {
        deliver()
    }

    /// Hands the original content back exactly once, whoever gets here first.
    private func deliver() {
        lock.lock()
        let handler = contentHandler
        let original = content
        contentHandler = nil
        content = nil
        lock.unlock()
        if let handler, let original {
            handler(original)
        }
    }
}

extension UNNotificationRequest: UNNotificationRequestLike {
    var userInfo: [AnyHashable: Any] { content.userInfo }
    var categoryIdentifier: String { content.categoryIdentifier }
}
