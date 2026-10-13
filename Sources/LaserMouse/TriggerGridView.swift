import AppKit
import LaserMouseCore

/// A grid of checkboxes inside the menu: one row per action, one column per key or mouse button.
/// Checkboxes in a view don't close the menu, so several can be changed at once.
final class TriggerGridView: NSView {
  private static let parts: [Trigger] = [.control, .option, .command, .leftClick, .rightClick]
  private static let rowTitles: [Action: String] = [.draw: "Draw", .rectangle: "Rectangle"]

  private let settings: Settings

  @MainActor
  init(settings: Settings) {
    self.settings = settings
    super.init(frame: .zero)

    let header: [NSView] = [NSView()] + [headerLabel("⌃"), headerLabel("⌥"), headerLabel("⌘")]
      + [headerImage(MouseIcon.image(button: .left), "Left mouse button")]
      + [headerImage(MouseIcon.image(button: .right), "Right mouse button")]
    let rows = Action.allCases.enumerated().map { row, action in
      let trigger = settings.trigger(for: action)
      let boxes = Self.parts.enumerated().map { column, part in
        let box = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggle))
        box.state = trigger.contains(part) ? .on : .off
        box.tag = row * Self.parts.count + column
        return box
      }
      return [NSTextField(labelWithString: Self.rowTitles[action]!)] + boxes
    }

    let grid = NSGridView(views: [header] + rows)
    grid.rowSpacing = 6
    grid.columnSpacing = 10
    for column in 1..<grid.numberOfColumns {
      grid.column(at: column).xPlacement = .center
    }
    grid.translatesAutoresizingMaskIntoConstraints = false
    addSubview(grid)
    NSLayoutConstraint.activate([
      grid.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
      grid.topAnchor.constraint(equalTo: topAnchor, constant: 4),
    ])
    let size = grid.fittingSize
    frame = NSRect(x: 0, y: 0, width: max(240, size.width + 28), height: size.height + 10)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  @MainActor @objc private func toggle(_ sender: NSButton) {
    let action = Action.allCases[sender.tag / Self.parts.count]
    let part = Self.parts[sender.tag % Self.parts.count]
    var trigger = settings.trigger(for: action)
    if sender.state == .on { trigger.insert(part) } else { trigger.remove(part) }
    settings.setTrigger(trigger, for: action)
  }

  private func headerLabel(_ symbol: String) -> NSView {
    let label = NSTextField(labelWithString: symbol)
    label.textColor = .secondaryLabelColor
    return label
  }

  private func headerImage(_ image: NSImage, _ description: String) -> NSView {
    image.accessibilityDescription = description
    let view = NSImageView(image: image)
    view.imageScaling = .scaleNone
    view.contentTintColor = .secondaryLabelColor
    view.toolTip = description
    return view
  }
}

/// A small mouse outline with one button filled, since Unicode has no left- or right-click symbol.
enum MouseIcon {
  enum Button { case left, right }

  static func image(button: Button) -> NSImage {
    let image = NSImage(size: NSSize(width: 12, height: 17), flipped: true) { _ in
      let body = NSRect(x: 0.6, y: 0.6, width: 10.8, height: 15.8)
      let outline = NSBezierPath(roundedRect: body, xRadius: 5.4, yRadius: 5.4)
      NSColor.black.set()
      NSGraphicsContext.saveGraphicsState()
      outline.addClip()
      let split = body.minY + body.height * 0.42
      let half = NSRect(
        x: button == .left ? body.minX : body.midX, y: body.minY, width: body.width / 2, height: split - body.minY)
      half.fill()
      NSGraphicsContext.restoreGraphicsState()
      let lines = NSBezierPath()
      lines.move(to: NSPoint(x: body.minX, y: split))
      lines.line(to: NSPoint(x: body.maxX, y: split))
      lines.move(to: NSPoint(x: body.midX, y: body.minY))
      lines.line(to: NSPoint(x: body.midX, y: split))
      for path in [outline, lines] {
        path.lineWidth = 1.2
        path.stroke()
      }
      return true
    }
    image.isTemplate = true
    return image
  }
}
