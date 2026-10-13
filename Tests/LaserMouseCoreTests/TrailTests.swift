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

/// Adds `samples` to a new trail as one stroke.
private func trail(_ samples: [CGPoint], smoothing: Double = 0) -> Trail {
  var trail = Trail(fadeDuration: 1)
  trail.smoothing = smoothing
  for (index, sample) in samples.enumerated() { trail.add(sample, at: Double(index)) }
  return trail
}

/// Samples on a circle of `radius` around the origin, unevenly spaced like a fast hand-drawn stroke.
private func sparseCircle(radius: Double) -> [CGPoint] {
  var angle = 0.0
  return (0..<28).map { index in
    defer { angle += 2 * .pi / 30 * (1 + 0.35 * sin(Double(index) * 2.3)) }
    return CGPoint(x: radius * cos(angle), y: radius * sin(angle))
  }
}

@Test func linesPassThroughEverySample() {
  let samples = [CGPoint(x: 0, y: 0), CGPoint(x: 40, y: 0), CGPoint(x: 40, y: 40), CGPoint(x: 90, y: 60)]
  let positions = trail(samples).lines[0].map(\.position)
  #expect(samples.allSatisfy(positions.contains))
}

@Test func linesAreEvenlyAndDenselySpaced() {
  let line = trail(sparseCircle(radius: 300)).lines[0]
  let gaps = zip(line, line.dropFirst()).map { hypot($1.position.x - $0.position.x, $1.position.y - $0.position.y) }
  #expect(gaps.max()! <= Trail.spacing * 1.5)
}

@Test func twoPointsMakeAStraightLine() {
  let line = trail([CGPoint(x: 0, y: 0), CGPoint(x: 60, y: 0)]).lines[0]
  #expect(line.allSatisfy { $0.position.y == 0 })
}

@Test func sparseSamplesOnACircleStayOnTheCircle() {
  let radius = 300.0
  let line = trail(sparseCircle(radius: radius)).lines[0]
  #expect(line.allSatisfy { abs(hypot($0.position.x, $0.position.y) - radius) < radius * 0.01 })
}

@Test func smoothingASparseCircleKeepsItRound() {
  let radius = 300.0
  let line = trail(sparseCircle(radius: radius), smoothing: 94).lines[0]
  // Away from the ends, where the smoothing window is at full width.
  let distances = line.dropFirst(60).dropLast(60).map { hypot($0.position.x, $0.position.y) }
  #expect(distances.max()! - distances.min()! < radius * 0.01)
}

@Test func linesDoNotJoinSeparateStrokes() {
  var trail = Trail(fadeDuration: 1)
  trail.add(CGPoint(x: 0, y: 0), at: 0)
  trail.add(CGPoint(x: 20, y: 0), at: 0.1)
  trail.endStroke()
  trail.add(CGPoint(x: 100, y: 0), at: 0.2)
  trail.add(CGPoint(x: 120, y: 0), at: 0.3)
  #expect(trail.lines.map { [$0.first!.position, $0.last!.position] } == [
    [CGPoint(x: 0, y: 0), CGPoint(x: 20, y: 0)],
    [CGPoint(x: 100, y: 0), CGPoint(x: 120, y: 0)],
  ])
}

@Test func pointsAlongALineFadeByWhenThePointerPassedThem() {
  var trail = Trail(fadeDuration: 1)
  trail.add(CGPoint(x: 0, y: 0), at: 0)
  trail.add(CGPoint(x: 20, y: 0), at: 1)
  let middle = trail.lines[0].first { $0.position.x == 10 }!
  #expect(middle.time == 0.5)
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

/// A zigzag stroke, smoothed.
private func zigzag(smoothing: Double) -> [CGPoint] {
  trail((0...8).map { CGPoint(x: Double($0) * 40, y: $0.isMultiple(of: 2) ? 0 : 40) }, smoothing: smoothing).lines[0].map(\.position)
}

@Test func smoothingFlattensWobbles() {
  // Compare the middle of the stroke, away from the pinned ends.
  let wobble = { (points: [CGPoint]) in
    let middle = points.filter { $0.x > 100 && $0.x < 220 }.map(\.y)
    return middle.max()! - middle.min()!
  }
  let none = wobble(zigzag(smoothing: 0))
  let light = wobble(zigzag(smoothing: 40))
  let heavy = wobble(zigzag(smoothing: 100))
  #expect(light < none)
  #expect(heavy < light)
}

@Test func smoothingKeepsTheEndsOfAStrokeInPlace() {
  let line = zigzag(smoothing: 100)
  #expect(line.first == CGPoint(x: 0, y: 0))
  #expect(line.last == CGPoint(x: 320, y: 0))
}

@Test func smoothingLeavesAStraightLineStraight() {
  let line = trail((0...8).map { CGPoint(x: Double($0) * 40, y: 0) }, smoothing: 100).lines[0]
  #expect(line.allSatisfy { abs($0.position.y) < 1e-9 })
}
