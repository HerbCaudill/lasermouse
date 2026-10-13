import CoreGraphics
import Testing

@testable import LaserMouseCore

@Test func newPointIsFullyOpaque() {
  var trail = Trail(fadeDuration: 1)
  trail.add(CGPoint(x: 10, y: 20), at: 5)
  #expect(trail.points.count == 1)
  #expect(trail.opacity(of: trail.points[0], at: 5) == 1)
}

@Test func pointFadesLinearlyOverFadeDuration() {
  var trail = Trail(fadeDuration: 2)
  trail.add(.zero, at: 0)
  #expect(trail.opacity(of: trail.points[0], at: 1) == 0.5)
  #expect(trail.opacity(of: trail.points[0], at: 3) == 0)
}

@Test func pruneRemovesOnlyFullyFadedPoints() {
  var trail = Trail(fadeDuration: 1)
  trail.add(CGPoint(x: 1, y: 1), at: 0)
  trail.add(CGPoint(x: 2, y: 2), at: 0.5)
  trail.add(CGPoint(x: 3, y: 3), at: 1.2)
  trail.prune(at: 1.2)
  #expect(trail.points.map(\.position) == [CGPoint(x: 2, y: 2), CGPoint(x: 3, y: 3)])
}

@Test func changingFadeDurationAppliesToExistingPoints() {
  var trail = Trail(fadeDuration: 1)
  trail.add(.zero, at: 0)
  trail.fadeDuration = 4
  #expect(trail.opacity(of: trail.points[0], at: 1) == 0.75)
}

/// Where a curve is at `t` between 0 and 1.
private func position(on curve: TrailCurve, at t: Double) -> CGPoint {
  let u = 1 - t
  let weights = [u * u * u, 3 * u * u * t, 3 * u * t * t, t * t * t]
  let points = [curve.from, curve.control1, curve.control2, curve.to]
  return zip(weights, points).reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.0 * $1.1.x, y: $0.y + $1.0 * $1.1.y) }
}

@Test func curvesPassThroughEverySample() {
  var trail = Trail(fadeDuration: 1)
  let samples = [CGPoint(x: 0, y: 0), CGPoint(x: 4, y: 0), CGPoint(x: 4, y: 4), CGPoint(x: 9, y: 6)]
  for (index, sample) in samples.enumerated() { trail.add(sample, at: Double(index)) }
  #expect(trail.curves.map(\.from) == Array(samples.dropLast()))
  #expect(trail.curves.map(\.to) == Array(samples.dropFirst()))
}

@Test func twoPointsMakeAStraightLine() {
  var trail = Trail(fadeDuration: 1)
  trail.add(CGPoint(x: 0, y: 0), at: 0)
  trail.add(CGPoint(x: 6, y: 0), at: 0.1)
  #expect(trail.curves.count == 1)
  #expect(trail.curves.allSatisfy { $0.control1.y == 0 && $0.control2.y == 0 })
}

@Test func sparseSamplesOnACircleStayOnTheCircle() {
  var trail = Trail(fadeDuration: 1)
  let radius = 500.0
  for index in 0...12 {
    let angle = Double(index) / 12 * 2 * .pi
    trail.add(CGPoint(x: radius * cos(angle), y: radius * sin(angle)), at: Double(index))
  }
  for curve in trail.curves.dropFirst().dropLast() {
    let middle = position(on: curve, at: 0.5)
    #expect(abs(hypot(middle.x, middle.y) - radius) < radius * 0.01)
  }
}

@Test func curvesDoNotJoinSeparateStrokes() {
  var trail = Trail(fadeDuration: 1)
  trail.add(CGPoint(x: 0, y: 0), at: 0)
  trail.add(CGPoint(x: 2, y: 0), at: 0.1)
  trail.endStroke()
  trail.add(CGPoint(x: 10, y: 0), at: 0.2)
  trail.add(CGPoint(x: 12, y: 0), at: 0.3)
  #expect(trail.curves.map { [$0.from, $0.to] } == [
    [CGPoint(x: 0, y: 0), CGPoint(x: 2, y: 0)],
    [CGPoint(x: 10, y: 0), CGPoint(x: 12, y: 0)],
  ])
}

@Test func pointStaysOpaqueThroughTheDelayThenFades() {
  var trail = Trail(fadeDuration: 2, fadeDelay: 1)
  trail.add(.zero, at: 0)
  #expect(trail.opacity(of: trail.points[0], at: 1) == 1)
  #expect(trail.opacity(of: trail.points[0], at: 2) == 0.5)
  #expect(trail.opacity(of: trail.points[0], at: 3) == 0)
}

@Test func pruneKeepsPointsThatAreStillInTheirDelay() {
  var trail = Trail(fadeDuration: 1, fadeDelay: 2)
  trail.add(.zero, at: 0)
  trail.prune(at: 2.5)
  #expect(trail.points.count == 1)
  trail.prune(at: 3)
  #expect(trail.isEmpty)
}

@Test func aPointerThatHasNotMovedAddsNoPoint() {
  var trail = Trail(fadeDuration: 1)
  trail.add(CGPoint(x: 1, y: 1), at: 0)
  trail.add(CGPoint(x: 1, y: 1), at: 0.1)
  #expect(trail.points.count == 1)
}

@Test func theSamePositionAfterAStrokeEndsStartsANewStroke() {
  var trail = Trail(fadeDuration: 1)
  trail.add(CGPoint(x: 1, y: 1), at: 0)
  trail.endStroke()
  trail.add(CGPoint(x: 1, y: 1), at: 0.1)
  #expect(trail.points.count == 2)
}

/// Adds a zigzag stroke and returns the smoothed positions the curves pass through.
private func smoothedZigzag(smoothing: Double) -> [CGPoint] {
  var trail = Trail(fadeDuration: 1)
  trail.smoothing = smoothing
  for x in 0...8 {
    trail.add(CGPoint(x: Double(x) * 4, y: x.isMultiple(of: 2) ? 0 : 4), at: Double(x))
  }
  return trail.curves.dropFirst().map(\.from)
}

@Test func noSmoothingFollowsTheSamplesExactly() {
  #expect(smoothedZigzag(smoothing: 0) == (1...7).map { CGPoint(x: Double($0) * 4, y: $0.isMultiple(of: 2) ? 0 : 4) })
}

@Test func smoothingFlattensWobbles() {
  let wobble = { (points: [CGPoint]) in points.map(\.y).max()! - points.map(\.y).min()! }
  let light = wobble(smoothedZigzag(smoothing: 8))
  let heavy = wobble(smoothedZigzag(smoothing: 30))
  #expect(light < 4)
  #expect(heavy < light)
}

@Test func smoothingKeepsTheEndsOfAStrokeInPlace() {
  var trail = Trail(fadeDuration: 1)
  trail.smoothing = 30
  for x in 0...8 {
    trail.add(CGPoint(x: Double(x) * 4, y: x.isMultiple(of: 2) ? 0 : 4), at: Double(x))
  }
  #expect(trail.curves.first!.from == CGPoint(x: 0, y: 0))
  #expect(trail.curves.last!.to == CGPoint(x: 32, y: 0))
}

@Test func smoothingLeavesAStraightLineStraight() {
  var trail = Trail(fadeDuration: 1)
  trail.smoothing = 30
  for x in 0...8 { trail.add(CGPoint(x: Double(x) * 4, y: 0), at: Double(x)) }
  #expect(trail.curves.allSatisfy { $0.from.y == 0 && $0.control1.y == 0 && $0.control2.y == 0 && $0.to.y == 0 })
}
