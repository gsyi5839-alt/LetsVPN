param(
    [string]$InputPng = "c:\LetsVPN\桌面LOGO.png"
)

$splashPng = "c:\LetsVPN\assets\images\app_icon_splash.png"
$icoOutput = "c:\LetsVPN\windows\runner\resources\app_icon.ico"

if (-not (Test-Path $InputPng)) {
    Write-Error "找不到文件: $InputPng`n请先将 桌面LOGO.png 保存到该路径"
    exit 1
}

Add-Type -AssemblyName System.Drawing

# 复制 PNG 到 assets（用于 Splash 页面图标显示）
Copy-Item -Force -Path $InputPng -Destination $splashPng
Write-Host "✓ 已更新 app_icon_splash.png"

# 将 PNG 转换为多尺寸 ICO（用于 Windows 桌面/任务栏图标）
$bitmap = [System.Drawing.Bitmap]::new($InputPng)
$sizes = @(16, 32, 48, 256)

$ms = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($ms)

# ICO 文件头
$bw.Write([Int16]0)              # Reserved
$bw.Write([Int16]1)              # Type: 1 = ICO
$bw.Write([Int16]$sizes.Count)   # 图像数量

# 计算第一个图像数据偏移
$offset = 6 + (16 * $sizes.Count)
$imageDataList = [System.Collections.ArrayList]::new()

foreach ($size in $sizes) {
    $resized = New-Object System.Drawing.Bitmap($bitmap, [System.Drawing.Size]::new($size, $size))
    $imgMs = New-Object System.IO.MemoryStream
    $resized.Save($imgMs, [System.Drawing.Imaging.ImageFormat]::Png)
    $imgData = $imgMs.ToArray()
    [void]$imageDataList.Add($imgData)

    # 目录项
    $w = if ($size -eq 256) { 0 } else { $size }
    $h = if ($size -eq 256) { 0 } else { $size }
    $bw.Write([Byte]$w)
    $bw.Write([Byte]$h)
    $bw.Write([Byte]0)           # 调色板数
    $bw.Write([Byte]0)           # Reserved
    $bw.Write([Int16]1)          # 色彩平面数
    $bw.Write([Int16]32)         # 位深
    $bw.Write([Int32]$imgData.Length)
    $bw.Write([Int32]$offset)
    $offset += $imgData.Length
}

foreach ($imgData in $imageDataList) {
    $bw.Write($imgData)
}

$bw.Flush()
[System.IO.File]::WriteAllBytes($icoOutput, $ms.ToArray())
Write-Host "✓ 已生成 app_icon.ico（含 16/32/48/256px）"

Write-Host "`n图标替换完成！请重新执行构建命令：`n  flutter build windows --release --target lib/main.dart"
