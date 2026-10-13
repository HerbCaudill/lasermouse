import CoreGraphics
import Foundation

/// A position the pointer passed through, stamped with when it was there.
public struct TrailPoint: Equatable, Sendable {
  public var position: CGPoint
  public var time: TimeInterval
  /// Whether this point begins a new mark rather than continuing the previous one.
  public var startsStroke: Bool
}

/// A cubic Bézier for the stretch from `p1` to `p2` of a centripetal Catmull-Rom spline through
/// `p0`...`p3`. Centripetal spacing keeps the curve from overshooting or looping when samples are
/// unevenly spaced, as they are when the pointer speeds up or slows down.
private struct SplineSegment {
  let from: CGPoint
  let control1: CGPoint
  let control2: CGPoint
  let to: CGPoint

  init(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) {
    let a = distance(p0, p1).squareRoot()
    let b = distance(p1, p2).squareRoot()
    let c = distance(p2, p3).squareRoot()
    from = p1
    to = p2
    control1 = a == 0 ? p1 : combine([(a * a, p2), (-b * b, p0), (2 * a * a + 3 * a * b + b * b, p1)], over: 3 * a * (a + b))
    control2 = c == 0 ? p2 : combine([(c * c, p1), (-b * b, p3), (2 * c * c + 3 * c * b + b * b, p2)], over: 3 * c * (c + b))
  }

  /// The length of the control polygon, which the curve is never longer than.
  var maximumLength: Double {
    distance(from, control1) + distance(control1, control2) + distance(control2, to)
  }

  func position(at t: Double) -> CGPoint {
    let u = 1 - t
    return combine([(u * u * u, from), (3 * u * u * t, control1), (3 * u * t * t, control2), (t * t * t, to)], over: 1)
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
  /// How far along the stroke, in points, the line is averaged with itself. 0 is no smoothing.
  public var smoothing: Double = 0
  /// The distance between neighboring points of `lines`.
  public static let spacing = 2.0
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

  /// Each mark as a line of closely and evenly spaced points, oldest first. The line follows a
  /// spline through every sample, so sparse samples from a fast stroke still keep its shape, and
  /// each point fades by when the pointer passed it. Smoothing is applied to this evenly spaced
  /// line rather than to the samples, so it behaves the same however fast the stroke was drawn.
  public var lines: [[TrailPoint]] {
    strokes.filter { $0.count > 1 }.map { smoothed(traced(Array($0))) }
  }

  /// Follows the spline through `stroke`, a point every `spacing` or so. Missing neighbors at the
  /// ends of a mark are mirrored from the inside, so the ends run straight on.
  private func traced(_ stroke: [TrailPoint]) -> [TrailPoint] {
    let positions = stroke.map(\.position)
    return [stroke[0]] + (0..<stroke.count - 1).flatMap { index in
      let p1 = positions[index]
      let p2 = positions[index + 1]
      let p0 = index > 0 ? positions[index - 1] : reflect(p2, through: p1)
      let p3 = index + 2 < positions.count ? positions[index + 2] : reflect(p1, through: p2)
      let segment = SplineSegment(p0, p1, p2, p3)
      let steps = max(1, Int((segment.maximumLength / Self.spacing).rounded(.up)))
      let (start, end) = (stroke[index].time, stroke[index + 1].time)
      return (1...steps).map { step in
        let t = Double(step) / Double(steps)
        return TrailPoint(position: step == steps ? p2 : segment.position(at: t), time: start + (end - start) * t, startsStroke: false)
      }
    }
  }

  /// Averages each point with its neighbors within about `smoothing` along the line, weighting
  /// nearer ones more (two passes of a moving average). The window shrinks toward the ends so it
  /// stays centered, which keeps the first and last points in place: the mark starts where it was
  /// pressed and its tip stays under the pointer.
  private func smoothed(_ line: [TrailPoint]) -> [TrailPoint] {
    let halfWidth = Int((smoothing / Self.spacing / 2).rounded())
    guard halfWidth > 0, line.count > 2 else { return line }
    let positions = averaged(averaged(line.map(\.position), halfWidth: halfWidth), halfWidth: halfWidth)
    return zip(line, positions).map { point, position in
      var point = point
      point.position = position
      return point
    }
  }

  /// A centered moving average of `positions` over `halfWidth` points on each side.
  private func averaged(_ positions: [CGPoint], halfWidth: Int) -> [CGPoint] {
    let sums = positions.reduce(into: [CGPoint.zero]) { sums, position in
      sums.append(CGPoint(x: sums.last!.x + position.x, y: sums.last!.y + position.y))
    }
    return positions.indices.map { index in
      let reach = min(halfWidth, index, positions.count - 1 - index)
      let count = Double(2 * reach + 1)
      let (low, high) = (sums[index - reach], sums[index + reach + 1])
      return CGPoint(x: (high.x - low.x) / count, y: (high.y - low.y) / count)
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
