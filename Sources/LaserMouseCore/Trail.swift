import CoreGraphics
import Foundation

/// A position the pointer passed through, stamped with when it was there.
public struct TrailPoint: Equatable, Sendable {
  public var position: CGPoint
  public var time: TimeInterval
  /// Whether this point begins a new mark rather than continuing the previous one.
  public var startsStroke: Bool
}

/// A cubic curve between two neighboring samples, with the newer sample, whose age sets its opacity.
public struct TrailCurve: Sendable {
  public var from: CGPoint
  public var control1: CGPoint
  public var control2: CGPoint
  public var to: CGPoint
  public var point: TrailPoint

  /// The curve from `p1` to `p2` of a centripetal Catmull-Rom spline through `p0`...`p3`, as a
  /// Bézier. Centripetal spacing keeps the curve from overshooting or looping when samples are
  /// unevenly spaced, as they are when the pointer speeds up or slows down.
  init(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, point: TrailPoint) {
    let a = distance(p0, p1).squareRoot()
    let b = distance(p1, p2).squareRoot()
    let c = distance(p2, p3).squareRoot()
    from = p1
    to = p2
    control1 = a == 0 ? p1 : combine([(a * a, p2), (-b * b, p0), (2 * a * a + 3 * a * b + b * b, p1)], over: 3 * a * (a + b))
    control2 = c == 0 ? p2 : combine([(c * c, p1), (-b * b, p3), (2 * c * c + 3 * c * b + b * b, p2)], over: 3 * c * (c + b))
    self.point = point
  }
}

private func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
  hypot(b.x - a.x, b.y - a.y)
}

private func combine(_ terms: [(Double, CGPoint)], over divisor: Double) -> CGPoint {
  let sum = terms.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.0 * $1.1.x, y: $0.y + $1.0 * $1.1.y) }
  return CGPoint(x: sum.x / divisor, y: sum.y / divisor)
}

/// `point` reflected through `center`.
private func reflect(_ point: CGPoint, through center: CGPoint) -> CGPoint {
  CGPoint(x: 2 * center.x - point.x, y: 2 * center.y - point.y)
}

/// The recent path of the laser, where each point stays fully visible for `fadeDelay` and then fades
/// out over `fadeDuration`.
public struct Trail: Sendable {
  public var fadeDuration: TimeInterval
  public var fadeDelay: TimeInterval
  /// How far along the stroke, in points, each sample is averaged with its neighbors. 0 is no smoothing.
  public var smoothing: Double = 0
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

  /// The trail as smooth curves, oldest first, passing through every sample. Sparse samples from a
  /// fast stroke still follow its shape, rather than being joined by straight lines. Missing
  /// neighbors at the ends of a mark are mirrored from the inside, so the ends run straight on.
  public var curves: [TrailCurve] {
    strokes.filter { $0.count > 1 }.flatMap { stroke in
      let points = smoothed(Array(stroke))
      let positions = points.map(\.position)
      return (0..<points.count - 1).map { index in
        let p1 = positions[index]
        let p2 = positions[index + 1]
        let p0 = index > 0 ? positions[index - 1] : reflect(p2, through: p1)
        let p3 = index + 2 < positions.count ? positions[index + 2] : reflect(p1, through: p2)
        return TrailCurve(p0, p1, p2, p3, point: points[index + 1])
      }
    }
  }

  /// Moves each point to a weighted average of its neighbors within `smoothing` along the stroke.
  /// The window shrinks toward the ends so it stays centered, which keeps the first and last points
  /// in place: the stroke starts where it was pressed and its tip stays under the pointer.
  private func smoothed(_ stroke: [TrailPoint]) -> [TrailPoint] {
    guard smoothing > 0, stroke.count > 2 else { return stroke }
    let distances = zip(stroke, stroke.dropFirst()).reduce(into: [0.0]) { distances, pair in
      distances.append(distances.last! + hypot(pair.1.position.x - pair.0.position.x, pair.1.position.y - pair.0.position.y))
    }
    let length = distances.last!
    return stroke.indices.map { index in
      let radius = min(smoothing, distances[index], length - distances[index])
      guard radius > 0 else { return stroke[index] }
      var sum = CGPoint.zero
      var totalWeight = 0.0
      var first = index
      while first > 0, distances[index] - distances[first - 1] < radius { first -= 1 }
      var last = index
      while last < stroke.count - 1, distances[last + 1] - distances[index] < radius { last += 1 }
      for neighbor in first...last {
        let weight = 1 - abs(distances[neighbor] - distances[index]) / radius
        sum.x += stroke[neighbor].position.x * weight
        sum.y += stroke[neighbor].position.y * weight
        totalWeight += weight
      }
      var point = stroke[index]
      point.position = CGPoint(x: sum.x / totalWeight, y: sum.y / totalWeight)
      return point
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
