#!/usr/bin/env bash
set -euo pipefail

LABEL="dev.chungmin.scrollfix"
DOMAIN="gui/$(id -u)"
PLIST_DST="${HOME}/Library/LaunchAgents/${LABEL}.plist"

echo "=== Uninstall ${LABEL} ==="
if launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1; then
  echo "Unloading agent…"
  launchctl bootout "${DOMAIN}/${LABEL}" || true
else
  echo "Agent not loaded."
fi

if [[ -f "${PLIST_DST}" ]]; then
  echo "Removing plist: ${PLIST_DST}"
  rm -f "${PLIST_DST}"
else
  echo "No plist to remove."
fi

echo "✅ Uninstall complete."
