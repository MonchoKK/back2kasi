Add-Type -AssemblyName System.Drawing

$sourcePath = "C:\Users\KABELO PC\.gemini\antigravity\brain\ba9ce623-fe35-4f1f-bdb7-7b6e28269f18\user_logo\Marketplace Symbol.png"
$src = [System.Drawing.Bitmap]::FromFile($sourcePath)

# The background color of the user's symbol
$bgColor = [System.Drawing.Color]::FromArgb(251, 248, 237)

# Create a master square 1024x1024 canvas with the symbol scaled to fit comfortably inside the adaptive safe zone (74% scale)
$masterSize = 1024
$masterBmp = [System.Drawing.Bitmap]::new($masterSize, $masterSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gMaster = [System.Drawing.Graphics]::FromImage($masterBmp)
$gMaster.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gMaster.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gMaster.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gMaster.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

$gMaster.Clear($bgColor)

# Scale the symbol so it has 12% padding on each side (76% size = 778px)
$symbolW = [int]($masterSize * 0.78)
$symbolH = [int]($masterSize * 0.78)
$symbolX = [int](($masterSize - $symbolW) / 2)
$symbolY = [int](($masterSize - $symbolH) / 2)

$destRect = [System.Drawing.Rectangle]::new($symbolX, $symbolY, $symbolW, $symbolH)
$gMaster.DrawImage($src, $destRect, 0, 0, $src.Width, $src.Height, [System.Drawing.GraphicsUnit]::Pixel)
$gMaster.Dispose()

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

    $r = [System.Drawing.Rectangle]::new(0, 0, $size, $size)
    $g.DrawImage($sourceBmp, $r, 0, 0, $sourceBmp.Width, $sourceBmp.Height, [System.Drawing.GraphicsUnit]::Pixel)
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
Save-ResizedIcon -sourceBmp $masterBmp -size 48  -destPath "$baseDir\app\android\app\src\main\res\mipmap-mdpi\ic_launcher.png"
Save-ResizedIcon -sourceBmp $masterBmp -size 72  -destPath "$baseDir\app\android\app\src\main\res\mipmap-hdpi\ic_launcher.png"
Save-ResizedIcon -sourceBmp $masterBmp -size 96  -destPath "$baseDir\app\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png"
Save-ResizedIcon -sourceBmp $masterBmp -size 144 -destPath "$baseDir\app\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png"
Save-ResizedIcon -sourceBmp $masterBmp -size 192 -destPath "$baseDir\app\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"

# Web icons
Save-ResizedIcon -sourceBmp $masterBmp -size 192 -destPath "$baseDir\app\web\icons\Icon-192.png"
Save-ResizedIcon -sourceBmp $masterBmp -size 512 -destPath "$baseDir\app\web\icons\Icon-512.png"
Save-ResizedIcon -sourceBmp $masterBmp -size 192 -destPath "$baseDir\app\web\icons\Icon-maskable-192.png"
Save-ResizedIcon -sourceBmp $masterBmp -size 512 -destPath "$baseDir\app\web\icons\Icon-maskable-512.png"
Save-ResizedIcon -sourceBmp $masterBmp -size 32  -destPath "$baseDir\app\web\favicon.png"

# Save the master preview to brain
$masterBmp.Save("C:\Users\KABELO PC\.gemini\antigravity\brain\ba9ce623-fe35-4f1f-bdb7-7b6e28269f18\user_logo\Master_App_Icon_1024.png", [System.Drawing.Imaging.ImageFormat]::Png)

$masterBmp.Dispose()
$src.Dispose()

Write-Host "User's Marketplace logo applied to all launcher mipmaps and web icons successfully!"
