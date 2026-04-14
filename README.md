# Chris Titus Tech's Windows Utility

[![Version](https://img.shields.io/github/v/release/ChrisTitusTech/winutil?color=%230567ff&label=Latest%20Release&style=for-the-badge)](https://github.com/ChrisTitusTech/winutil/releases/latest)
![GitHub Downloads (specific asset, all releases)](https://img.shields.io/github/downloads/ChrisTitusTech/winutil/winutil.ps1?label=Total%20Downloads&style=for-the-badge)
[![](https://dcbadge.limes.pink/api/server/https://discord.gg/RUbZUZyByQ?theme=default-inverted&style=for-the-badge)](https://discord.gg/RUbZUZyByQ)
[![Static Badge](https://img.shields.io/badge/Documentation-_?style=for-the-badge&logo=bookstack&color=grey)](https://winutil.christitus.com/)

This utility is a compilation of Windows tasks I perform on each Windows system I use. It is meant to streamline *installs*, debloat with *tweaks*, troubleshoot with *config*, and fix Windows *updates*. I am extremely picky about any contributions to keep this project clean and efficient.

![screen-install](/docs/assets/images/Title-Screen.png)

## 💡 Usage

Winutil must be run in Admin mode because it performs system-wide tweaks. To achieve this, run PowerShell as an administrator. Here are a few ways to do it:

1. **Start menu Method:**
   - Right-click on the start menu.
   - Choose "Windows PowerShell (Admin)" (for Windows 10) or "Terminal (Admin)" (for Windows 11).

2. **Search and Launch Method:**
   - Press the Windows key.
   - Type "PowerShell" or "Terminal" (for Windows 11).
   - Press `Ctrl + Shift + Enter` or Right-click and choose "Run as administrator" to launch it with administrator privileges.

### Launch Command (this fork)

Build `winutil.ps1` with `.\Compile.ps1`, then publish it as release asset **`winutil.ps1`** on [Abengs84/winutil](https://github.com/Abengs84/winutil) so the URL below resolves.

```ps1
irm "https://github.com/Abengs84/winutil/releases/latest/download/winutil.ps1" | iex
```

Upstream shortcuts (Chris Titus Tech) for reference: `irm "https://christitus.com/win" | iex` — those load the official build, not this fork.

If you have Issues, refer to [Known Issues](https://winutil.christitus.com/knownissues/) or open an issue on your fork.

## 🎓 Documentation

### [WinUtil Official Documentation](https://winutil.christitus.com/)

### [YouTube Tutorial](https://www.youtube.com/watch?v=6UQZ5oQg8XA)

### [ChrisTitus.com Article](https://christitus.com/windows-tool/)

## 🛠️ Build & Develop

> [!NOTE]
> Winutil is a relatively large script, so it's split into multiple files which're combined into a single `.ps1` file using a custom compiler. This makes maintaining the project a lot easier.

Get a copy of the source code. This can be done using GitHub UI (**Code** > **Download ZIP**), or by cloning (downloading) the repo using git.

If git is installed, run the following commands under a PowerShell window to clone and move into the project's directory:
```ps1
git clone --depth 1 "https://github.com/ChrisTitusTech/winutil.git"
cd winutil
```

To build the project, run the Compile Script under a PowerShell window (admin permissions IS NOT required):
```ps1
.\Compile.ps1
```

You'll see a new file named `winutil.ps1`, which was created by `Compile.ps1` script. Now you can run it as admin, and a new window will pop up. Enjoy your own compiled version of WinUtil :)

