# Windows PowerShell script to install zuite 0.1.0

$repo = "MatejKis/zuite"
$version = "0.1.0"

$arch = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "i386" }

$filename = "zuite-$version-windows-$arch.zip"
$url = "https://github.com/$repo/releases/download/v$version/$filename"

$installDir = "$env:USERPROFILE\bin"
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

$tmpZip = "$env:TEMP\$filename"

Write-Output "Downloading $url ..."
Invoke-WebRequest -Uri $url -OutFile $tmpZip

Write-Output "Extracting..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($tmpZip, $installDir)

Remove-Item $tmpZip

Write-Output "Installed zuite to $installDir"

if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $installDir })) {
    Write-Warning "$installDir is not in your PATH."
    Write-Output "Add the following to your user environment PATH variable:"
    Write-Output "  $installDir"
}

Write-Output "Done! You can now run 'zuite.exe' from PowerShell or CMD."

