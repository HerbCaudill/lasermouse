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
