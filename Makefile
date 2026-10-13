APP := build/LaserMouse.app
# Command Line Tools ship Swift Testing outside the default search paths.
DEV_FRAMEWORKS := $(shell xcode-select -p)/Library/Developer/Frameworks
DEV_LIBS := $(shell xcode-select -p)/Library/Developer/usr/lib

.PHONY: build app install run test clean

build:
	swift build -c release

app: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp .build/release/LaserMouse $(APP)/Contents/MacOS/
	cp Resources/Info.plist $(APP)/Contents/
	codesign --force --sign - $(APP)

install: app
	rm -rf /Applications/LaserMouse.app
	cp -R $(APP) /Applications/

run: app
	open $(APP)

test:
	swift test -Xswiftc -F$(DEV_FRAMEWORKS) -Xlinker -F$(DEV_FRAMEWORKS) -Xlinker -rpath -Xlinker $(DEV_FRAMEWORKS) -Xlinker -rpath -Xlinker $(DEV_LIBS)

clean:
	rm -rf .build build
