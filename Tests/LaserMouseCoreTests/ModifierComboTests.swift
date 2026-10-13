import AppKit
import Testing

@testable import LaserMouseCore

@Test func comboIsHeldWhenExactlyItsModifiersAreDown() {
  #expect(ModifierCombo.controlOptionCommand.isHeld(by: [.control, .option, .command]))
}

@Test func comboIsNotHeldWhenAModifierIsMissing() {
  #expect(!ModifierCombo.controlOptionCommand.isHeld(by: [.control, .option]))
}

@Test func comboIsNotHeldWhenAnExtraModifierIsDown() {
  #expect(!ModifierCombo.controlOption.isHeld(by: [.control, .option, .shift]))
}

@Test func capsLockAndFunctionDoNotAffectTheMatch() {
  #expect(ModifierCombo.controlOption.isHeld(by: [.control, .option, .capsLock, .function, .numericPad]))
}
