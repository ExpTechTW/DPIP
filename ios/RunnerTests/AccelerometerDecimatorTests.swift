import XCTest

@testable import Runner

final class AccelerometerDecimatorTests: XCTestCase {
  /// Three days since boot, so the timestamps are the size a real device sends.
  private let t0 = 259_200_000_000_000.0
  private let millis = 1_000_000.0

  /// Timestamps of a perfectly regular source, in whole nanoseconds so slot
  /// boundaries come out exact.
  private func regular(hertz: Double, count: Int, from start: Double? = nil) -> [Double] {
    let start = start ?? t0
    return (0..<count).map { (start + Double($0) * 1e9 / hertz).rounded() }
  }

  /// What one fresh session keeps of `timestamps`.
  private func admitted(_ timestamps: [Double]) -> [Double] {
    var decimator = AccelerometerDecimator()
    return timestamps.filter { decimator.admit($0) }
  }

  func testKeepsEverySampleOfAnExact50HzSource() {
    let input = regular(hertz: 50, count: 500)
    XCTAssertEqual(admitted(input), input)
  }

  func testKeepsEveryOtherSampleOfA100HzSource() {
    let input = regular(hertz: 100, count: 1000)
    // Every odd sample lands exactly on a slot boundary, which belongs to the
    // later slot, so each odd sample opens its slot and the even one at the
    // slot's centre is dropped. Only the anchor, sample 0, shares nothing.
    let expected = [input[0]] + stride(from: 1, to: input.count, by: 2).map { input[$0] }
    XCTAssertEqual(admitted(input), expected)
  }

  func testKeepsEverySampleOfA50HzSourceWithFiveMillisecondsOfJitter() {
    let jitter: [Double] = [0, 5, -5, 3, -2, 4, -4, 1, -1, 5, -5, -5, 5, 5, 0]
    let input = (0..<600).map { k in
      t0 + Double(k) * 20 * millis + jitter[k % jitter.count] * millis
    }
    XCTAssertEqual(admitted(input), input)
  }

  func testKeepsOnlyTheFirstOfABurstInsideOneSlot() {
    // Slot 0 is [t0 - 10 ms, t0 + 10 ms), slot 1 is [t0 + 10 ms, t0 + 30 ms).
    let input = [0, 1, 9.9, 10, 11, 20, 25, 29.9, 30].map { t0 + $0 * millis }
    let expected = [0, 10, 30].map { t0 + $0 * millis }
    XCTAssertEqual(admitted(input), expected)
  }

  func testResumesAfterALongGap() {
    let before = regular(hertz: 50, count: 50)
    // Ten seconds later, on a phase 13 ms off the anchor's grid.
    let after = regular(hertz: 50, count: 50, from: t0 + 10_013 * millis)
    XCTAssertEqual(admitted(before + after), before + after)
  }

  func testResetStartsANewGrid() {
    var decimator = AccelerometerDecimator()
    XCTAssertTrue(decimator.admit(t0))
    XCTAssertFalse(decimator.admit(t0 + 5 * millis), "same slot as the anchor")

    decimator.reset()
    XCTAssertTrue(decimator.admit(t0 + 5 * millis), "the first sample after a reset")
    // On the old grid t0 + 14 ms is in slot 1 and would be kept; on the grid
    // the new anchor starts it is in slot 0, with the anchor itself.
    XCTAssertFalse(decimator.admit(t0 + 14 * millis))
    XCTAssertTrue(decimator.admit(t0 + 16 * millis))
  }

  func testFasterSourcesNeverExceedOneSamplePerSlotAndAverage50Hz() {
    let seconds = 60.0
    for hertz in [51.0, 60, 120] {
      let input = regular(hertz: hertz, count: Int(hertz * seconds))
      let output = admitted(input)

      let slots = output.map { (($0 - t0) / (20 * millis)).rounded(.toNearestOrAwayFromZero) }
      XCTAssertEqual(Set(slots).count, slots.count, "\(hertz) Hz: two samples in one slot")
      XCTAssertEqual(
        Double(output.count), 50 * seconds, accuracy: 1, "\(hertz) Hz: average rate")
      // One per slot means any 51 consecutive kept samples span more than
      // 49 slots, so no second of sensor time ever holds more than 51.
      for i in 0..<(output.count - 50) {
        XCTAssertGreaterThan(output[i + 50] - output[i], 980 * millis, "\(hertz) Hz at \(i)")
      }
    }
  }
}
