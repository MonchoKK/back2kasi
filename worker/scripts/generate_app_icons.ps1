Add-Type -AssemblyName System.Drawing

$sourcePath = "C:\Users\KABELO PC\.gemini\antigravity\brain\ba9ce623-fe35-4f1f-bdb7-7b6e28269f18\back2kasi_app_icon_1794423651403.jpg"
$src = [System.Drawing.Bitmap]::FromFile($sourcePath)

function Save-ResizedIcon {
    param (
        [System.Drawing.Bitmap]$sourceBmp,
        [int]$size,
        [string]$destPath
    )

    $destBmp = [System.Drawing.Bitmap]::new($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($destBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

    $destRect = [System.Drawing.Rectangle]::new(0, 0, $size, $size)
    $g.DrawImage($sourceBmp, $destRect, 0, 0, $sourceBmp.Width, $sourceBmp.Height, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()

    $parentDir = Split-Path $destPath
    if (!(Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $destBmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destBmp.Dispose()
    Write-Host "Generated: $destPath ($size x $size)"
}

$baseDir = "c:\Users\KABELO PC\practise_projects\back2kasi"

# Android mipmap launcher icons
Save-ResizedIcon -sourceBmp $src -size 48  -destPath "$baseDir\app\android\app\src\main\res\mipmap-mdpi\ic_launcher.png"
Save-ResizedIcon -sourceBmp $src -size 72  -destPath "$baseDir\app\android\app\src\main\res\mipmap-hdpi\ic_launcher.png"
Save-ResizedIcon -sourceBmp $src -size 96  -destPath "$baseDir\app\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png"
Save-ResizedIcon -sourceBmp $src -size 144 -destPath "$baseDir\app\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png"
Save-ResizedIcon -sourceBmp $src -size 192 -destPath "$baseDir\app\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"

# Web icons
Save-ResizedIcon -sourceBmp $src -size 192 -destPath "$baseDir\app\web\icons\Icon-192.png"
Save-ResizedIcon -sourceBmp $src -size 512 -destPath "$baseDir\app\web\icons\Icon-512.png"
Save-ResizedIcon -sourceBmp $src -size 192 -destPath "$baseDir\app\web\icons\Icon-maskable-192.png"
Save-ResizedIcon -sourceBmp $src -size 512 -destPath "$baseDir\app\web\icons\Icon-maskable-512.png"
Save-ResizedIcon -sourceBmp $src -size 32  -destPath "$baseDir\app\web\favicon.png"

$src.Dispose()

Write-Host "All Back2Kasi launcher and web icons updated to One Marketplace design successfully!"
