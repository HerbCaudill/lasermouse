import CoreGraphics
import Testing

@testable import LaserMouseCore

@Test func draggingStretchesTheRectangleFromWhereItStarted() {
  var rectangles = Rectangles(fadeDuration: 1)
  rectangles.drag(to: CGPoint(x: 1, y: 1))
  rectangles.drag(to: CGPoint(x: 5, y: 3))
  #expect(rectangles.marks.map(\.rect) == [CGRect(x: 1, y: 1, width: 4, height: 2)])
}

@Test func rectangleStaysOpaqueWhileDragging() {
  var rectangles = Rectangles(fadeDuration: 1)
  rectangles.drag(to: .zero)
  rectangles.prune(at: 100)
  #expect(rectangles.opacity(of: rectangles.marks[0], at: 100) == 1)
}

@Test func releasedRectangleFadesAfterTheDelay() {
  var rectangles = Rectangles(fadeDuration: 2, fadeDelay: 1)
  rectangles.drag(to: .zero)
  rectangles.release(at: 10)
  #expect(rectangles.opacity(of: rectangles.marks[0], at: 11) == 1)
  #expect(rectangles.opacity(of: rectangles.marks[0], at: 12) == 0.5)
  rectangles.prune(at: 13)
  #expect(rectangles.isEmpty)
}

@Test func draggingAfterAReleaseStartsANewRectangle() {
  var rectangles = Rectangles(fadeDuration: 1)
  rectangles.drag(to: .zero)
  rectangles.drag(to: CGPoint(x: 2, y: 2))
  rectangles.release(at: 0)
  rectangles.drag(to: CGPoint(x: 5, y: 5))
  rectangles.drag(to: CGPoint(x: 6, y: 6))
  #expect(rectangles.marks.map(\.rect) == [
    CGRect(x: 0, y: 0, width: 2, height: 2), CGRect(x: 5, y: 5, width: 1, height: 1),
  ])
}
