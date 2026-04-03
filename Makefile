.PHONY: build run install clean

APP_NAME = VoiceInput
BUILD_DIR = .build
APP_BUNDLE = $(BUILD_DIR)/release/$(APP_NAME).app

build:
	@echo "Building $(APP_NAME)..."
	@swift build -c release --product $(APP_NAME)
	@echo "Creating .app bundle..."
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp Info.plist $(APP_BUNDLE)/Contents/
	@cp $(BUILD_DIR)/release/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	@echo "Code signing..."
	@codesign --force --deep --sign - $(APP_BUNDLE) 2>/dev/null || echo "Warning: Code signing skipped (no identity)"
	@echo "Build complete: $(APP_BUNDLE)"

run: build
	@open $(APP_BUNDLE)

install: build
	@cp -R $(APP_BUNDLE) /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

clean:
	@rm -rf $(BUILD_DIR)
	@echo "Cleaned build artifacts"
