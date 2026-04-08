# План реализации: рабочая сборка и использование youtube-dl-gui

Документ описывает шаги после бекапа исходников, чтобы проект собирался на вашей машине и им можно было скачивать видео (в т.ч. с YouTube).

---

## Статус (что уже сделано в репозитории)

| Этап | Статус |
|------|--------|
| 0 Бекап | Есть `backup_project.py`, папка `backups/` |
| 1 Solution | Удалён отсутствующий проект `youtube-dl-gui-test` из `youtube-dl-gui.sln` |
| 2 Сборка | Удалены PreBuild/PostBuild из `youtube-dl-gui.csproj` (локальная сборка без BuildDateWriter / 7z / HashCalcConsole) |
| 3 yt-dlp + ffmpeg | `tools\fetch_ytdlp.ps1` и `tools\fetch_ffmpeg.ps1` кладут `yt-dlp.exe`, `ffmpeg.exe`, `ffprobe.exe` в `bin\Debug\` (рядом с GUI) |
| 4 Проверка | Запустите `youtube-dl-gui\bin\Debug\youtube-dl-gui.exe`, вставьте URL, режим **Video** |
| Загрузки | По умолчанию файлы идут в **`YouTubeDownloads`** в корне репозитория (рядом с `youtube-dl-gui.sln`). Старый путь в `youtube-dl-gui.ini` переопределяет это — смените в настройках программы при необходимости. |
| Языки | При сборке все `Languages\*.ini` копируются в **`bin\Debug\lang`** (и Release). Без этого в окне выбора языка только English (Internal). После правки — пересоберите проект или скопируйте папку `Languages` в `lang` рядом с exe. |
| YouTube + Node | В аргументы yt-dlp автоматически добавляется **`--js-runtimes node`** (быстрая и расширенная загрузка, запрос метаданных). Нужен **Node.js в PATH**; без него yt-dlp может выдать ошибку — тогда установите Node LTS или временно уберите флаг в коде. |
| Release | `tools\build_release.ps1` → `bin\Release\`; `tools\sync_runtime_debug_to_release.ps1` копирует yt-dlp/ffmpeg из Debug в Release |
| 5 Код | Исправлена передача пользовательских аргументов: везде `CustomArguments` вместо ошибочного `Arguments` (`frmMain`, `Program`, `frmArchiveDownloader`) |

**Сборка:** используйте **MSBuild из Visual Studio 2022** (Build Tools / Community и т.д.). Команда `dotnet build` для этих `.csproj` (WinForms, net472, `.resx`) на типичной установке SDK даёт ошибки `GenerateResource` — это ожидаемо.

```powershell
.\tools\build_debug.ps1
.\tools\build_release.ps1
```

---

## Этап 0 — Бекап

1. Скрипт `backup_project.py` в корне проекта.
2. Запуск: `python backup_project.py` из каталога `youtube-dl-gui-master`.
3. Архивы: `backups/`, префикс `youtube-dl-gui-master_backup_`, максимум **3** ZIP.

---

## Этап 1 — Solution (выполнено)

Из `youtube-dl-gui.sln` удалены: папка решения «Tests», проект `youtube-dl-gui-test`, его конфигурации и `NestedProjects`.

---

## Этап 2 — Сборка (выполнено)

События **PreBuildEvent** / **PostBuildEvent** убраны из `youtube-dl-gui.csproj`. Для официального релиза upstream их можно вернуть из git-истории и положить утилиты автору в корень solution.

**Артефакты Debug:**  
`youtube-dl-gui\bin\Debug\youtube-dl-gui.exe`  
`youtube-dl-gui-updater\bin\Debug\youtube-dl-gui-updater.exe`

---

## Этап 3 — Зависимости рантайма

1. **yt-dlp:** `powershell -File tools\fetch_ytdlp.ps1` → `youtube-dl-gui\bin\Debug\yt-dlp.exe`
2. **ffmpeg:** `powershell -File tools\fetch_ffmpeg.ps1` → `ffmpeg.exe` и `ffprobe.exe` в ту же папку, что и `youtube-dl-gui.exe` (так ищет `Verification`)
3. Для **Release:** после сборки выполните `tools\sync_runtime_debug_to_release.ps1`
4. **.NET Framework 4.7.2** — компонент Windows.

---

## Этап 4 — Проверка скачивания

1. Запустить `youtube-dl-gui.exe` из `bin\Debug`.
2. Вставить URL YouTube.
3. **Video** → скачать; в окне загрузки — сгенерированные аргументы и код выхода 0.

Проверка CLI без GUI:

```text
youtube-dl-gui\bin\Debug\yt-dlp.exe --version
```

---

## Этап 5 — Дополнительно

| Задача | Действие |
|--------|----------|
| Updater | Уже собирается вместе с solution; при необходимости скопировать `youtube-dl-gui-updater.exe` рядом с GUI |
| Расширенный загрузчик | Отдельная форма в приложении; плейлисты — через быстрый загрузчик (README) |
| Восстановить релизную упаковку | Вернуть блоки Pre/Post в `.csproj` из git + `BuildDateWriter`, `7z`, `HashCalcConsole` |

---

## Порядок с нуля (кратко)

1. `python backup_project.py`
2. `.\tools\build_debug.ps1`
3. При необходимости `.\tools\fetch_ytdlp.ps1`
4. Установить **ffmpeg**
5. Запуск `bin\Debug\youtube-dl-gui.exe` и тестовый URL
