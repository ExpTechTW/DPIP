import Foundation
import Network

protocol WidgetWallTimeSource: Sendable {
    func now() -> Date
}

struct WidgetSystemWallTimeSource: WidgetWallTimeSource {
    func now() -> Date {
        Date()
    }
}

struct WidgetSNTPExchange: Sendable {
    let response: Data
    let clientTransmitTime: Date
    let clientReceiveTime: Date
}

protocol WidgetSNTPHostQuerying: Sendable {
    func query(
        host: String,
        timeout: TimeInterval
    ) async throws -> WidgetSNTPExchange
}

protocol WidgetServerTimeSource: Sendable {
    func serverTimeUnixMilliseconds() async throws -> Int64
}

enum WidgetSNTPError: Error, Equatable {
    case allHostsFailed
    case cancelled
    case connectionFailed
    case invalidResponse
    case timedOut
}

enum WidgetNTPPacket {
    static let length = 48
    static let unixEpochDelta: TimeInterval = 2_208_988_800
    private static let eraSeconds: TimeInterval = 4_294_967_296

    static func request(transmitTime: Date) -> Data {
        var packet = Data(repeating: 0, count: length)
        // Leap indicator 0, NTP version 3, client mode 3.
        packet[0] = 0x1B
        writeTimestamp(
            unixTime: transmitTime.timeIntervalSince1970,
            to: &packet,
            at: 40
        )
        return packet
    }

    static func correctedUnixMilliseconds(
        exchange: WidgetSNTPExchange
    ) throws -> Int64 {
        let response = exchange.response
        guard response.count >= length else {
            throw WidgetSNTPError.invalidResponse
        }

        let firstByte = response[0]
        let leapIndicator = firstByte >> 6
        let version = (firstByte >> 3) & 0x07
        let mode = firstByte & 0x07
        let stratum = response[1]

        guard leapIndicator != 3,
              version == 3 || version == 4,
              mode == 4,
              (1...15).contains(stratum)
        else {
            throw WidgetSNTPError.invalidResponse
        }

        guard !timestampIsZero(in: response, at: 32),
              !timestampIsZero(in: response, at: 40)
        else {
            throw WidgetSNTPError.invalidResponse
        }

        let serverReceiveTime = try unixTime(
            from: response,
            at: 32,
            near: exchange.clientReceiveTime.timeIntervalSince1970
        )
        let serverTransmitTime = try unixTime(
            from: response,
            at: 40,
            near: exchange.clientReceiveTime.timeIntervalSince1970
        )

        guard serverTransmitTime >= serverReceiveTime
        else {
            throw WidgetSNTPError.invalidResponse
        }

        let offset = offsetSeconds(
            clientTransmitTime:
                exchange.clientTransmitTime.timeIntervalSince1970,
            serverReceiveTime: serverReceiveTime,
            serverTransmitTime: serverTransmitTime,
            clientReceiveTime:
                exchange.clientReceiveTime.timeIntervalSince1970
        )
        let correctedTime =
            exchange.clientReceiveTime.timeIntervalSince1970 + offset

        guard correctedTime.isFinite,
              correctedTime >= 0,
              correctedTime <= Double(Int64.max) / 1_000
        else {
            throw WidgetSNTPError.invalidResponse
        }

        return Int64((correctedTime * 1_000).rounded())
    }

    static func offsetSeconds(
        clientTransmitTime: TimeInterval,
        serverReceiveTime: TimeInterval,
        serverTransmitTime: TimeInterval,
        clientReceiveTime: TimeInterval
    ) -> TimeInterval {
        (
            (serverReceiveTime - clientTransmitTime)
                + (serverTransmitTime - clientReceiveTime)
        ) / 2
    }

    static func unixTime(
        from packet: Data,
        at offset: Int,
        near referenceUnixTime: TimeInterval
    ) throws -> TimeInterval {
        guard offset >= 0, packet.count >= offset + 8 else {
            throw WidgetSNTPError.invalidResponse
        }

        let seconds = UInt32(packet[offset]) << 24
            | UInt32(packet[offset + 1]) << 16
            | UInt32(packet[offset + 2]) << 8
            | UInt32(packet[offset + 3])
        let fraction = UInt32(packet[offset + 4]) << 24
            | UInt32(packet[offset + 5]) << 16
            | UInt32(packet[offset + 6]) << 8
            | UInt32(packet[offset + 7])

        let eraZeroUnixTime = TimeInterval(seconds) - unixEpochDelta
        // The wire format carries no era number. Select the era nearest T4,
        // as required to unfold timestamps after the February 2036 rollover.
        let era = (
            (referenceUnixTime - eraZeroUnixTime) / eraSeconds
        ).rounded()
        return eraZeroUnixTime + era * eraSeconds
            + TimeInterval(fraction) / 4_294_967_296
    }

    static func writeTimestamp(
        unixTime: TimeInterval,
        to packet: inout Data,
        at offset: Int
    ) {
        let ntpTime = unixTime + unixEpochDelta
        let wholeSeconds = ntpTime.rounded(.down)
        var eraSeconds = wholeSeconds.truncatingRemainder(
            dividingBy: self.eraSeconds
        )
        if eraSeconds < 0 {
            eraSeconds += self.eraSeconds
        }
        let seconds = UInt32(eraSeconds)
        let fractionalSeconds = ntpTime - wholeSeconds
        let fraction = UInt32(
            (fractionalSeconds * 4_294_967_296).rounded(.down)
        )

        write(seconds, to: &packet, at: offset)
        write(fraction, to: &packet, at: offset + 4)
    }

