#!/usr/bin/env bash
set -euo pipefail

LABEL="dev.chungmin.scrollfix"
DOMAIN="gui/$(id -u)"
PLIST_DST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
INSTALL_ROOT="${HOME}/Library/Application Support/ScrollFix"
BIN_PATH="${INSTALL_ROOT}/scrollfix"

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

if [[ -f "${BIN_PATH}" ]]; then
  echo "Removing binary: ${BIN_PATH}"
  rm -f "${BIN_PATH}"
  rmdir "${INSTALL_ROOT}" >/dev/null 2>&1 || true
else
  echo "No binary to remove."
fi

echo "✅ Uninstall complete."
