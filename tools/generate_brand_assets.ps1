param(
    [string]$Source = "logo-heart-pixel.png"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$repo = Resolve-Path (Join-Path $PSScriptRoot "..")
$sourcePath = Resolve-Path (Join-Path $repo $Source)
$resDir = Join-Path $repo "android\app\src\main\res"
$storeDir = Join-Path $repo "store_assets"

New-Item -ItemType Directory -Force -Path $storeDir | Out-Null

function New-TransparentIcon {
    param(
        [System.Drawing.Bitmap]$Image
    )

    $bitmap = New-Object System.Drawing.Bitmap $Image.Width, $Image.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $bitmap.SetResolution(96, 96)

    for ($y = 0; $y -lt $Image.Height; $y++) {
        for ($x = 0; $x -lt $Image.Width; $x++) {
            $pixel = $Image.GetPixel($x, $y)
            $r = [int]$pixel.R
            $g = [int]$pixel.G
            $b = [int]$pixel.B
            $max = [Math]::Max($r, [Math]::Max($g, $b))
            $pinkScore = $r - [Math]::Max($g, $b)
            $whiteHighlight = ($r -gt 160 -and $g -gt 115 -and $b -gt 135)
            $isPinkGlow = ($r -gt 34 -and $pinkScore -gt 10)

            if ($whiteHighlight) {
                $alpha = 255
            }
            elseif ($isPinkGlow) {
                $alpha = [Math]::Min(255, [Math]::Max(0, (($r - 24) * 1.35) + ($pinkScore * 2.2)))
            }
            elseif ($max -lt 28) {
                $alpha = 0
            }
            else {
                $alpha = [Math]::Max(0, [Math]::Min(90, ($max - 30) * 1.2))
            }

            if ($alpha -lt 12) {
                $bitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            }
            else {
                $bitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb([int]$alpha, $r, $g, $b))
            }
        }
    }

    return $bitmap
}

function Save-ResizedPng {
    param(
        [System.Drawing.Image]$Image,
        [string]$Path,
        [int]$Width,
        [int]$Height,
        [bool]$Transparent = $false
    )

    $dir = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $bitmap = New-Object System.Drawing.Bitmap $Width, $Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $bitmap.SetResolution(96, 96)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    if ($Transparent) {
        $graphics.Clear([System.Drawing.Color]::Transparent)
    }
    else {
        $graphics.Clear([System.Drawing.Color]::FromArgb(18, 0, 20))
    }
    $graphics.DrawImage($Image, 0, 0, $Width, $Height)
    $graphics.Dispose()
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

function Save-FeatureGraphic {
    param(
        [System.Drawing.Image]$Image,
        [string]$Path
    )

    $width = 1024
    $height = 500
    $bitmap = New-Object System.Drawing.Bitmap $width, $height
    $bitmap.SetResolution(96, 96)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $rect = New-Object System.Drawing.Rectangle 0, 0, $width, $height
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(18, 0, 20),
        [System.Drawing.Color]::FromArgb(37, 0, 46),
        [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
    )
    $graphics.FillRectangle($brush, $rect)
    $brush.Dispose()

    $glowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(62, 255, 20, 147))
    $graphics.FillEllipse($glowBrush, 565, -70, 430, 430)
    $graphics.FillEllipse($glowBrush, -110, 220, 340, 340)
    $glowBrush.Dispose()

    $iconSize = 360
    $iconRect = New-Object System.Drawing.Rectangle 92, 70, $iconSize, $iconSize
    $radius = 58
    $graphicsPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $graphicsPath.AddArc($iconRect.X, $iconRect.Y, $radius, $radius, 180, 90)
    $graphicsPath.AddArc(($iconRect.Right - $radius), $iconRect.Y, $radius, $radius, 270, 90)
    $graphicsPath.AddArc(($iconRect.Right - $radius), ($iconRect.Bottom - $radius), $radius, $radius, 0, 90)
    $graphicsPath.AddArc($iconRect.X, ($iconRect.Bottom - $radius), $radius, $radius, 90, 90)
    $graphicsPath.CloseFigure()
    $graphics.SetClip($graphicsPath)
    $graphics.DrawImage($Image, $iconRect)
    $graphics.ResetClip()
    $graphicsPath.Dispose()

    $titleFont = New-Object System.Drawing.Font "Segoe UI", 58, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $subtitleFont = New-Object System.Drawing.Font "Segoe UI", 26, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
    $pinkBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 20, 147))
    $whiteBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(235, 255, 255, 255))
    $softBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(210, 255, 119, 200))

    $graphics.DrawString("Couple Snap", $titleFont, $whiteBrush, 500, 166)
    $graphics.DrawString("Private neon snaps for two", $subtitleFont, $softBrush, 504, 246)

    foreach ($point in @(
        @(870, 112, 9), @(930, 344, 7), @(668, 84, 6), @(506, 352, 5), @(806, 412, 4)
    )) {
        $graphics.FillRectangle($pinkBrush, $point[0], $point[1], $point[2], $point[2])
    }

    $titleFont.Dispose()
    $subtitleFont.Dispose()
    $pinkBrush.Dispose()
    $whiteBrush.Dispose()
    $softBrush.Dispose()
    $graphics.Dispose()
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

$sourceBitmap = [System.Drawing.Bitmap]::FromFile($sourcePath)
$transparentIcon = New-TransparentIcon $sourceBitmap

$densities = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($density in $densities.Keys) {
    $size = $densities[$density]
    Save-ResizedPng $transparentIcon (Join-Path $resDir "$density\ic_launcher.png") $size $size $true
    Save-ResizedPng $transparentIcon (Join-Path $resDir "$density\ic_launcher_round.png") $size $size $true
}

Save-ResizedPng $transparentIcon (Join-Path $resDir "drawable-nodpi\ic_launcher_foreground.png") 432 432 $true
Save-ResizedPng $transparentIcon (Join-Path $storeDir "app_icon_1024.png") 1024 1024 $true
Save-ResizedPng $transparentIcon (Join-Path $storeDir "play_store_icon_512.png") 512 512 $true
Save-ResizedPng $sourceBitmap (Join-Path $storeDir "app_icon_with_background_1024.png") 1024 1024 $false
Save-ResizedPng $sourceBitmap (Join-Path $storeDir "play_store_icon_with_background_512.png") 512 512 $false
Save-FeatureGraphic $transparentIcon (Join-Path $storeDir "feature_graphic_1024x500.png")

$transparentIcon.Dispose()
$sourceBitmap.Dispose()

Write-Output "Generated launcher and store assets from $Source"
