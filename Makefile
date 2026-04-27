# Makefile for Xsign iOS App - No XcodeGen, No Code Signing
# Builds unsigned IPA for iOS devices only
# Usage: make help

# Configuration
SHELL := /bin/bash
PROJECT_NAME := Xsign
SCHEME := Xsign
PLATFORM := iOS
IOS_VERSION_MIN := 17.0
CONFIGURATION := Release
BUILDDIR := $(PWD)/build
DERIVED_DATA := $(BUILDDIR)/DerivedData
ARCHIVE_PATH := $(BUILDDIR)/$(PROJECT_NAME).xcarchive
IPA_PATH := $(BUILDDIR)/$(PROJECT_NAME).ipa

# Swift Package paths
PACKAGE_SWIFT := Package.swift
SOURCES_DIR := Xsign

.PHONY: help setup clean build-device archive ipa generate-xcworkspace \
        bootstrap-submodules clean-build clean-derived clean-all

## Show available commands
help:
	@echo "Xsign iOS App Build System (No Code Signing)"
	@echo "================================================"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make bootstrap-submodules  - Initialize git submodules (zsign)"
	@echo "  make generate-xcworkspace  - Generate Xcode project from Package.swift"
	@echo ""
	@echo "Device Builds (iOS Devices Only):"
	@echo "  make build-device         - Build for iOS Device (iphoneos, no signing)"
	@echo "  make archive              - Create xcarchive for devices (no signing)"
	@echo "  make ipa                  - Create unsigned IPA for iOS devices"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean                - Clean build artifacts"
	@echo "  make clean-derived        - Clean DerivedData"
	@echo "  make clean-all            - Clean everything"
	@echo ""
	@echo "Configuration:"
	@echo "  PLATFORM:              $(PLATFORM)"
	@echo "  SCHEME:                $(SCHEME)"
	@echo "  CONFIGURATION:         $(CONFIGURATION)"
	@echo "  IOS VERSION:           $(IOS_VERSION_MIN)+"
	@echo ""
	@echo "WARNING: No code signing - builds unsigned IPA for devices"

## Initialize git submodules (zsign)
bootstrap-submodules:
	@echo "Initializing git submodules..."
	git submodule update --init --recursive
	@echo "Submodules initialized"

## Generate Xcode project from Swift Package
generate-xcworkspace: bootstrap-submodules
	@echo "Generating Xcode project from Package.swift..."
	@rm -rf $(PROJECT_NAME).xcodeproj
	swift package generate-xcodeproj
	@echo "Generated $(PROJECT_NAME).xcodeproj"

## Build for iOS Device (no code signing)
build-device: generate-xcworkspace
	@echo "Building $(PROJECT_NAME) for iOS Device (no signing)..."
	@if [ ! -d "$(PROJECT_NAME).xcodeproj" ]; then \
		echo "Xcode project not found. Run 'make generate-xcworkspace' first."; \
		exit 1; \
	fi
	xcodebuild build \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-sdk iphoneos \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGN_IDENTITY="" \
		PROVISIONING_PROFILE_SPECIFIER="" \
		2>&1 | xcpretty || true
	@echo "Device build complete (unsigned). Check $(DERIVED_DATA)"

## Create xcarchive for iOS Device (no signing)
archive: generate-xcworkspace
	@echo "Creating archive for iOS Device (no signing)..."
	@if [ ! -d "$(PROJECT_NAME).xcodeproj" ]; then \
		echo "Xcode project not found. Run 'make generate-xcworkspace' first."; \
		exit 1; \
	fi
	@rm -rf $(ARCHIVE_PATH)
	xcodebuild archive \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-sdk iphoneos \
		-archivePath $(ARCHIVE_PATH) \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGN_IDENTITY="" \
		PROVISIONING_PROFILE_SPECIFIER="" \
		2>&1 | xcpretty || true
	@echo "Archive created (unsigned) at $(ARCHIVE_PATH)"

## Create Unsigned IPA for iOS Devices
ipa: archive
	@echo "Creating unsigned IPA for iOS Devices..."
	@if [ ! -d "$(ARCHIVE_PATH)" ]; then \
		echo "Archive not found. Run 'make archive' first."; \
		exit 1; \
	fi
	@mkdir -p $(BUILDDIR)/ipa-staging
	@rm -rf $(BUILDDIR)/ipa-staging/*
	
# Copy .app from archive
	@echo "Extracting .app from archive..."
	cp -r $(ARCHIVE_PATH)/Products/Applications/*.app $(BUILDDIR)/ipa-staging/ 2>/dev/null || \
	cp -r $(ARCHIVE_PATH)/Products/Applications/$(PROJECT_NAME).app $(BUILDDIR)/ipa-staging/ 2>/dev/null || \
	find $(ARCHIVE_PATH)/Products -name "*.app" -exec cp -r {} $(BUILDDIR)/ipa-staging/ \;
	
# Create IPA structure
	@echo "Packaging IPA..."
	@mkdir -p $(BUILDDIR)/ipa-staging/Payload
	@mv $(BUILDDIR)/ipa-staging/*.app $(BUILDDIR)/ipa-staging/Payload/ 2>/dev/null || true
	
# Create unsigned IPA
	cd $(BUILDDIR)/ipa-staging && zip -r ../$(PROJECT_NAME).ipa Payload/
	
	@echo "Unsigned IPA created at $(IPA_PATH)"
	@ls -lh $(IPA_PATH)
	@echo ""
	@echo "WARNING: This is an UNSIGNED IPA - it will only work on:"
	@echo "  - Jailbroken devices"
	@echo "  - Devices with developer mode enabled (for development)"
	@echo "  - If you re-sign it manually with a valid certificate"

## Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILDDIR)
	rm -rf $(PROJECT_NAME).xcodeproj
	@echo "Clean complete"

## Clean DerivedData only
clean-derived:
	@echo "Cleaning DerivedData..."
	rm -rf $(DERIVED_DATA)
	@echo "DerivedData cleaned"

## Clean everything including workspace
clean-all: clean
	@echo "Cleaning everything..."
	rm -rf .build
	@echo "Full clean complete"

## Show build settings
show-build-settings: generate-xcworkspace
	xcodebuild -project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-showBuildSettings \
		-sdk iphoneos

# Default target
.DEFAULT_GOAL := help
