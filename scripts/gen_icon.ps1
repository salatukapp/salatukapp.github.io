# Generates Salatuk's branded master icons with GDI+ (no external assets):
#   assets/icons/icon.png            1024² emerald gradient + gold crescent & star
#   assets/icons/icon_foreground.png 1024² transparent, motif padded into the
#                                    adaptive-icon safe zone
# Run:  powershell -ExecutionPolicy Bypass -File scripts/gen_icon.ps1
Add-Type -AssemblyName System.Drawing

$size = 1024
$gold = [System.Drawing.Color]::FromArgb(255, 201, 169, 97)   # #C9A961

function Draw-Motif($g, $cx, $cy, $r) {
    # Crescent: outer gold disc minus an offset disc (true transparent carve).
    $outer = New-Object System.Drawing.Drawing2D.GraphicsPath
    $outer.AddEllipse([float]($cx - $r), [float]($cy - $r), [float]($r * 2), [float]($r * 2))
    $region = New-Object System.Drawing.Region($outer)

    $io = $r * 0.42          # horizontal offset of the carving disc
    $ir = $r * 0.86          # carving disc radius
    $inner = New-Object System.Drawing.Drawing2D.GraphicsPath
    $inner.AddEllipse([float]($cx - $ir + $io), [float]($cy - $ir - ($r * 0.10)), [float]($ir * 2), [float]($ir * 2))
    $region.Exclude($inner)

    $goldBrush = New-Object System.Drawing.SolidBrush($gold)
    $g.FillRegion($goldBrush, $region)

    # Five-point star to the upper-right of the crescent opening.
    $sr = $r * 0.34
    $scx = $cx + $r * 0.62
    $scy = $cy - $r * 0.52
    $pts = @()
    for ($i = 0; $i -lt 5; $i++) {
        $ang = -90 + $i * 72
        $rad = [Math]::PI * $ang / 180
        $pts += New-Object System.Drawing.PointF([float]($scx + $sr * [Math]::Cos($rad)), [float]($scy + $sr * [Math]::Sin($rad)))
        $angI = $ang + 36
        $radI = [Math]::PI * $angI / 180
        $pts += New-Object System.Drawing.PointF([float]($scx + ($sr * 0.42) * [Math]::Cos($radI)), [float]($scy + ($sr * 0.42) * [Math]::Sin($radI)))
    }
    $g.FillPolygon((New-Object System.Drawing.SolidBrush($gold)), [System.Drawing.PointF[]]$pts)
}

function New-Icon($path, $withBg, $scale) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    if ($withBg) {
        $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
        $c1 = [System.Drawing.Color]::FromArgb(255, 14, 74, 55)    # #0E4A37
        $c2 = [System.Drawing.Color]::FromArgb(255, 30, 107, 82)   # #1E6B52
        $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $c1, $c2, [single]45)
        $g.FillRectangle($bg, $rect)
    }

    $r = $size * 0.30 * $scale
    # Nudge left so the crescent opening + star sit centered as a unit.
    Draw-Motif $g ($size * 0.46) ($size * 0.54) $r

    $g.Dispose()
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "wrote $path"
}

$dir = Join-Path $PSScriptRoot "..\assets\icons"
New-Icon (Join-Path $dir "icon.png") $true 1.0
New-Icon (Join-Path $dir "icon_foreground.png") $false 0.78
