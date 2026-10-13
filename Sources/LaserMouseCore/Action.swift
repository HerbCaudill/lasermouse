import AppKit

/// What the laser does while its trigger is held.
public enum Action: String, CaseIterable, Sendable {
  case draw
  case rectangle

  /// The action whose trigger is held, preferring the most specific when several are.
  public static func held(by triggers: [Action: Trigger], keys: NSEvent.ModifierFlags, buttons: Trigger) -> Action? {
    allCases
      .filter { triggers[$0]?.isHeld(by: keys, buttons: buttons) == true }
      .max { triggers[$0]!.specificity < triggers[$1]!.specificity }
  }
}
