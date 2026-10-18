# Preview images for the Obsidian Apps pages: one shared background (apps/preview_bg.jpg, a bright blue to violet
# gradient with a light glow, so the dark cards stand out as over a TV picture) and one transparent overlay per app (apps/preview_<app>.png) that the app page draws on top of it.
# Overlays are the skin's own layer grabbed from a receiver with OpenWebif (/grab?mode=osd, transparent where video is).
# Usage: powershell -File tools\app-previews.ps1 -Osd <folder with osd_weather.png, osd_bitrate.png, osd_menu.png, osd_chlist.png, osd_infobar.png, osd_infobar_glass.png, osd_infobar_nova.png>
param([string]$Osd = "")
Add-Type -AssemblyName System.Drawing
$root = Join-Path $PSScriptRoot ".." | Resolve-Path
$out = Join-Path $root "Obsidian-FHD\apps"
$W = 896; $H = 504
function C($hex, $a = 255) { [System.Drawing.Color]::FromArgb($a, [System.Drawing.ColorTranslator]::FromHtml($hex)) }

# shared background
$bg = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bg); $g.SmoothingMode = "AntiAlias"
$lin = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Point(0, 0)), (New-Object System.Drawing.Point($W, $H)), (C "#3A7BC8"), (C "#5B3A9E"))
$g.FillRectangle($lin, 0, 0, $W, $H)
$glow = New-Object System.Drawing.Drawing2D.GraphicsPath; $glow.AddEllipse(-220, -260, 900, 700)
$pgb = New-Object System.Drawing.Drawing2D.PathGradientBrush($glow); $pgb.CenterColor = (C "#7FF6FF" 120); $pgb.SurroundColors = @((C "#00F0FF" 0))
$g.FillPath($pgb, $glow)
$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$ep = New-Object System.Drawing.Imaging.EncoderParameters 1; $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]92)
$bg.Save((Join-Path $out "preview_bg.jpg"), $enc, $ep); "preview_bg.jpg"

function SaveOverlay([System.Drawing.Image]$src, [string]$name) {
	$o = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g2 = [System.Drawing.Graphics]::FromImage($o); $g2.InterpolationMode = "HighQualityBicubic"; $g2.Clear([System.Drawing.Color]::Transparent)
	$g2.DrawImage($src, 0, 0, $W, $H)
	$o.Save((Join-Path $out "preview_$name.png"), [System.Drawing.Imaging.ImageFormat]::Png); $g2.Dispose(); $o.Dispose(); "preview_$name.png"
}

# About: logo and name
$about = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($about); $g.SmoothingMode = "AntiAlias"; $g.TextRenderingHint = "AntiAliasGridFit"; $g.Clear([System.Drawing.Color]::Transparent)
$logo = [System.Drawing.Image]::FromFile((Join-Path $root "Obsidian-FHD\icons\logo_big.png")); $g.DrawImage($logo, 338, 90, 220, 220); $logo.Dispose()
$pfc = New-Object System.Drawing.Text.PrivateFontCollection
$pfc.AddFontFile((Join-Path $root "Obsidian-FHD\fonts\Inter-SemiBold.ttf")); $pfc.AddFontFile((Join-Path $root "Obsidian-FHD\fonts\JetBrainsMono-Bold.ttf"))
$cf = New-Object System.Drawing.StringFormat; $cf.Alignment = "Center"
$fi = $pfc.Families | Where-Object { $_.Name -like "Inter*" } | Select-Object -First 1
$fm = $pfc.Families | Where-Object { $_.Name -like "JetBrains*" } | Select-Object -First 1
$g.DrawString("Obsidian FHD", (New-Object System.Drawing.Font($fi, 40, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)), (New-Object System.Drawing.SolidBrush (C "#FFFFFF")), (New-Object System.Drawing.RectangleF(0, 330, $W, 60)), $cf)
$g.DrawString("DARK 1080P SKIN FOR ENIGMA2", (New-Object System.Drawing.Font($fm, 18, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)), (New-Object System.Drawing.SolidBrush (C "#00F0FF")), (New-Object System.Drawing.RectangleF(0, 396, $W, 40)), $cf)
$g.Dispose(); $about.Save((Join-Path $out "preview_about.png"), [System.Drawing.Imaging.ImageFormat]::Png); "preview_about.png"

if (-not $Osd) { "Give -Osd <folder> to rebuild the app overlays"; return }
foreach ($n in "weather", "bitrate", "menu", "chlist", "infobar", "infobar_glass", "infobar_nova") {
	$f = Join-Path $Osd "osd_$n.png"
	if (-not (Test-Path $f)) { "missing $f"; continue }
	$img = [System.Drawing.Image]::FromFile($f); SaveOverlay $img $n; $img.Dispose()
}
