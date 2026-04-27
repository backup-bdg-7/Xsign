.PHONY: help build clean test xcodegen generate-xcodeproj run-simulator

# Default target
help:
	@echo "Xsign iOS App Build System"
	@echo "=========================="
	@echo ""
	@echo "Available commands:"
	@echo "  make build          - Build the app for iOS Simulator"
	@echo "  make build-device   - Build the app for iOS Device"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make test           - Run tests"
	@echo "  make xcodegen       - Generate Xcode project (requires xcodegen)"
	@echo "  make generate-xcodeproj - Alias for xcodegen"
	@echo "  make run-simulator  - Build and run on simulator"
	@echo "  make archive        - Create archive for distribution"
	@echo "  make swift-package  - Update Swift Package dependencies"
	@echo ""

# Build for iOS Simulator (Release)
build:
	@echo "Building Xsign for iOS Simulator..."
	xcodebuild build \
		-scheme Xsign \
		-sdk iphonesimulator \
		-configuration Release \
		-destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		-derivedDataPath ./DerivedData

# Build for iOS Device (Release)
build-device:
	@echo "Building Xsign for iOS Device..."
	xcodebuild build \
		-scheme Xsign \
		-sdk iphoneos \
		-configuration Release \
		-destination 'generic/platform=iOS' \
		-derivedDataPath ./DerivedData

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf ./DerivedData
	rm -rf ./build
	xcodebuild clean \
		-scheme Xsign \
		-sdk iphonesimulator \
		-configuration Release || true

# Run tests
test:
	@echo "Running tests..."
	xcodebuild test \
		-scheme Xsign \
		-sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
		-derivedDataPath ./DerivedData

# Generate Xcode project from Package.swift (if needed for development)
xcodegen:
	@echo "Generating Xcode project from Package.swift..."
	swift package generate-xcodeproj

generate-xcodeproj: xcodegen

# Build and run on simulator
run-simulator: build
	@echo "Installing app to simulator..."
	@SIMULATOR_ID=$$(xcrun simctl list devices booted | grep -E 'iPhone 15 Pro' | head -1 | sed -E 's/.*\(([A-Z0-9-]+)\).*/\1/'); \
	if [ -z "$$SIMULATOR_ID" ]; then \
		echo "Booting iPhone 15 Pro simulator..."; \
		SIMULATOR_ID=$$(xcrun simctl create "Xsign Simulator" "iPhone 15 Pro" "iOS 17.0"); \
		xcrun simctl boot "$$SIMULATOR_ID"; \
	fi; \
	echo "Simulator ID: $$SIMULATOR_ID"; \
	APP_PATH=$$(find ./DerivedData -name "Xsign.app" -type d | head -1); \
	if [ -n "$$APP_PATH" ]; then \
		xcrun simctl install "$$SIMULATOR_ID" "$$APP_PATH"; \
		xcrun simctl launch "$$SIMULATOR_ID" com.example.Xsign; \
	else \
		echo "App not found. Build may have failed."; \
	fi

# Create archive for distribution
archive:
	@echo "Creating archive..."
	xcodebuild archive \
		-scheme Xsign \
		-sdk iphoneos \
		-configuration Release \
		-archivePath ./build/Xsign.xcarchive \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO

# Update Swift Package dependencies
swift-package:
	@echo "Updating Swift Package dependencies..."
	swift package update
	swift package resolve

# Build for CI (simplified)
ci-build:
	@echo "Building for CI..."
	swift build --configuration release

# Format code (requires swift-format)
format:
	@echo "Formatting code..."
	swift format --recursive ./Xsign

# Lint code (requires SwiftLint)
lint:
	@echo "Linting code..."
	swiftlint lint ./Xsign

# Open in Xcode
open:
	@echo "Opening in Xcode..."
	open Package.swift

