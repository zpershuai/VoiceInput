.PHONY: build run install clean

APP_NAME = VoiceInput
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/release/$(APP_NAME).app
INSTALL_PATH = /Applications/$(APP_NAME).app
ALLOW_ADHOC_INSTALL ?= 0

# Codesign identity - use environment variable or Makefile variable
# For stable Accessibility trust, use a Developer ID: CODESIGN_IDENTITY="Developer ID Application: Your Name"
# For ad-hoc signing (default): CODESIGN_IDENTITY="-"
CODESIGN_IDENTITY ?= -

build:
	@echo "Building $(APP_NAME)..."
	@swift build -c release --product $(APP_NAME) --build-path $(BUILD_DIR)
	@echo "Creating .app bundle..."
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp Info.plist $(APP_BUNDLE)/Contents/
	@cp $(BUILD_DIR)/release/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	@echo "Code signing with identity: $(CODESIGN_IDENTITY)..."
	@codesign --force --deep --sign "$(CODESIGN_IDENTITY)" $(APP_BUNDLE) 2>/dev/null || echo "Warning: Code signing failed"
	@echo ""
	@echo "=== Build Complete ==="
	@echo "Bundle: $(APP_BUNDLE)"
	@echo "Signing: $$(codesign -dv $(APP_BUNDLE) 2>&1 | grep -E 'Identifier|Authority|Sealed')"
	@echo "======================"

run: build
	@open $(APP_BUNDLE)

install: build
	@if [ "$(CODESIGN_IDENTITY)" = "-" ] && [ "$(ALLOW_ADHOC_INSTALL)" != "1" ]; then \
		echo "ERROR: Refusing to install an ad-hoc signed app to $(INSTALL_PATH)."; \
		echo "Accessibility permission will not reliably persist across reinstalls."; \
		echo "Use a stable signing identity:"; \
		echo "  make install CODESIGN_IDENTITY=\"Developer ID Application: Your Name\""; \
		echo "Or override intentionally for one-off testing:"; \
		echo "  make install ALLOW_ADHOC_INSTALL=1"; \
		exit 1; \
	fi
	@echo "Installing to $(INSTALL_PATH)..."
	@if [ -d "$(INSTALL_PATH)" ]; then \
		echo "Removing existing app bundle..."; \
		rm -rf "$(INSTALL_PATH)"; \
	fi
	@echo "Copying new app bundle..."
	@ditto $(APP_BUNDLE) $(INSTALL_PATH)
	@echo ""
	@echo "=== Install Complete ==="
	@echo "Path: $(INSTALL_PATH)"
	@echo "Bundle ID: $$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' $(INSTALL_PATH)/Contents/Info.plist 2>/dev/null || echo 'unknown')"
	@echo "Signing: $$(codesign -dv $(INSTALL_PATH) 2>&1 | grep -E 'Identifier|Authority|Sealed' || echo 'unsigned')"
	@echo "========================"
	@echo ""

clean:
	@rm -rf $(BUILD_DIR)
	@echo "Cleaned build artifacts"
