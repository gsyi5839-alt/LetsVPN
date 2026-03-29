$distTmpPath = Join-Path $PWD "dist\tmp"
$portablePath = Join-Path $distTmpPath "LetsVPN"
$setupOutputPath = Join-Path $PWD "out\LetsVPN-Windows-Setup-x64.exe"
$msixOutputPath = Join-Path $PWD "out\LetsVPN-Windows-Setup-x64.msix"
$portableOutputPath = Join-Path $PWD "out\LetsVPN-Windows-Portable-x64.zip"

New-Item -ItemType Directory -Force -Name "dist\tmp" | Out-Null
New-Item -ItemType Directory -Force -Name "out" | Out-Null

Remove-Item -LiteralPath $portablePath -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $setupOutputPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $msixOutputPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $portableOutputPath -Force -ErrorAction SilentlyContinue

# windows setup
# Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows-setup.exe" | Copy-Item -Destination "dist\tmp\letsvpn-setup.exe" -ErrorAction SilentlyContinue
# Compress-Archive -Force -Path "dist\tmp\letsvpn-setup.exe",".github\help\mac-windows\*.url" -DestinationPath "out\LetsVPN-Windows-Setup-x64.zip"
$latestSetup = Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows-setup.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($null -ne $latestSetup) {
  Copy-Item -LiteralPath $latestSetup.FullName -Destination $setupOutputPath -Force
}

$latestMsix = Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows.msix" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($null -ne $latestMsix) {
  Copy-Item -LiteralPath $latestMsix.FullName -Destination $msixOutputPath -Force
}


# windows portable
xcopy "build\windows\x64\runner\Release" "dist\tmp\LetsVPN" /E/H/C/I/Y | Out-Null
xcopy ".github\help\mac-windows\*.url" "dist\tmp\LetsVPN" /E/H/C/I/Y | Out-Null
Compress-Archive -Force -Path "dist\tmp\LetsVPN" -DestinationPath $portableOutputPath -ErrorAction SilentlyContinue

Remove-Item -Path "$HOME\.pub-cache\git\cache\flutter_circle_flags*" -Force -Recurse -ErrorAction SilentlyContinue

echo "Done"
