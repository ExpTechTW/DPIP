import Flutter
import Network

/// EventChannel plugin reporting which network the device's traffic currently
/// leaves through, once on listen and again whenever the path changes, so the
/// realtime feeds can replace connections bound to a network that is gone.
///
/// Each event is an identity string: `none` when no path is satisfied,
/// otherwise `<type>:<interface name>` for the preferred interface
/// (`availableInterfaces` is ordered by preference). The Dart side only
/// compares consecutive identities, and drops the repeats `NWPathMonitor`
/// sends when some other property of the same path moves.
///
/// Coarser than Android's network handle: one Wi-Fi network to another keeps
/// `wifi:en0`, and `NWPath` exposes nothing that reliably tells them apart.
/// That case is left to the feeds' silence limit; every change of interface
/// type, and every drop to no network and back, is caught here.
///
/// One system monitor, so a channel rather than a connectivity package.
/// Registered as a real `FlutterPlugin` for the implicit-engine lifecycle.
public class NetworkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var monitor: NWPathMonitor?
  private var sink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterEventChannel(
      name: "com.exptech.dpip/network",
      binaryMessenger: registrar.messenger())
    channel.setStreamHandler(NetworkPlugin())
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events
    let monitor = NWPathMonitor()
    // Delivered on the main queue, where the event sink must be called; a
    // change of path is rare enough that it costs the main thread nothing.
    monitor.pathUpdateHandler = { [weak self] path in
      self?.sink?(NetworkPlugin.identity(of: path))
    }
    monitor.start(queue: .main)
    self.monitor = monitor
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    monitor?.cancel()
    monitor = nil
    sink = nil
    return nil
  }

  static func identity(of path: NWPath) -> String {
    guard path.status == .satisfied, let interface = path.availableInterfaces.first
    else { return "none" }
    let type: String
    switch interface.type {
    case .wifi: type = "wifi"
    case .cellular: type = "cellular"
    case .wiredEthernet: type = "ethernet"
    case .loopback: type = "loopback"
    case .other: type = "other"
    @unknown default: type = "other"
    }
    return "\(type):\(interface.name)"
  }
}
