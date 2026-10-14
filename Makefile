APP_NAME := Blabber
BUNDLE_ID := com.tejas.blabber
SIGN_IDENTITY := Blabber Dev Signing
BUILD_DIR := .build/release
APP_BUNDLE := build/$(APP_NAME).app
ICONSET := Resources/Blabber.iconset
ICNS := Resources/Blabber.icns

INSTALL_DIR := /Applications

.PHONY: all build bundle icon sign run clean test selfcheck cert install

all: bundle

# --- Toolchain / signing setup (run once) ---------------------------------

cert:
	./Scripts/make-cert.sh

# --- Icon -------------------------------------------------------------------

icon:
	swift Scripts/make-icon.swift
	iconutil -c icns $(ICONSET) -o $(ICNS)

# --- Build --------------------------------------------------------------

build:
	swift build -c release --product $(APP_NAME)

# --- Bundle assembly ------------------------------------------------------
# SwiftPM produces a bare Mach-O executable; this assembles it into a
# proper .app bundle by hand since there's no Xcode project to do it.

bundle: build
	rm -rf "$(APP_BUNDLE)"
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	cp "$(BUILD_DIR)/$(APP_NAME)" "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"
	cp Resources/Info.plist "$(APP_BUNDLE)/Contents/Info.plist"
	if [ -f "$(ICNS)" ]; then cp "$(ICNS)" "$(APP_BUNDLE)/Contents/Resources/Blabber.icns"; fi
	$(MAKE) sign

# --- Signing --------------------------------------------------------------
# Signs with the stable self-signed dev identity (Scripts/make-cert.sh).
# This is what makes TCC permission grants (Microphone, Input Monitoring,
# Accessibility) survive rebuilds instead of resetting every time.

sign:
	codesign --force --deep --sign "$(SIGN_IDENTITY)" \
		--entitlements Resources/Blabber.entitlements \
		"$(APP_BUNDLE)"
	codesign -dv "$(APP_BUNDLE)" 2>&1 | head -5

# --- Run --------------------------------------------------------------------
# Always launch via `open`, never by executing the binary directly, or
# TCC attributes the permissions to Terminal instead of Blabber.

run: bundle
	open "$(APP_BUNDLE)"

# --- Install ----------------------------------------------------------------
# Copies the signed bundle to /Applications. Never uses sudo: if
# /Applications isn't writable by the current user, this fails with a
# clear message instead of silently elevating privileges.

install: bundle
	@if [ ! -w "$(INSTALL_DIR)" ]; then \
		echo "$(INSTALL_DIR) is not writable by $$(whoami) — fix its permissions or move Blabber.app there yourself. Not using sudo."; \
		exit 1; \
	fi
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	cp -R "$(APP_BUNDLE)" "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"

# --- Tests ------------------------------------------------------------------
# `swift test` builds but does not actually execute on this CLT-only
# toolchain (see Sources/SelfCheck/main.swift for the full story).
# `make test` runs the real check.

selfcheck:
	swift run SelfCheck

test: selfcheck

clean:
	rm -rf .build build
