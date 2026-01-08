import 'dart:io';

Future<int?> tcpPing(
    String host, {
      int port = 443,
      Duration timeout = const Duration(seconds: 3),
    }) async {
  final sw = Stopwatch()..start();
  try {
    final socket = await Socket.connect(
      host,
      port,
      timeout: timeout,
    );
    socket.destroy();
    sw.stop();
    return sw.elapsedMilliseconds;
  } catch (_) {
    return null;
  }
}
