# Selection images for the Floating menu style (skin_menu_floating.xml): a full-width, slightly lighter row from card
# edge to card edge with a cyan accent bar on the right edge; the entry text turns white. Drawn on the solid card
# colour, so edges blend correctly on boxes that cannot blend PNG alpha over video.
Add-Type -AssemblyName System.Drawing
$out = Join-Path $PSScriptRoot "..\Obsidian-FHD\window" | Resolve-Path
function C($hex, $a = 255) { [System.Drawing.Color]::FromArgb($a, [System.Drawing.ColorTranslator]::FromHtml($hex)) }
function RR($x, $y, $w, $h, $r) { $p = New-Object System.Drawing.Drawing2D.GraphicsPath; $d = 2 * $r; $p.AddArc($x, $y, $d, $d, 180, 90); $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90); $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90); $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90); $p.CloseFigure(); $p }
foreach ($s in @(@("sel_floating_main", 518, 68), @("sel_floating_sub", 638, 68), @("sel_floating_main_txt", 518, 60), @("sel_floating_sub_txt", 638, 60))) {
	$name, $w, $h = $s
	$bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = "AntiAlias"
	$g.Clear((C "#0F131B"))
	$g.FillRectangle((New-Object System.Drawing.SolidBrush (C "#1C2532")), 0, 2, $w, ($h - 4))  # full-width row
	$g.FillRectangle((New-Object System.Drawing.SolidBrush (C "#00F0FF")), ($w - 5), 2, 5, ($h - 4))  # accent bar on the card edge
	$bmp.Save((Join-Path $out "$name.png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
	"{0,-22} {1}x{2}" -f $name, $w, $h
}

# RAM ring for the Floating dashboard (skin_sysinfo.xml): 21 images, 0..100 % in 5 % steps, picked by the
# ObsidianSysInfo "RamStep" value (Pixmap renderer "pixmaps" list, OpenATV). Opaque card background.
$ringDir = Join-Path $out "..\icons\ring" ; New-Item -ItemType Directory -Force $ringDir | Out-Null
for ($i = 0; $i -le 20; $i++) {
	$s = 168; $bmp = New-Object System.Drawing.Bitmap $s, $s, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = "AntiAlias"; $g.Clear((C "#0F131B"))
	$w = 14; $r = New-Object System.Drawing.RectangleF(($w / 2 + 2), ($w / 2 + 2), ($s - $w - 4), ($s - $w - 4))
	$g.DrawEllipse((New-Object System.Drawing.Pen((C "#1E2A30"), $w)), $r)
	if ($i -gt 0) { $p = New-Object System.Drawing.Pen((C "#00F0FF"), $w); $p.StartCap = "Round"; $p.EndCap = "Round"; $g.DrawArc($p, $r, -90, [float]($i * 18)) }
	$bmp.Save((Join-Path $ringDir ("ram_{0:D2}.png" -f $i)), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
"ram ring: 21 images"

# Menu icon for the Floating main menu card header: three rounded cyan lines (hamburger).
$s = 40; $bmp = New-Object System.Drawing.Bitmap $s, $s, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = "AntiAlias"; $g.Clear((C "#0F131B"))
$p = New-Object System.Drawing.Pen((C "#00F0FF"), 4); $p.StartCap = "Round"; $p.EndCap = "Round"
foreach ($y in 10, 20, 30) { $g.DrawLine($p, 6, $y, 34, $y) }
$bmp.Save((Join-Path $out "..\icons\menu_header.png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
"menu header icon"
