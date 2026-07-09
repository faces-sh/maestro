#!/bin/bash
#
# Upgrade a pre-0.4 "Faced" install to the current Maestro.
#
# Old Faced versions (0.3.x and earlier) predate the Maestro rename and the Sparkle
# auto-updater, so they can't update themselves and they store data in old locations.
# This script installs the latest Maestro, removes the old app and every trace of its
# data, repairs the local faces catalog, and launches the new app.
#
# Kept on purpose: ~/.faces (your Faces sign-in and catalog carry over; the new app
# uses the same convention). Removed for good: old chats and the old Deepself data
# (the new app rebuilds your Deepself during onboarding; the old format is incompatible).
#
#   curl -fsSL https://raw.githubusercontent.com/faces-sh/maestro/main/upgrade-from-faced.sh | bash
#
set -uo pipefail

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

say "Closing the old app"
osascript -e 'quit app "Faced"' 2>/dev/null || true
osascript -e 'quit app "Maestro"' 2>/dev/null || true
sleep 2

say "Downloading the latest Maestro"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
if ! curl -fL --progress-bar -o "$TMP/Maestro.dmg" \
     "https://github.com/faces-sh/maestro/releases/latest/download/Maestro.dmg"; then
  echo "Download failed. Nothing was changed on this Mac. Check your connection and re-run." >&2
  exit 1
fi

say "Installing Maestro into /Applications"
MNT="$TMP/mnt"
mkdir -p "$MNT"
if ! hdiutil attach "$TMP/Maestro.dmg" -nobrowse -quiet -mountpoint "$MNT"; then
  echo "Could not open the downloaded disk image. Nothing was changed on this Mac." >&2
  exit 1
fi
rm -rf /Applications/Maestro.app
if ! ditto "$MNT/Maestro.app" /Applications/Maestro.app; then
  hdiutil detach "$MNT" -quiet || true
  echo "Could not write to /Applications. Opening the disk image instead:" >&2
  echo "drag Maestro to Applications by hand, then re-run this script to finish cleanup." >&2
  open "$TMP/Maestro.dmg"
  exit 1
fi
hdiutil detach "$MNT" -quiet || true

say "Removing the old Faced app and its data"
# The nightly launchd job keeps running even after the app is deleted; remove it first.
launchctl bootout "gui/$(id -u)/sh.faces.faced.nightly" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/sh.faces.faced.nightly.plist"
rm -rf /Applications/Faced.app
rm -rf "$HOME/Library/Application Support/Faced"
defaults delete ai.headwaters.faced >/dev/null 2>&1 || true
rm -f "$HOME/Library/Preferences/ai.headwaters.faced.plist"
rm -rf "$HOME/Library/Caches/ai.headwaters.faced" \
       "$HOME/Library/HTTPStorages/ai.headwaters.faced" \
       "$HOME/Library/Saved Application State/ai.headwaters.faced.savedState" \
       "$HOME/Library/WebKit/ai.headwaters.faced"
# Old permission grants are keyed to the old app and would only confuse System Settings.
tccutil reset All ai.headwaters.faced >/dev/null 2>&1 || true

say "Repairing the local faces catalog"
# The new app bundles the current faces CLI and its own node, so nothing needs installing.
RT="/Applications/Maestro.app/Contents/Resources/faces-runtime"
if ! "$RT/node/bin/node" "$RT/bin/faces" catalog:doctor --fix; then
  echo "(Catalog repair skipped; onboarding will sort the catalog out after you sign in.)"
fi

say "Launching Maestro"
open /Applications/Maestro.app
echo ""
echo "Done. Maestro will walk you through onboarding; your Faces sign-in was kept."
echo "From here on the app updates itself."