    private static func write(
        _ value: UInt32,
        to packet: inout Data,
        at offset: Int
    ) {
        packet[offset] = UInt8((value >> 24) & 0xFF)
        packet[offset + 1] = UInt8((value >> 16) & 0xFF)
        packet[offset + 2] = UInt8((value >> 8) & 0xFF)
        packet[offset + 3] = UInt8(value & 0xFF)
    }

    private static func timestampIsZero(
        in packet: Data,
        at offset: Int
    ) -> Bool {
        packet[offset..<(offset + 8)].allSatisfy { $0 == 0 }
    }
}

struct WidgetSNTPClient: WidgetServerTimeSource {
    static let primaryHost = "time.exptech.com.tw"
    static let backupHost = "time.apple.com"

    private let hosts: [String]
    private let hostTimeout: TimeInterval
    private let hostQuery: any WidgetSNTPHostQuerying

    init(
        hosts: [String] = [primaryHost, backupHost],
        hostTimeout: TimeInterval = 3,
        hostQuery: any WidgetSNTPHostQuerying = WidgetNetworkSNTPHostQuery()
    ) {
        self.hosts = hosts
        self.hostTimeout = hostTimeout
        self.hostQuery = hostQuery
    }

    func serverTimeUnixMilliseconds() async throws -> Int64 {
        for host in hosts {
            do {
                let exchange = try await hostQuery.query(
                    host: host,
                    timeout: hostTimeout
                )
                return try WidgetNTPPacket.correctedUnixMilliseconds(
                    exchange: exchange
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch WidgetSNTPError.cancelled {
                throw CancellationError()
            } catch {
                continue
            }
        }
        throw WidgetSNTPError.allHostsFailed
    }
}

struct WidgetNetworkSNTPHostQuery: WidgetSNTPHostQuerying {
    private let wallClock: any WidgetWallTimeSource

    init(
        wallClock: any WidgetWallTimeSource = WidgetSystemWallTimeSource()
    ) {
        self.wallClock = wallClock
    }

    func query(
        host: String,
        timeout: TimeInterval
    ) async throws -> WidgetSNTPExchange {
        try Task.checkCancellation()

        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: 123)!,
            using: .udp
        )
        let context = WidgetSNTPQueryContext()
        let queue = DispatchQueue(
            label: "com.exptech.dpip.widget-sntp.\(UUID().uuidString)"
        )

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                context.install(
                    connection: connection,
                    continuation: continuation
                )

                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        let transmitTime = wallClock.now()
                        let request = WidgetNTPPacket.request(
                            transmitTime: transmitTime
                        )
                        connection.send(
                            content: request,
                            completion: .contentProcessed { error in
                                if error != nil {
                                    context.finish(
                                        .failure(
                                            WidgetSNTPError.connectionFailed
                                        )
                                    )
                                    return
                                }

                                connection.receiveMessage {
                                    data,
                                    _,
                                    _,
                                    error in
                                    let receiveTime = wallClock.now()
                                    guard error == nil, let data else {
                                        context.finish(
                                            .failure(
                                                WidgetSNTPError
                                                    .connectionFailed
                                            )
                                        )
                                        return
                                    }
                                    context.finish(
                                        .success(
                                            WidgetSNTPExchange(
                                                response: data,
                                                clientTransmitTime:
                                                    transmitTime,
                                                clientReceiveTime:
                                                    receiveTime
                                            )
                                        )
                                    )
                                }
                            }
                        )
                    case .failed:
                        context.finish(
                            .failure(WidgetSNTPError.connectionFailed)
                        )
                    case .cancelled:
                        context.finish(
                            .failure(WidgetSNTPError.cancelled)
                        )
                    default:
                        break
                    }
                }

                queue.asyncAfter(deadline: .now() + timeout) {
                    context.finish(.failure(WidgetSNTPError.timedOut))
                }
                connection.start(queue: queue)
            }
        } onCancel: {
            context.finish(.failure(WidgetSNTPError.cancelled))
        }
    }
}

private final class WidgetSNTPQueryContext: @unchecked Sendable {
    private let lock = NSLock()
    private var connection: NWConnection?
    private var continuation:
        CheckedContinuation<WidgetSNTPExchange, Error>?
    private var pendingResult: Result<WidgetSNTPExchange, Error>?

    func install(
        connection: NWConnection,
        continuation: CheckedContinuation<WidgetSNTPExchange, Error>
    ) {
        lock.lock()
        if let pendingResult {
            lock.unlock()
            connection.cancel()
            continuation.resume(with: pendingResult)
            return
        }
        self.connection = connection
        self.continuation = continuation
        lock.unlock()
    }

    func finish(_ result: Result<WidgetSNTPExchange, Error>) {
        lock.lock()
        guard pendingResult == nil else {
            lock.unlock()
            return
        }
        pendingResult = result
        let connection = connection
        let continuation = continuation
        self.connection = nil
        self.continuation = nil
        lock.unlock()

        connection?.cancel()
        continuation?.resume(with: result)
    }
}
