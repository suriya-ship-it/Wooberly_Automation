#!/bin/bash

# Script: update_package_swift.sh
# Purpose: Patch FlutterGeneratedPluginSwiftPackage/Package.swift after
#          "flutter pub get" resets the iOS deployment target.
# Usage:   Run manually, or add as an Xcode Scheme Pre-action.

# ---- Resolve SRCROOT ----
if [ -z "$SRCROOT" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SRCROOT="$(dirname "$SCRIPT_DIR")"
fi

XCCONFIG_PATH="${SRCROOT}/Flutter/AppEnvConfig.xcconfig"
PACKAGE_SWIFT_PATH="${SRCROOT}/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"

# ---- Read deployment target ----
if [ -f "$XCCONFIG_PATH" ]; then
    DEPLOYMENT_TARGET=$(grep "IPHONEOS_DEPLOYMENT_TARGET" "$XCCONFIG_PATH" | cut -d'=' -f2 | xargs)
fi

if [ -z "$DEPLOYMENT_TARGET" ]; then
    echo "Warning: IPHONEOS_DEPLOYMENT_TARGET not found in xcconfig, defaulting to 16.0"
    DEPLOYMENT_TARGET="16.0"
fi

echo "Using deployment target: $DEPLOYMENT_TARGET"

# ---- Patch FlutterGeneratedPluginSwiftPackage/Package.swift ----
if [ -f "$PACKAGE_SWIFT_PATH" ]; then
    # Replace any .iOS("X.X") with .iOS("$DEPLOYMENT_TARGET")
    sed -i '' -E "s/\.iOS\(\"[0-9]+\.[0-9]+\"\)/\.iOS(\"${DEPLOYMENT_TARGET}\")/g" "$PACKAGE_SWIFT_PATH"
    echo "Patched: $PACKAGE_SWIFT_PATH"
else
    echo "Warning: Package.swift not found at $PACKAGE_SWIFT_PATH"
fi

# ---- Patch individual plugin Package.swift files ----
PACKAGES_DIR="${SRCROOT}/Flutter/ephemeral/Packages/.packages"
if [ -d "$PACKAGES_DIR" ]; then
    find "$PACKAGES_DIR" -name "Package.swift" | while read -r plugin_package; do
        # Only patch files that use string-based .iOS("X.X") syntax
        if grep -qE '\.iOS\("[0-9]+\.[0-9]+"' "$plugin_package"; then
            sed -i '' -E "s/\.iOS\(\"[0-9]+\.[0-9]+\"\)/\.iOS(\"${DEPLOYMENT_TARGET}\")/g" "$plugin_package"
            echo "Patched: $plugin_package"
        fi
    done
fi

echo "Done. iOS deployment target set to ${DEPLOYMENT_TARGET} in all Package.swift files."
