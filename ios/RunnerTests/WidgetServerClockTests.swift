import Foundation
import XCTest

final class WidgetServerClockTests: XCTestCase {
    func testStartsUnsynchronized() async {
        let clock = makeClock()

        let hasSynchronized = await clock.hasSynchronized

        XCTAssertFalse(hasSynchronized)
    }

    func testSuccessfulSyncCreatesAnchor() async {
        let monotonic = TestMonotonicClock(milliseconds: 400)
        let clock = makeClock(
            monotonic: monotonic,
            source: ScriptedServerTimeSource(results: [.success(10_000)])
        )

        let succeeded = await clock.synchronize()
        let hasSynchronized = await clock.hasSynchronized
        let calibratedNow = await clock.calibratedNowUnixMilliseconds()

        XCTAssertTrue(succeeded)
        XCTAssertTrue(hasSynchronized)
        XCTAssertEqual(calibratedNow, 10_000)
    }

    func testCalibratedNowAdvancesWithMonotonicElapsedTime() async {
        let monotonic = TestMonotonicClock(milliseconds: 400)
        let clock = makeClock(
            monotonic: monotonic,
            source: ScriptedServerTimeSource(results: [.success(10_000)])
        )
        let synchronized = await clock.synchronize()
        XCTAssertTrue(synchronized)

        monotonic.set(milliseconds: 1_900)
        let calibratedNow = await clock.calibratedNowUnixMilliseconds()

        XCTAssertEqual(calibratedNow, 11_500)
    }

    func testDeviceWallClockJumpDoesNotMoveCalibratedNow() async {
        let wallClock = TestWallClock(milliseconds: 10_000)
        let monotonic = TestMonotonicClock(milliseconds: 400)
        let clock = makeClock(
            wallClock: wallClock,
            monotonic: monotonic,
            source: ScriptedServerTimeSource(results: [.success(20_000)])
        )
        let synchronized = await clock.synchronize()
        XCTAssertTrue(synchronized)
        monotonic.set(milliseconds: 900)
        let beforeJump = await clock.calibratedNowUnixMilliseconds()

        wallClock.set(milliseconds: 9_999_999)
        let afterJump = await clock.calibratedNowUnixMilliseconds()

        XCTAssertEqual(beforeJump, 20_500)
        XCTAssertEqual(afterJump, beforeJump)
    }

    func testFailedLaterSyncPreservesPreviousAnchor() async {
        let monotonic = TestMonotonicClock(milliseconds: 100)
        let source = ScriptedServerTimeSource(
            results: [
                .success(10_000),
                .failure(WidgetSNTPError.allHostsFailed),
            ]
        )
        let clock = makeClock(monotonic: monotonic, source: source)
        let firstSyncSucceeded = await clock.synchronize()
        XCTAssertTrue(firstSyncSucceeded)
        monotonic.set(milliseconds: 600)

        let secondSyncSucceeded = await clock.synchronize()
        let hasSynchronized = await clock.hasSynchronized
        let calibratedNow = await clock.calibratedNowUnixMilliseconds()

        XCTAssertFalse(secondSyncSucceeded)
        XCTAssertTrue(hasSynchronized)
        XCTAssertEqual(calibratedNow, 10_500)
    }

    func testZeroOffsetIsStillSynchronized() async {
        let wallClock = TestWallClock(milliseconds: 10_000)
        let clock = makeClock(
            wallClock: wallClock,
            source: ScriptedServerTimeSource(results: [.success(10_000)])
        )

        let synchronized = await clock.synchronize()
        XCTAssertTrue(synchronized)
        let sample = await clock.currentWeatherSnapshotTime()
        let hasSynchronized = await clock.hasSynchronized

        XCTAssertTrue(hasSynchronized)
        XCTAssertEqual(sample.calibratedTimeOffsetMilliseconds, 0)
    }

    func testSnapshotOffsetIsCalibratedMinusDevice() async {
        let aheadClock = makeClock(
            wallClock: TestWallClock(milliseconds: 15_000),
            source: ScriptedServerTimeSource(results: [.success(10_000)])
        )
        let aheadSynchronized = await aheadClock.synchronize()
        XCTAssertTrue(aheadSynchronized)

        let behindClock = makeClock(
            wallClock: TestWallClock(milliseconds: 5_000),
            source: ScriptedServerTimeSource(results: [.success(10_000)])
        )
        let behindSynchronized = await behindClock.synchronize()
        XCTAssertTrue(behindSynchronized)

        let aheadSample = await aheadClock.currentWeatherSnapshotTime()
        let behindSample = await behindClock.currentWeatherSnapshotTime()
        XCTAssertEqual(aheadSample.calibratedTimeOffsetMilliseconds, -5_000)
        XCTAssertEqual(behindSample.calibratedTimeOffsetMilliseconds, 5_000)
    }

