<h1 align="center">Sigil</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg" alt="Swift 5.0">
  <img src="https://img.shields.io/badge/macOS-14%2B-blue.svg" alt="macOS 14+">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License MIT">
</p>

<p align="center">
  A native macOS menubar password manager.<br>
  Seal your credentials behind the macOS Keychain — one click away in the menubar.
</p>

## Features

- **Menubar native** — Lives in the macOS menubar as an `NSPopover`. No dock icon, no window clutter.
- **Keychain sealed** — Passwords stored exclusively in the macOS Keychain. Never written to disk in plain text.
- **One-click copy** — Click any credential to copy the password. Hover to reveal username, password, or eye-toggle.
- **Strength meter** — Visual entropy indicator on every entry and inside the generator.
- **Password generator** — Length 8–64, uppercase / lowercase / digits / symbols toggles, ambiguous-character filter.
- **Search** — Filter credentials by service, username, or URL.
- **Edit & open** — Right-click any row to edit, copy username, open the URL, or delete.
- **Launch at Login** — Optional auto-start on macOS login.

## Installation

**Requirements:** macOS 14.0+, Xcode 15.0+, [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
git clone https://github.com/abderrahimghazali/sigil.git
cd sigil

xcodegen generate
open Sigil.xcodeproj
```

Build and run (`⌘R`). Sigil appears in the menubar.

### DMG Install

Download the `.dmg` from [Releases](https://github.com/abderrahimghazali/sigil/releases), open it, and drag Sigil to Applications.

> **Note:** Since the app is not notarized, macOS will block it on first launch. Right-click (or Control-click) on Sigil.app and select **Open**, then click **Open** in the dialog to bypass Gatekeeper.

## License

MIT
