import Foundation

/// How a mark fades: fully visible for `delay`, then linearly to nothing over `duration`.
public struct Fade: Sendable {
  public var duration: TimeInterval
  public var delay: TimeInterval

  public init(duration: TimeInterval, delay: TimeInterval = 0) {
    self.duration = duration
    self.delay = delay
  }

  public func opacity(age: TimeInterval) -> Double {
    guard duration > 0 else { return 0 }
    return min(1, max(0, 1 - (age - delay) / duration))
  }

  public func isOver(age: TimeInterval) -> Bool {
    age >= delay + duration
  }
}
