import AppKit
import Testing

@testable import LaserMouseCore

let allKeys: NSEvent.ModifierFlags = [.control, .option, .command]
let draw: Trigger = [.control, .option, .command, .leftClick]

@Test func triggerIsHeldWhenItsKeysAndButtonAreDown() {
  #expect(draw.isHeld(by: allKeys, buttons: .leftClick))
}

@Test func triggerIsNotHeldWithoutItsButton() {
  #expect(!draw.isHeld(by: allKeys, buttons: []))
  #expect(!draw.isHeld(by: allKeys, buttons: .rightClick))
}

@Test func triggerIsNotHeldWhenAnExtraButtonIsDown() {
  #expect(!draw.isHeld(by: allKeys, buttons: [.leftClick, .rightClick]))
}

@Test func triggerIgnoresTheMouseWhenItHasNoButton() {
  let trigger: Trigger = [.control, .option]
  #expect(trigger.isHeld(by: [.control, .option], buttons: []))
  #expect(trigger.isHeld(by: [.control, .option], buttons: .rightClick))
}

@Test func triggerIsNotHeldWhenAKeyIsMissing() {
  #expect(!draw.isHeld(by: [.control, .option], buttons: .leftClick))
}

@Test func triggerIsNotHeldWhenAnExtraKeyIsDown() {
  let trigger: Trigger = [.control, .option]
  #expect(!trigger.isHeld(by: allKeys, buttons: []))
  #expect(!trigger.isHeld(by: [.control, .option, .shift], buttons: []))
}

@Test func aButtonAloneCanBeTheTrigger() {
  #expect(Trigger.rightClick.isHeld(by: [], buttons: .rightClick))
  #expect(!Trigger.rightClick.isHeld(by: [.command], buttons: .rightClick))
}

@Test func emptyTriggerIsNeverHeld() {
  #expect(!Trigger().isHeld(by: [], buttons: []))
  #expect(!Trigger().isHeld(by: [], buttons: .leftClick))
}

@Test func capsLockAndFunctionDoNotAffectTheMatch() {
  let trigger: Trigger = [.control, .option]
  #expect(trigger.isHeld(by: [.control, .option, .capsLock, .function, .numericPad], buttons: []))
}

@Test func clicksAreCapturedOnceTheKeysAreDownAndBeforeTheClick() {
  #expect(draw.capturesClicks(with: allKeys))
  #expect(Trigger([.option, .rightClick]).capturesClicks(with: .option))
}

@Test func clicksAreNotCapturedWhileTheKeysDoNotMatch() {
  #expect(!draw.capturesClicks(with: [.control, .option]))
  #expect(!draw.capturesClicks(with: [.control, .option, .command, .shift]))
}

@Test func clicksAreNotCapturedWhenTheTriggerHasNoButton() {
  let trigger: Trigger = [.control, .option]
  #expect(!trigger.capturesClicks(with: [.control, .option]))
}

@Test func clicksAreNeverCapturedWhenAButtonIsTheWholeTrigger() {
  #expect(!Trigger.leftClick.capturesClicks(with: []))
}

@Test func heldActionMatchesItsOwnButton() {
  let triggers: [Action: Trigger] = [.draw: draw, .rectangle: [.control, .option, .command, .rightClick]]
  #expect(Action.held(by: triggers, keys: allKeys, buttons: .leftClick) == .draw)
  #expect(Action.held(by: triggers, keys: allKeys, buttons: .rightClick) == .rectangle)
  #expect(Action.held(by: triggers, keys: allKeys, buttons: []) == nil)
}

@Test func theMoreSpecificTriggerWinsWhenBothAreHeld() {
  let triggers: [Action: Trigger] = [.draw: [.control, .option], .rectangle: [.control, .option, .rightClick]]
  #expect(Action.held(by: triggers, keys: [.control, .option], buttons: .rightClick) == .rectangle)
  #expect(Action.held(by: triggers, keys: [.control, .option], buttons: []) == .draw)
}
