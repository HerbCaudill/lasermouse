import AppKit
import Testing

@testable import LaserMouseCore

@Test func triggerIsHeldWhenItsKeysAreDownAndTheMouseIsPressed() {
  #expect(Trigger.all.isHeld(by: [.control, .option, .command], mouseDown: true))
}

@Test func triggerIsNotHeldWithoutAClickWhenItRequiresOne() {
  #expect(!Trigger.all.isHeld(by: [.control, .option, .command], mouseDown: false))
}

@Test func triggerIgnoresTheMouseWhenItDoesNotRequireAClick() {
  let trigger: Trigger = [.control, .option]
  #expect(trigger.isHeld(by: [.control, .option], mouseDown: false))
  #expect(trigger.isHeld(by: [.control, .option], mouseDown: true))
}

@Test func triggerIsNotHeldWhenAKeyIsMissing() {
  #expect(!Trigger.all.isHeld(by: [.control, .option], mouseDown: true))
}

@Test func triggerIsNotHeldWhenAnExtraKeyIsDown() {
  let trigger: Trigger = [.control, .option]
  #expect(!trigger.isHeld(by: [.control, .option, .command], mouseDown: false))
  #expect(!trigger.isHeld(by: [.control, .option, .shift], mouseDown: false))
}

@Test func clickAloneCanBeTheTrigger() {
  #expect(Trigger.mouseClick.isHeld(by: [], mouseDown: true))
  #expect(!Trigger.mouseClick.isHeld(by: [.command], mouseDown: true))
}

@Test func emptyTriggerIsNeverHeld() {
  #expect(!Trigger().isHeld(by: [], mouseDown: false))
  #expect(!Trigger().isHeld(by: [], mouseDown: true))
}

@Test func capsLockAndFunctionDoNotAffectTheMatch() {
  let trigger: Trigger = [.control, .option]
  #expect(trigger.isHeld(by: [.control, .option, .capsLock, .function, .numericPad], mouseDown: false))
}

@Test func clicksAreCapturedOnceTheKeysAreDownAndBeforeTheClick() {
  #expect(Trigger.all.capturesClicks(with: [.control, .option, .command]))
}

@Test func clicksAreNotCapturedWhileTheKeysDoNotMatch() {
  #expect(!Trigger.all.capturesClicks(with: [.control, .option]))
  #expect(!Trigger.all.capturesClicks(with: [.control, .option, .command, .shift]))
}

@Test func clicksAreNotCapturedWhenTheTriggerHasNoClick() {
  let trigger: Trigger = [.control, .option]
  #expect(!trigger.capturesClicks(with: [.control, .option]))
}

@Test func clicksAreNeverCapturedWhenTheClickIsTheWholeTrigger() {
  #expect(!Trigger.mouseClick.capturesClicks(with: []))
}
