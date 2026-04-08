# Мини-окно: путь к youtube-dl-gui.exe + ссылка → запуск загрузки видео (-v URL).
# Сохраняет путь к exe в %APPDATA%\youtube-dl-gui-quick\exe-path.txt

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$cfgDir = Join-Path $env:APPDATA "youtube-dl-gui-quick"
$cfgExe = Join-Path $cfgDir "exe-path.txt"
if (-not (Test-Path $cfgDir)) { New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null }

$form = New-Object System.Windows.Forms.Form
$form.Text = "YouTube — быстрая загрузка"
$form.Size = New-Object System.Drawing.Size(560, 220)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.MinimizeBox = $false

$lblExe = New-Object System.Windows.Forms.Label
$lblExe.Text = "Программа youtube-dl-gui (выберите youtube-dl-gui.exe один раз):"
$lblExe.Location = New-Object System.Drawing.Point(12, 10)
$lblExe.AutoSize = $true

$tbExe = New-Object System.Windows.Forms.TextBox
$tbExe.Location = New-Object System.Drawing.Point(12, 32)
$tbExe.Width = 420
$tbExe.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
if (Test-Path $cfgExe) {
    $tbExe.Text = (Get-Content -LiteralPath $cfgExe -Raw -Encoding UTF8).Trim()
}

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Обзор..."
$btnBrowse.Location = New-Object System.Drawing.Point(440, 29)
$btnBrowse.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "youtube-dl-gui|youtube-dl-gui.exe|Все exe|*.exe"
    $ofd.Title = "Укажите youtube-dl-gui.exe"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $tbExe.Text = $ofd.FileName
    }
})

$lblUrl = New-Object System.Windows.Forms.Label
$lblUrl.Text = "Ссылка на видео (вставьте из браузера):"
$lblUrl.Location = New-Object System.Drawing.Point(12, 68)
$lblUrl.AutoSize = $true

$tbUrl = New-Object System.Windows.Forms.TextBox
$tbUrl.Location = New-Object System.Drawing.Point(12, 88)
$tbUrl.Width = 508
$tbUrl.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

$btnGo = New-Object System.Windows.Forms.Button
$btnGo.Text = "Скачать (откроется окно загрузки)"
$btnGo.Location = New-Object System.Drawing.Point(12, 130)
$btnGo.Width = 240
$btnGo.Add_Click({
    $exe = $tbExe.Text.Trim()
    $url = $tbUrl.Text.Trim()
    if (-not $exe -or -not (Test-Path -LiteralPath $exe)) {
        [System.Windows.Forms.MessageBox]::Show("Укажите существующий файл youtube-dl-gui.exe (кнопка «Обзор»).", "Нужен путь к программе")
        return
    }
    if (-not $url) {
        [System.Windows.Forms.MessageBox]::Show("Вставьте ссылку на ролик.", "Нет ссылки")
        return
    }
    [System.IO.File]::WriteAllText($cfgExe, $exe, [System.Text.UTF8Encoding]::new($false))
    # Аргументы youtube-dl-gui: -v URL = скачать как видео (настройки как в программе)
    Start-Process -FilePath $exe -ArgumentList @("-v", $url)
    $form.Close()
})

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "Качество и папка — как в самой youtube-dl-gui (последние настройки)."
$lblHint.Location = New-Object System.Drawing.Point(12, 168)
$lblHint.AutoSize = $true
$lblHint.ForeColor = [System.Drawing.Color]::DimGray

$form.Controls.AddRange(@($lblExe, $tbExe, $btnBrowse, $lblUrl, $tbUrl, $btnGo, $lblHint))
[void]$form.ShowDialog()
