import AppKit
import LaserMouseCore

/// What every overlay draws on a given frame, in global screen coordinates.
@MainActor
final class LaserState {
  var trail = Trail(fadeDuration: 3)
  var rectangles = Rectangles(fadeDuration: 3)
  var head: CGPoint?
  var now: TimeInterval = 0
  var color = LaserColor.red.nsColor
  var strokeWidth: CGFloat = 12
}

/// Draws the part of the laser that falls on one screen.
final class LaserView: NSView {
  private let state: LaserState

  init(state: LaserState) {
    self.state = state
    super.init(frame: .zero)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  override func draw(_ dirtyRect: NSRect) {
    guard let context = NSGraphicsContext.current?.cgContext, let origin = window?.frame.origin else { return }
    let local = { (point: CGPoint) in CGPoint(x: point.x - origin.x, y: point.y - origin.y) }
    drawRectangles(in: context, local: local)
    drawTail(in: context, local: local)
    if let head = state.head { drawDot(at: local(head), in: context) }
  }

  private func drawTail(in context: CGContext, local: (CGPoint) -> CGPoint) {
    let segments = state.trail.segments
    guard !segments.isEmpty else { return }
    // Copy blending inside a transparency layer lets newer segments replace older ones where their
    // round caps overlap, so the joints don't build up into darker beads.
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    context.setBlendMode(.copy)
    context.setLineCap(.round)
    for (from, to) in segments {
      let opacity = state.trail.opacity(of: to, at: state.now)
      context.setStrokeColor(state.color.withAlphaComponent(0.85 * opacity).cgColor)
      context.setLineWidth(state.strokeWidth)
      context.move(to: local(from.position))
      context.addLine(to: local(to.position))
      context.strokePath()
    }
    context.endTransparencyLayer()
  }

  private func drawRectangles(in context: CGContext, local: (CGPoint) -> CGPoint) {
    context.setLineJoin(.round)
    context.setLineWidth(state.strokeWidth)
    for mark in state.rectangles.marks {
      let opacity = state.rectangles.opacity(of: mark, at: state.now)
      let origin = local(mark.rect.origin)
      let rect = CGRect(origin: origin, size: mark.rect.size)
      context.setStrokeColor(state.color.withAlphaComponent(0.85 * opacity).cgColor)
      context.stroke(rect)
    }
  }

  private func drawDot(at center: CGPoint, in context: CGContext) {
    let size = state.strokeWidth
    fillCircle(at: center, radius: size, color: state.color.withAlphaComponent(0.2), in: context)
    fillCircle(at: center, radius: size / 2, color: state.color, in: context)
    fillCircle(at: center, radius: size / 5, color: NSColor.white.withAlphaComponent(0.75), in: context)
  }

  private func fillCircle(at center: CGPoint, radius: CGFloat, color: NSColor, in context: CGContext) {
    context.setFillColor(color.cgColor)
    context.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
  }
}
