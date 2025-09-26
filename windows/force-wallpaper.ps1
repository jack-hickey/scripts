# This script is designed to fight DC controlled desktop wallpapers

$wallpaperFolder = ""
$regPath = "HKCU:\Control Panel\Desktop"

if (-not ("Wallpaper" -as [type])) {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
"@
}

function Set-Wallpaper {
    param($path)

    Set-ItemProperty -Path $regPath -Name Wallpaper -Value $path
    Set-ItemProperty -Path $regPath -Name WallpaperStyle -Value "10"
    Set-ItemProperty -Path $regPath -Name TileWallpaper -Value "0"

    [Wallpaper]::SystemParametersInfo(20, 0, $path, 3) | Out-Null
    Write-Host "Wallpaper applied at $(Get-Date) with Fill mode"
}

while ($true) {
    $wallpaperPath = Get-ChildItem -Path $wallpaperFolder -Filter "wallpaper.*" | 
                     Where-Object { $_.Extension -match "\.jpg|\.jpeg|\.png|\.bmp" } |
                     Select-Object -First 1 -ExpandProperty FullName

    if ($wallpaperPath) {
        Set-Wallpaper -path $wallpaperPath
    } else {
        Write-Host "No wallpaper file found in $wallpaperFolder"
    }

    Start-Sleep -Seconds 30
}
