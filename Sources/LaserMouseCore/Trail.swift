import CoreGraphics
import Foundation

/// A position the pointer passed through, stamped with when it was there.
public struct TrailPoint: Equatable, Sendable {
  public var position: CGPoint
  public var time: TimeInterval
  /// Whether this point begins a new mark rather than continuing the previous one.
  public var startsStroke: Bool
}

/// A quadratic curve along the trail, with the sampled point whose age sets its opacity.
public struct TrailCurve: Sendable {
  public var from: CGPoint
  public var control: CGPoint
  public var to: CGPoint
  public var point: TrailPoint

  static func line(from: CGPoint, to: CGPoint, point: TrailPoint) -> TrailCurve {
    TrailCurve(from: from, control: midpoint(from, to), to: to, point: point)
  }
}

private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
  CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
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

  private var fade: Fade { Fade(duration: fadeDuration, delay: fadeDelay) }

  public var isEmpty: Bool { points.isEmpty }

  /// Records the pointer at `position` at time `time`, unless it hasn't moved since the last point.
  public mutating func add(_ position: CGPoint, at time: TimeInterval) {
    if !isStrokeEnded, points.last?.position == position { return }
    points.append(TrailPoint(position: position, time: time, startsStroke: isStrokeEnded))
    isStrokeEnded = false
  }

  /// Ends the current mark, so the next point added isn't joined to the last one.
  public mutating func endStroke() {
    isStrokeEnded = true
  }

  /// The trail as smooth curves, oldest first. Each sampled point is the control point of a curve
  /// between the midpoints on either side of it, so the line bends through the samples instead of
  /// cornering at them. Each mark starts and ends at its first and last points.
  public var curves: [TrailCurve] {
    strokes.filter { $0.count > 1 }.flatMap { stroke in
      let points = Array(stroke)
      let midpoints = zip(points, points.dropFirst()).map { midpoint($0.position, $1.position) }
      let bends = (1..<points.count - 1).map { index in
        TrailCurve(from: midpoints[index - 1], control: points[index].position, to: midpoints[index], point: points[index])
      }
      return [.line(from: points.first!.position, to: midpoints.first!, point: points.first!)] + bends
        + [.line(from: midpoints.last!, to: points.last!.position, point: points.last!)]
    }
  }

  /// The points split into marks.
  private var strokes: [ArraySlice<TrailPoint>] {
    points.indices.reduce(into: []) { strokes, index in
      if index == 0 || points[index].startsStroke {
        strokes.append(points[index...index])
      } else {
        strokes[strokes.count - 1] = points[strokes[strokes.count - 1].startIndex...index]
      }
    }
  }

  /// Drops points that have fully faded by `time`.
  public mutating func prune(at time: TimeInterval) {
    let fade = fade
    points.removeAll { fade.isOver(age: time - $0.time) }
  }

  /// Returns 1 until a point is `fadeDelay` old, then falls linearly to 0 over `fadeDuration`.
  public func opacity(of point: TrailPoint, at time: TimeInterval) -> Double {
    fade.opacity(age: time - point.time)
  }
}
