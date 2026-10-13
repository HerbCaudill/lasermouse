import CoreGraphics
import Foundation

/// A rectangle dragged from `anchor` to `corner`; `releaseTime` is nil while it's still being dragged.
public struct RectangleMark: Equatable, Sendable {
  public var anchor: CGPoint
  public var corner: CGPoint
  public var releaseTime: TimeInterval?

  public var rect: CGRect {
    CGRect(x: anchor.x, y: anchor.y, width: corner.x - anchor.x, height: corner.y - anchor.y).standardized
  }
}

/// Rectangles the user has dragged out, each fading once released.
public struct Rectangles: Sendable {
  public var fade: Fade
  public private(set) var marks: [RectangleMark] = []

  public init(fadeDuration: TimeInterval, fadeDelay: TimeInterval = 0) {
    fade = Fade(duration: fadeDuration, delay: fadeDelay)
  }

  public var isEmpty: Bool { marks.isEmpty }

  /// Moves the corner of the rectangle being dragged, or starts a new one at `point`.
  public mutating func drag(to point: CGPoint) {
    if let last = marks.indices.last, marks[last].releaseTime == nil {
      marks[last].corner = point
    } else {
      marks.append(RectangleMark(anchor: point, corner: point))
    }
  }

  /// Lets go of the rectangle being dragged, so it starts fading.
  public mutating func release(at time: TimeInterval) {
    if let last = marks.indices.last, marks[last].releaseTime == nil {
      marks[last].releaseTime = time
    }
  }

  /// Drops released rectangles that have fully faded by `time`.
  public mutating func prune(at time: TimeInterval) {
    let fade = fade
    marks.removeAll { mark in mark.releaseTime.map { fade.isOver(age: time - $0) } ?? false }
  }

  public func opacity(of mark: RectangleMark, at time: TimeInterval) -> Double {
    mark.releaseTime.map { fade.opacity(age: time - $0) } ?? 1
  }
}
