import AppKit
import LaserMouseCore
import ServiceManagement

/// The menu bar icon and its settings menu.
@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
  private let settings: Settings
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  private let menu = NSMenu()

  init(settings: Settings) {
    self.settings = settings
    super.init()
    statusItem.button?.image = NSImage(
      systemSymbolName: "smallcircle.filled.circle", accessibilityDescription: "LaserMouse")
    menu.delegate = self
    statusItem.menu = menu
  }

  /// Rebuilds the menu each time it opens so checkmarks and login state are current.
  func menuNeedsUpdate(_ menu: NSMenu) {
    menu.removeAllItems()

    let isLoginItem = SMAppService.mainApp.status == .enabled
    menu.addItem(choiceItem("Open at login", isOn: isLoginItem) {
      do {
        if isLoginItem {
          try SMAppService.mainApp.unregister()
        } else {
          try SMAppService.mainApp.register()
        }
      } catch {
        NSAlert(error: error).runModal()
      }
    })

    menu.addItem(.separator())
    let triggerItem = NSMenuItem()
    triggerItem.view = TriggerGridView(settings: settings)
    menu.addItem(triggerItem)

    menu.addItem(.separator())
    menu.addItem(
      sliderItem(
        title: "Fade delay", value: settings.fadeDelay, range: Settings.fadeDelayRange,
        format: { String(format: "%.1f s", $0) }
      ) { [weak self] in self?.settings.fadeDelay = $0 })
    menu.addItem(
      sliderItem(
        title: "Fade time", value: settings.fadeDuration, range: Settings.fadeRange,
        format: { String(format: "%.1f s", $0) }
      ) { [weak self] in self?.settings.fadeDuration = $0 })
    menu.addItem(
      sliderItem(
        title: "Dot size", value: settings.dotSize, range: Settings.dotSizeRange,
        format: { String(format: "%.0f pt", $0) }
      ) { [weak self] in self?.settings.dotSize = $0 })

    menu.addItem(.separator())
    menu.addItem(.sectionHeader(title: "Color"))
    for color in LaserColor.allCases {
      let item = choiceItem(color.title, isOn: settings.color == color) { [weak self] in
        self?.settings.color = color
      }
      item.image = swatch(color.nsColor)
      menu.addItem(item)
    }

    menu.addItem(.separator())
    menu.addItem(NSMenuItem(title: "Quit LaserMouse", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
  }

  private func choiceItem(_ title: String, isOn: Bool, action: @escaping () -> Void) -> NSMenuItem {
    let item = ClosureMenuItem(title: title, action: action)
    item.state = isOn ? .on : .off
    return item
  }

  private func sliderItem(
    title: String, value: Double, range: ClosedRange<Double>, format: @escaping (Double) -> String,
    onChange: @escaping (Double) -> Void
  ) -> NSMenuItem {
    let item = NSMenuItem()
    item.view = SliderMenuView(title: title, value: value, range: range, format: format, onChange: onChange)
    return item
  }

  private func swatch(_ color: NSColor) -> NSImage {
    NSImage(size: NSSize(width: 12, height: 12), flipped: false) { rect in
      color.setFill()
      NSBezierPath(ovalIn: rect).fill()
      return true
    }
  }
}

/// A menu item that runs a closure when chosen.
final class ClosureMenuItem: NSMenuItem {
  private let handler: () -> Void

  init(title: String, action handler: @escaping () -> Void) {
    self.handler = handler
    super.init(title: title, action: #selector(run), keyEquivalent: "")
    target = self
  }

  required init(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  @objc private func run() { handler() }
}

/// A labeled slider that lives inside a menu and reports changes as it moves.
final class SliderMenuView: NSView {
  private let valueLabel = NSTextField(labelWithString: "")
  private let format: (Double) -> String
  private let onChange: (Double) -> Void

  init(
    title: String, value: Double, range: ClosedRange<Double>, format: @escaping (Double) -> String,
    onChange: @escaping (Double) -> Void
  ) {
    self.format = format
    self.onChange = onChange
    super.init(frame: NSRect(x: 0, y: 0, width: 240, height: 48))

    let titleLabel = NSTextField(labelWithString: title)
    let slider = NSSlider(value: value, minValue: range.lowerBound, maxValue: range.upperBound, target: self, action: #selector(slide))
    slider.isContinuous = true
    valueLabel.stringValue = format(value)
    valueLabel.textColor = .secondaryLabelColor
    valueLabel.alignment = .right

    for view in [titleLabel, valueLabel, slider] {
      view.translatesAutoresizingMaskIntoConstraints = false
      addSubview(view)
    }
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
      valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
      valueLabel.firstBaselineAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor),
      slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
      slider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
      slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  @objc private func slide(_ sender: NSSlider) {
    valueLabel.stringValue = format(sender.doubleValue)
    onChange(sender.doubleValue)
  }
}
