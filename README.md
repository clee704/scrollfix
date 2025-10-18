# ScrollFix

ScrollFix inverts mouse scroll direction system-wide on macOS (so you can keep natural scrolling for your trackpad but Windows-style scrolling for your mouse). It runs as a lightweight LaunchAgent and automatically starts at login once installed.

## How it works

ScrollFix creates a low-level scroll event tap via the macOS Accessibility API and flips the scroll delta for non-continuous devices (mice, not trackpads).

Because this requires access to global input events, macOS will ask you to grant Accessibility permission to the ScrollFix binary once. After that, it runs silently in the background.

## Build and install

### Prerequisites

- macOS 13 or newer  
- Command Line Tools (`xcode-select --install`)  

### Steps

```bash
git clone https://github.com/clee704/scrollfix.git
cd scrollfix
./install.sh
```

During install:
1. The script compiles `scrollfix.cpp` → `scrollfix`.
2. It copies the binary to `~/Library/Application Support/ScrollFix/scrollfix` (stable path used by the permission dialog).
3. It installs `~/Library/LaunchAgents/dev.chungmin.scrollfix.plist` pointing at that path.
4. It asks you to grant Accessibility permission for the binary (System Settings → Privacy & Security → Accessibility).
5. Once granted, the LaunchAgent starts automatically.

Re-running `./install.sh` keeps the binary at the same path, so you generally don’t need to re-authorize Accessibility after the first run.

Expected output:
```
✅ dev.chungmin.scrollfix: running
```

The scroll inversion takes effect immediately.

## Uninstall

```bash
./uninstall.sh
```

This stops and removes the LaunchAgent and its plist. It also deletes the installed binary at `~/Library/Application Support/ScrollFix/scrollfix`.
