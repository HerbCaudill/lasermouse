import CoreGraphics
import Foundation

/// A position the pointer passed through, stamped with when it was there.
public struct TrailPoint: Equatable, Sendable {
  public var position: CGPoint
  public var time: TimeInterval
  /// Whether this point begins a new mark rather than continuing the previous one.
  public var startsStroke: Bool
}

/// The recent path of the laser, where each point stays fully visible for `fadeDelay` and then fades
/// out over `fadeDuration`.
public struct Trail: Sendable {
  public var fadeDuration: TimeInterval
  public var fadeDelay: TimeInterval
  public private(set) var points: [TrailPoint] = []
  private var isStrokeEnded = true

  public init(fadeDuration: TimeInterval, fadeDelay: TimeInterval = 0) {
    self.fadeDuration = fadeDuration
    self.fadeDelay = fadeDelay
  }

  public var isEmpty: Bool { points.isEmpty }

  /// Records the pointer at `position` at time `time`.
  public mutating func add(_ position: CGPoint, at time: TimeInterval) {
    points.append(TrailPoint(position: position, time: time, startsStroke: isStrokeEnded))
    isStrokeEnded = false
  }

  /// Ends the current mark, so the next point added isn't joined to the last one.
  public mutating func endStroke() {
    isStrokeEnded = true
  }

  /// Pairs of consecutive points within the same mark, oldest first.
  public var segments: [(from: TrailPoint, to: TrailPoint)] {
    zip(points, points.dropFirst()).filter { !$0.1.startsStroke }.map { (from: $0.0, to: $0.1) }
  }

  /// Drops points that have fully faded by `time`.
  public mutating func prune(at time: TimeInterval) {
    points.removeAll { time - $0.time >= fadeDelay + fadeDuration }
  }

  /// Returns 1 until a point is `fadeDelay` old, then falls linearly to 0 over `fadeDuration`.
  public func opacity(of point: TrailPoint, at time: TimeInterval) -> Double {
    guard fadeDuration > 0 else { return 0 }
    let fadeAge = time - point.time - fadeDelay
    return min(1, max(0, 1 - fadeAge / fadeDuration))
  }
}
