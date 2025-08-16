# Makefile for GloboFucker
# Builds a complete macOS application bundle

# Configuration
APP_NAME = GloboFucker
BUNDLE_ID = com.globofucker.app
VERSION = 1.0
BUILD_NUMBER = 1

# Directories
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources
LANGUAGES_DIR = $(RESOURCES_DIR)/Languages

# Source files
SWIFT_SOURCES = $(shell find Sources -name "*.swift")
RESOURCE_FILES = $(shell find Resources -name "*" -type f)
LANGUAGE_FILES = $(shell find Languages -name "*.json")

# Compiler
SWIFTC = swiftc
SWIFT_FLAGS = -framework Cocoa -framework Carbon -framework ApplicationServices -framework ServiceManagement

# Default target
all: $(APP_BUNDLE)

# Create application bundle
$(APP_BUNDLE): $(MACOS_DIR)/$(APP_NAME) $(RESOURCES_DIR) $(LANGUAGES_DIR) $(CONTENTS_DIR)/Info.plist
	@echo "✅ Application bundle created: $(APP_BUNDLE)"

# Compile Swift sources
$(MACOS_DIR)/$(APP_NAME): $(SWIFT_SOURCES)
	@echo "🔨 Compiling Swift sources..."
	@mkdir -p $(MACOS_DIR)
	$(SWIFTC) $(SWIFT_FLAGS) -o $@ $(SWIFT_SOURCES)

# Create Resources directory and copy resources
$(RESOURCES_DIR):
	@echo "📁 Creating Resources directory..."
	@mkdir -p $(RESOURCES_DIR)
	@if [ -d "Resources" ]; then \
		cp -R Resources/* $(RESOURCES_DIR)/; \
	fi

# Create Languages directory and copy language files (re-copy on changes)
$(LANGUAGES_DIR): $(LANGUAGE_FILES)
	@echo "🌍 Creating Languages directory..."
	@mkdir -p $(LANGUAGES_DIR)
	@rm -rf $(LANGUAGES_DIR)/*
	@if [ -d "Languages" ]; then \
		cp -R Languages/* $(LANGUAGES_DIR)/; \
	fi

# Copy Info.plist
$(CONTENTS_DIR)/Info.plist: Info.plist
	@echo "📋 Copying Info.plist..."
	@mkdir -p $(CONTENTS_DIR)
	@cp Info.plist $(CONTENTS_DIR)/

# Install application
install: $(APP_BUNDLE)
	@echo "📦 Installing GloboFucker..."
	@cp -R $(APP_BUNDLE) /Applications/
	@echo "✅ GloboFucker installed to /Applications/"

# Uninstall application
uninstall:
	@echo "🗑️ Uninstalling GloboFucker..."
	@rm -rf /Applications/$(APP_NAME).app
	@echo "✅ GloboFucker uninstalled"

# Run application
run: $(APP_BUNDLE)
	@echo "🚀 Running GloboFucker..."
	@open $(APP_BUNDLE)

# Clean build directory
clean:
	@echo "🧹 Cleaning build directory..."
	@rm -rf $(BUILD_DIR)
	@echo "✅ Build directory cleaned"

# Create release package
package: $(APP_BUNDLE)
	@echo "📦 Creating release package..."
	@cd $(BUILD_DIR) && zip -r $(APP_NAME)-$(VERSION).zip $(APP_NAME).app
	@echo "✅ Release package created: $(BUILD_DIR)/$(APP_NAME)-$(VERSION).zip"

# Show help
help:
	@echo "GloboFucker Build System"
	@echo "========================"
	@echo "Available targets:"
	@echo "  all      - Build application bundle (default)"
	@echo "  install  - Install to /Applications/"
	@echo "  uninstall - Remove from /Applications/"
	@echo "  run      - Build and run application"
	@echo "  clean    - Clean build directory"
	@echo "  package  - Create release package"
	@echo "  help     - Show this help"

.PHONY: all install uninstall run clean package help 