#!/usr/bin/env bash
# Archive Shepherd (Release, generic iOS), export an App Store IPA, and verify it.
# Signs manually with the "Shepherd AppStore Profile" (IOS_APP_STORE) for team 6KH82C884Q.
# The profile must be installed first, e.g.:
#   asc --profile LittleRed profiles download --id 9N8YDXM67C \
#     --output "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles/<uuid>.mobileprovision"
# Usage: tools/archive.sh [build-number]   (default build number: 1)
# Output: build/Shepherd.xcarchive, build/export/Shepherd.ipa
set -euo pipefail

cd "$(dirname "$0")/.."

TEAM_ID=6KH82C884Q
BUNDLE_ID=com.dangvietquan.shepherd
PROFILE_NAME="Shepherd AppStore Profile"
MARKETING_VERSION=1.0.0
BUILD_NUMBER="${1:-1}"

OUT=build
ARCHIVE="$OUT/Shepherd.xcarchive"
EXPORT="$OUT/export"
LOG="$OUT/archive.log"

rm -rf "$ARCHIVE" "$EXPORT"
mkdir -p "$OUT"

xcodegen generate

echo "==> archive (log: $LOG)"
if ! xcodebuild archive \
    -project Shepherd.xcodeproj \
    -scheme Shepherd \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="Apple Distribution" \
    PROVISIONING_PROFILE_SPECIFIER="$PROFILE_NAME" \
    MARKETING_VERSION="$MARKETING_VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    >"$LOG" 2>&1; then
    tail -40 "$LOG"
    echo "ARCHIVE FAILED" >&2
    exit 1
fi
echo "ARCHIVE SUCCEEDED"

EXPORT_PLIST="$OUT/ExportOptions.plist"
cat >"$EXPORT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>app-store-connect</string>
    <key>destination</key><string>export</string>
    <key>teamID</key><string>$TEAM_ID</string>
    <key>signingStyle</key><string>manual</string>
    <key>signingCertificate</key><string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict><key>$BUNDLE_ID</key><string>$PROFILE_NAME</string></dict>
    <key>uploadSymbols</key><true/>
    <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
EOF

echo "==> export"
if ! xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportPath "$EXPORT" \
    -exportOptionsPlist "$EXPORT_PLIST" \
    >>"$LOG" 2>&1; then
    tail -40 "$LOG"
    echo "EXPORT FAILED" >&2
    exit 1
fi
echo "EXPORT SUCCEEDED: $EXPORT/Shepherd.ipa"

tools/verify_ipa.sh "$EXPORT/Shepherd.ipa" "$MARKETING_VERSION" "$BUILD_NUMBER"
