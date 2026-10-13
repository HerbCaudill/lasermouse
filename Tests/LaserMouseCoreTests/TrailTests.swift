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

/// A curve's start, control and end points, for comparing in tests.
private func shape(_ curve: TrailCurve) -> [CGPoint] { [curve.from, curve.control, curve.to] }

@Test func twoPointsMakeAStraightLine() {
  var trail = Trail(fadeDuration: 1)
  trail.add(CGPoint(x: 0, y: 0), at: 0)
  trail.add(CGPoint(x: 4, y: 0), at: 0.1)
  #expect(trail.curves.map(shape) == [
    [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 2, y: 0)],
    [CGPoint(x: 2, y: 0), CGPoint(x: 3, y: 0), CGPoint(x: 4, y: 0)],
  ])
}

@Test func cornersAreRoundedThroughTheMidpoints() {
  var trail = Trail(fadeDuration: 1)
  trail.add(CGPoint(x: 0, y: 0), at: 0)
  trail.add(CGPoint(x: 4, y: 0), at: 0.1)
  trail.add(CGPoint(x: 4, y: 4), at: 0.2)
  #expect(trail.curves.map(shape) == [
    [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 2, y: 0)],
    [CGPoint(x: 2, y: 0), CGPoint(x: 4, y: 0), CGPoint(x: 4, y: 2)],
    [CGPoint(x: 4, y: 2), CGPoint(x: 4, y: 3), CGPoint(x: 4, y: 4)],
  ])
}

@Test func curvesDoNotJoinSeparateStrokes() {
  var trail = Trail(fadeDuration: 1)
  trail.add(CGPoint(x: 0, y: 0), at: 0)
  trail.add(CGPoint(x: 2, y: 0), at: 0.1)
  trail.endStroke()
  trail.add(CGPoint(x: 10, y: 0), at: 0.2)
  trail.add(CGPoint(x: 12, y: 0), at: 0.3)
  #expect(trail.curves.map(shape) == [
    [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0)],
    [CGPoint(x: 1, y: 0), CGPoint(x: 1.5, y: 0), CGPoint(x: 2, y: 0)],
    [CGPoint(x: 10, y: 0), CGPoint(x: 10.5, y: 0), CGPoint(x: 11, y: 0)],
    [CGPoint(x: 11, y: 0), CGPoint(x: 11.5, y: 0), CGPoint(x: 12, y: 0)],
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
