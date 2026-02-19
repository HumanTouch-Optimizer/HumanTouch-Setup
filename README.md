# HumanTouch Optimizer v2.0

A production-ready, modular PowerShell GUI installer for Windows applications using **winget**.

![Windows 10/11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows)
![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell)

## Features

- **Horizontal Scrollable Layout** — Browse app categories by scrolling left/right
- **3 Built-in Presets** — Gaming 🎮, Work 💼, Media 🎬 (icon buttons with tooltips)
- **Custom Presets** — Save & load your own preset selections for future use
- **Visual Install Feedback** — Apps dim during install, smoothly fade to full opacity on completion
- **Internet Connectivity Check** — Detects offline state and shows an overlay with retry button
- **Resizable & DPI-Friendly** — Window can be resized for low-DPI displays
- **Clear Selection** — One-click button to deselect all apps
- **Background Installation** — Non-blocking installs via separate runspace
- **6 Categories, 40+ Apps** — Browsers, Communication, Gaming, System Tools, Media, Development

## Modular Architecture

```
HumanTouch-Setup/
├── HumanTouch-Setup.ps1      # Main entry point & event wiring
└── modules/
    ├── Config.ps1             # App definitions & built-in presets
    ├── XAML.ps1               # Window UI markup
    ├── Builder.ps1            # Dynamic UI construction
    ├── Helpers.ps1            # Logging, status, progress utilities
    ├── Presets.ps1            # Custom preset save/load system
    └── Installer.ps1          # Background installation engine
```

## Quick Start

```powershell
# Right-click → Run as Administrator, or:
powershell -ExecutionPolicy Bypass -File .\HumanTouch-Setup.ps1
```

The script auto-elevates to administrator if needed.

## Requirements

- Windows 10 / 11
- PowerShell 5.1+
- **winget** (Windows Package Manager) — install via Microsoft Store "App Installer"
- Internet connection

## Custom Presets

Your custom presets are saved as JSON files in:
```
%APPDATA%\HumanTouch-Optimizer\Presets\
```

## License

MIT License — see [LICENSE](LICENSE) for details.
