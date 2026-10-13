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

  /// Strokes the trail into a grayscale mask, keeping the newest (brightest) opacity wherever segments
  /// overlap, then fills through the mask. Lighten blending makes overlapping round caps harmless, so
  /// joints neither build up into darker beads nor leave seams.
  private func drawTail(in context: CGContext, local: (CGPoint) -> CGPoint) {
    let segments = state.trail.segments
    let width = state.strokeWidth
    let box = segments.reduce(CGRect.null) { box, segment in
      box.union(CGRect(origin: local(segment.from.position), size: .zero))
        .union(CGRect(origin: local(segment.to.position), size: .zero))
    }.insetBy(dx: -width, dy: -width).intersection(bounds).integral
    guard !box.isEmpty else { return }

    let scale = window?.backingScaleFactor ?? 2
    guard let mask = CGContext(
      data: nil, width: Int(box.width * scale), height: Int(box.height * scale), bitsPerComponent: 8,
      bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
    else { return }
    mask.scaleBy(x: scale, y: scale)
    mask.translateBy(x: -box.minX, y: -box.minY)
    mask.setBlendMode(.lighten)
    mask.setLineCap(.round)
    mask.setLineJoin(.round)
    mask.setLineWidth(width)
    for (from, to) in segments {
      mask.setStrokeColor(gray: state.trail.opacity(of: to, at: state.now), alpha: 1)
      mask.move(to: local(from.position))
      mask.addLine(to: local(to.position))
      mask.strokePath()
    }
    guard let image = mask.makeImage() else { return }

    context.saveGState()
    context.clip(to: box, mask: image)
    context.setFillColor(state.color.withAlphaComponent(0.85).cgColor)
    context.fill(box)
    context.restoreGState()
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
