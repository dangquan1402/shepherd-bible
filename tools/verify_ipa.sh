#!/usr/bin/env bash
# Pre-upload checks on an exported App Store IPA. Exits non-zero on the first failed check.
# Usage: tools/verify_ipa.sh path/to/Shepherd.ipa [marketing-version] [build-number]
set -euo pipefail

IPA="$1"
WANT_VERSION="${2:-1.0.0}"
WANT_BUILD="${3:-1}"
TEAM_ID=6KH82C884Q

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
unzip -q "$IPA" -d "$WORK"
APP="$(echo "$WORK"/Payload/*.app)"
PLIST="$APP/Info.plist"

fail=0
check() { # check <label> <command...>
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "PASS  $label"; else echo "FAIL  $label"; fail=1; fi
}
plist_eq() { [ "$(plutil -extract "$1" raw -o - "$PLIST")" = "$2" ]; }

check "Assets.car present" test -f "$APP/Assets.car"
check "AppIcon files present" sh -c "ls '$APP'/AppIcon*.png"
for f in paths.json lamb_variants.json sample_bible.json; do check "content $f present" test -s "$APP/$f"; done
check "CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconName = AppIcon" plist_eq CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconName AppIcon
check "CFBundlePackageType = APPL" plist_eq CFBundlePackageType APPL
check "CFBundleVersion = $WANT_BUILD" plist_eq CFBundleVersion "$WANT_BUILD"
check "CFBundleShortVersionString = $WANT_VERSION" plist_eq CFBundleShortVersionString "$WANT_VERSION"
check "ITSAppUsesNonExemptEncryption = false" plist_eq ITSAppUsesNonExemptEncryption false
check "MinimumOSVersion = 26.0" plist_eq MinimumOSVersion 26.0
check "UIDeviceFamily = [1]" sh -c "[ \"\$(plutil -extract UIDeviceFamily json -o - '$PLIST')\" = '[1]' ]"

PROFILE="$WORK/profile.plist"
security cms -D -i "$APP/embedded.mobileprovision" >"$PROFILE" 2>/dev/null || : >"$PROFILE"
check "embedded.mobileprovision present" test -s "$PROFILE"
check "profile team = $TEAM_ID" sh -c "[ \"\$(plutil -extract TeamIdentifier.0 raw -o - '$PROFILE')\" = $TEAM_ID ]"
check "profile is App Store distribution (no devices, not get-task-allow)" sh -c \
    "! plutil -extract ProvisionedDevices raw -o - '$PROFILE' && ! plutil -extract ProvisionsAllDevices raw -o - '$PROFILE' \
     && [ \"\$(plutil -extract Entitlements.get-task-allow raw -o - '$PROFILE')\" = false ]"
check "signed by Apple Distribution" sh -c "codesign -dvv '$APP' 2>&1 | grep -q 'Authority=Apple Distribution: .*($TEAM_ID)'"

# Scan every Mach-O in the bundle (Debug builds move app code into Shepherd.debug.dylib).
BINS="$WORK/binaries.txt"
find "$APP" -type f -exec sh -c 'file -b "$1" | grep -q Mach-O && echo "$1"' _ {} \; >"$BINS"
check "binaries found" test -s "$BINS"
check "no debug dylib in bundle" sh -c "! grep -q '\.debug\.dylib$' '$BINS'"
check "binaries have no -appearance/-screen launch handling" sh -c "! xargs strings -a <'$BINS' | grep -qxE -- '-(appearance|screen)'"
check "binaries have no debug fixture router" sh -c "! xargs strings -a <'$BINS' | grep -qiE 'fixture|screenRouter|handleLaunchArguments'"

echo "--- Info.plist summary"
for k in CFBundleIdentifier CFBundleShortVersionString CFBundleVersion MinimumOSVersion CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconName; do
    printf '%s = %s\n' "$k" "$(plutil -extract "$k" raw -o - "$PLIST" 2>/dev/null)"
done
printf 'profile = %s (%s)\n' "$(plutil -extract Name raw -o - "$PROFILE" 2>/dev/null)" "$(plutil -extract UUID raw -o - "$PROFILE" 2>/dev/null)"

if [ "$fail" -ne 0 ]; then echo "IPA CHECKS FAILED" >&2; exit 1; fi
echo "IPA CHECKS PASSED"