    func testSnapshotTimeUsesOneLogicalClockSample() async {
        let wallClock = TestWallClock(milliseconds: 8_000)
        let monotonic = TestMonotonicClock(milliseconds: 100)
        let clock = makeClock(
            wallClock: wallClock,
            monotonic: monotonic,
            source: ScriptedServerTimeSource(results: [.success(10_000)])
        )
        let synchronized = await clock.synchronize()
        XCTAssertTrue(synchronized)
        monotonic.set(milliseconds: 350)
        wallClock.resetReadCount()
        monotonic.resetReadCount()

        let sample = await clock.currentWeatherSnapshotTime()

        XCTAssertEqual(sample.calibratedNowUnixMilliseconds, 10_250)
        XCTAssertEqual(sample.calibratedTimeOffsetMilliseconds, 2_250)
        XCTAssertEqual(wallClock.readCount, 1)
        XCTAssertEqual(monotonic.readCount, 1)
    }

    func testConcurrentSyncCallsShareUnderlyingWork() async {
        let source = GatedServerTimeSource()
        let clock = makeClock(source: source)

        let first = Task { await clock.synchronize() }
        while await source.callCount == 0 {
            await Task.yield()
        }
        let second = Task { await clock.synchronize() }
        for _ in 0..<20 {
            await Task.yield()
        }

        let callsBeforeCompletion = await source.callCount
        XCTAssertEqual(callsBeforeCompletion, 1)
        await source.succeed(with: 10_000)
        let firstResult = await first.value
        let secondResult = await second.value
        let finalCallCount = await source.callCount
        XCTAssertTrue(firstResult)
        XCTAssertTrue(secondResult)
        XCTAssertEqual(finalCallCount, 1)
    }

    func testOuterTimeoutLeavesClockUnsynchronizedWithoutWaiting() async {
        let source = ScriptedServerTimeSource(results: [.success(10_000)])
        let timeoutRunner = ScriptedTimeoutRunner(
            results: [.failure(WidgetServerClockError.timedOut)]
        )
        let clock = WidgetServerClock(
            deviceClock: TestWallClock(milliseconds: 4_000),
            monotonicClock: TestMonotonicClock(milliseconds: 0),
            serverTimeSource: source,
            timeoutRunner: timeoutRunner
        )

        let succeeded = await clock.synchronize()
        let hasSynchronized = await clock.hasSynchronized
        let callCount = await source.callCount
        let timeouts = await timeoutRunner.timeouts

        XCTAssertFalse(succeeded)
        XCTAssertFalse(hasSynchronized)
        XCTAssertEqual(callCount, 0)
        XCTAssertEqual(timeouts, [8])
    }

    func testOuterTimeoutPreservesExistingAnchor() async {
        let monotonic = TestMonotonicClock(milliseconds: 100)
        let timeoutRunner = ScriptedTimeoutRunner(
            results: [
                .success(10_000),
                .failure(WidgetServerClockError.timedOut),
            ]
        )
        let clock = WidgetServerClock(
            deviceClock: TestWallClock(milliseconds: 4_000),
            monotonicClock: monotonic,
            serverTimeSource:
                ScriptedServerTimeSource(results: [.success(99_999)]),
            timeoutRunner: timeoutRunner
        )
        let firstSucceeded = await clock.synchronize()
        monotonic.set(milliseconds: 600)

        let secondSucceeded = await clock.synchronize()
        let hasSynchronized = await clock.hasSynchronized
        let calibratedNow = await clock.calibratedNowUnixMilliseconds()

        XCTAssertTrue(firstSucceeded)
        XCTAssertFalse(secondSucceeded)
        XCTAssertTrue(hasSynchronized)
        XCTAssertEqual(calibratedNow, 10_500)
    }

    private func makeClock(
        wallClock: TestWallClock = TestWallClock(milliseconds: 1_000),
        monotonic: TestMonotonicClock =
            TestMonotonicClock(milliseconds: 0),
        source: any WidgetServerTimeSource =
            ScriptedServerTimeSource(results: [.success(2_000)])
    ) -> WidgetServerClock {
        WidgetServerClock(
            deviceClock: wallClock,
            monotonicClock: monotonic,
            serverTimeSource: source,
            timeoutRunner: PassthroughServerClockTimeoutRunner()
        )
    }
}

private actor GatedServerTimeSource: WidgetServerTimeSource {
    private(set) var callCount = 0
    private var continuation: CheckedContinuation<Int64, Error>?

    func serverTimeUnixMilliseconds() async throws -> Int64 {
        callCount += 1
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func succeed(with value: Int64) {
        continuation?.resume(returning: value)
        continuation = nil
    }
}

private actor ScriptedTimeoutRunner: WidgetServerClockTimeoutRunning {
    private(set) var timeouts: [TimeInterval] = []
    private var results: [Result<Int64, Error>]

    init(results: [Result<Int64, Error>]) {
        self.results = results
    }

    func serverTimeUnixMilliseconds(
        from source: any WidgetServerTimeSource,
        timeout: TimeInterval
    ) async throws -> Int64 {
        timeouts.append(timeout)
        guard !results.isEmpty else {
            throw WidgetServerClockError.timedOut
        }
        return try results.removeFirst().get()
    }
}
