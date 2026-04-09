# Murs Media

Windows GUI for **[yt-dlp](https://github.com/yt-dlp/yt-dlp)** (and compatible downloaders) plus **[ffmpeg](https://ffmpeg.org/)** for conversion. This project is a maintained fork of **[youtube-dl-gui](https://github.com/murrty/youtube-dl-gui)** with branding and release workflow updates.

**Author / автор:** Ольга Шевелева

![Screenshot](preview.png)

## Download

**[Releases →](https://github.com/Murs2024/youtube-dl-gui-master/releases)** — portable `.zip` or `youtube-dl-gui.exe`.

1. Extract and run `youtube-dl-gui.exe`.
2. Install [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases) and point to it in **Settings**.
3. For conversion, install ffmpeg and set its path in **Settings** when prompted.

**Requirements:** Windows, **.NET Framework 4.7.2** (usually present on Windows 10/11).

## Build from source

Requires [Visual Studio 2022 Build Tools](https://visualstudio.microsoft.com/downloads/) (or VS) with **.NET desktop development** and **.NET Framework 4.7.2** targeting.

```powershell
git clone https://github.com/Murs2024/youtube-dl-gui-master.git
cd youtube-dl-gui-master
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

Output: `youtube-dl-gui\bin\Release\youtube-dl-gui.exe`. Close a running copy of the app before rebuilding.

Optional: `create-desktop-shortcut.ps1` creates a **Murs Media** shortcut and copies language files next to the exe.

## Features

- Quick and extended download forms, batch downloads, converter, protocol handler support.
- Custom arguments for advanced users.
- Optional [userscripts](USERSCRIPTS.md) integration.

## License

This program is licensed under the **GNU GPL v3** — see [LICENSE](LICENSE).

---

### Кратко по-русски

**Murs Media** — программа для Windows: загрузка видео через **yt-dlp**, конвертация через **ffmpeg**. Скачать сборку: **[Releases](https://github.com/Murs2024/youtube-dl-gui-master/releases)**. После распаковки запустите `youtube-dl-gui.exe`, укажите пути к yt-dlp (и при необходимости ffmpeg) в **Настройках**. Сборка из исходников — команда `build.ps1` в корне репозитория (нужны Build Tools / Visual Studio с .NET Framework 4.7.2).
