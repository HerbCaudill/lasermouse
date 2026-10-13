import CoreGraphics
import Foundation

/// A position the pointer passed through, stamped with when it was there.
public struct TrailPoint: Equatable, Sendable {
  public var position: CGPoint
  public var time: TimeInterval
}

/// The recent path of the laser, where each point fades out over `fadeDuration`.
public struct Trail: Sendable {
  public var fadeDuration: TimeInterval
  public private(set) var points: [TrailPoint] = []

  public init(fadeDuration: TimeInterval) {
    self.fadeDuration = fadeDuration
  }

  public var isEmpty: Bool { points.isEmpty }

  /// Records the pointer at `position` at time `time`.
  public mutating func add(_ position: CGPoint, at time: TimeInterval) {
    points.append(TrailPoint(position: position, time: time))
  }

  /// Drops points that have fully faded by `time`.
  public mutating func prune(at time: TimeInterval) {
    points.removeAll { time - $0.time >= fadeDuration }
  }

  /// Returns 1 for a brand-new point, falling linearly to 0 once it is `fadeDuration` old.
  public func opacity(of point: TrailPoint, at time: TimeInterval) -> Double {
    guard fadeDuration > 0 else { return 0 }
    let age = time - point.time
    return min(1, max(0, 1 - age / fadeDuration))
  }
}
