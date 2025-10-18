#!/usr/bin/env bash
set -euo pipefail

LABEL="dev.chungmin.scrollfix"
DOMAIN="gui/$(id -u)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_SRC="${SCRIPT_DIR}/dev.chungmin.scrollfix.plist"
AGENTS_DIR="${HOME}/Library/LaunchAgents"
PLIST_DST="${AGENTS_DIR}/${LABEL}.plist"
INSTALL_ROOT="${HOME}/Library/Application Support/ScrollFix"
BIN_BUILD="${SCRIPT_DIR}/scrollfix"
BIN_PATH="${INSTALL_ROOT}/scrollfix"

echo "=== Build ==="
make -C "${SCRIPT_DIR}"

if [[ ! -x "${BIN_BUILD}" ]]; then
  echo "Error: binary not found or not executable at: ${BIN_BUILD}" >&2
  exit 1
fi

echo "=== Install plist ==="
mkdir -p "${AGENTS_DIR}"
cp -f "${PLIST_SRC}" "${PLIST_DST}"
/usr/bin/sed -i '' "s#/path/to/scrollfix#${BIN_PATH}#g" "${PLIST_DST}"
chmod 0644 "${PLIST_DST}"

echo "=== Install binary ==="
mkdir -p "${INSTALL_ROOT}"
/usr/bin/install -m 0755 "${BIN_BUILD}" "${BIN_PATH}"

# Optionally write logs to files for easier debugging (harmless if duplicated)
if ! /usr/bin/plutil -extract StandardOutPath raw "${PLIST_DST}" >/dev/null 2>&1; then
  /usr/bin/sed -i '' 's#</dict>#<key>StandardOutPath</key><string>'"$HOME"'/Library/Logs/scrollfix.out.log</string><key>StandardErrorPath</key><string>'"$HOME"'/Library/Logs/scrollfix.err.log</string></dict>#' "${PLIST_DST}"
fi

# --- launchd helpers ---
bootout()   { launchctl bootout   "${DOMAIN}/${LABEL}" >/dev/null 2>&1 || true; }
bootstrap() { launchctl bootstrap "${DOMAIN}" "${PLIST_DST}"; }
kick()      { launchctl kickstart -k "${DOMAIN}/${LABEL}" >/dev/null 2>&1 || true; }
is_running(){ launchctl print "${DOMAIN}/${LABEL}" 2>/dev/null | grep -q 'state = running'; }
last_exit() { launchctl print "${DOMAIN}/${LABEL}" 2>/dev/null | awk -F'= ' '/last exit code/{print $2; exit}'; }
settle()    { sleep 0.7; }

open_ax() {
  echo "Opening Accessibility…"
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || true
  echo "→ Enable the entry for EXACT path:"
  echo "   ${BIN_PATH}"
  open -R "${BIN_PATH}" || true
}

echo "=== (Re)load agent ==="
bootout
bootstrap
launchctl enable "${DOMAIN}/${LABEL}" >/dev/null 2>&1 || true
kick
settle

# --- permission loop (AX only) ---
for _ in {1..12}; do
  if is_running; then
    echo "✅ ${LABEL}: running"
    exit 0
  fi

  code="$(last_exit || true)"
  case "${code:-}" in
    10)
      echo "⚠️  Needs Accessibility for: ${BIN_PATH}"
      open_ax
      read -rp "Press Enter after enabling Accessibility…"
      kick; settle
      ;;
    "" )
      settle
      ;;
    0 )
      # unexpected clean exit; just restart
      kick; settle
      ;;
    * )
      echo "⚠️  Exited with code ${code}. Recent logs:"
      log show --last 2m --predicate 'process == "scrollfix"' --style compact || true
      launchctl print "${DOMAIN}/${LABEL}" 2>/dev/null | sed -n '1,160p' || true
      exit "${code}"
      ;;
  esac
done

echo "⚠️  Timed out waiting for ${LABEL} to run. Logs:"
log show --last 3m --predicate 'process == "scrollfix"' --style compact || true
launchctl print "${DOMAIN}/${LABEL}" 2>/dev/null | sed -n '1,200p' || true
exit 1
