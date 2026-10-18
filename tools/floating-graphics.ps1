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

# Floating channel list (skin_chlist_floating.xml): selected row, same style as the Floating menu (758 x 80).
$bmp = New-Object System.Drawing.Bitmap 758, 80, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.Clear((C "#0F131B"))
$g.FillRectangle((New-Object System.Drawing.SolidBrush (C "#1C2532")), 0, 2, 758, 76)
$g.FillRectangle((New-Object System.Drawing.SolidBrush (C "#00F0FF")), 753, 2, 5, 76)
$bmp.Save((Join-Path $out "sel_chlist_floating.png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
"channel list selection row"

# Obsidian FHD Apps panel (skin_apps.xml): tiles (normal / selected), app icons, Turn on / Turn off buttons.
# Tiles and buttons are opaque on the card colour; icons keep a transparent corner and are blended over the tile.
$apps = Join-Path $out "..\apps"; New-Item -ItemType Directory -Force $apps | Out-Null
foreach ($t in @(@("tile", "#181C23", $null), @("tile_sel", "#1C2532", "#00F0FF"))) {
	$bmp = New-Object System.Drawing.Bitmap 402, 224, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = "AntiAlias"; $g.Clear((C "#0F131B"))
	$g.FillPath((New-Object System.Drawing.SolidBrush (C $t[1])), (RR 1 1 400 222 18))
	if ($t[2]) { $g.DrawPath((New-Object System.Drawing.Pen((C $t[2]), 3)), (RR 2 2 398 220 18)) }
	$bmp.Save((Join-Path $apps "$($t[0]).png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
foreach ($b in @(@("btn_on", "#22C55E"), @("btn_off", "#262A32"))) {
	$bmp = New-Object System.Drawing.Bitmap 240, 64, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = "AntiAlias"; $g.Clear((C "#0F131B"))
	$g.FillPath((New-Object System.Drawing.SolidBrush (C $b[1])), (RR 0 0 239 63 32))
	$bmp.Save((Join-Path $apps "$($b[0]).png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
function AppIcon([string]$name, [scriptblock]$draw) {
	$bmp = New-Object System.Drawing.Bitmap 96, 96, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = "AntiAlias"; $g.Clear([System.Drawing.Color]::Transparent)
	$g.FillPath((New-Object System.Drawing.SolidBrush (C "#0F131B")), (RR 0 0 95 95 24))
	$p = New-Object System.Drawing.Pen((C "#00F0FF"), 4); $p.StartCap = "Round"; $p.EndCap = "Round"
	& $draw $g $p
	$bmp.Save((Join-Path $apps "icon_$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
	# 72 px copy for the grid tiles
	$sm = New-Object System.Drawing.Bitmap 72, 72, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g2 = [System.Drawing.Graphics]::FromImage($sm); $g2.SmoothingMode = "AntiAlias"; $g2.InterpolationMode = "HighQualityBicubic"; $g2.Clear([System.Drawing.Color]::Transparent); $g2.DrawImage($bmp, 0, 0, 72, 72)
	$sm.Save((Join-Path $apps "icon_s_$name.png"), [System.Drawing.Imaging.ImageFormat]::Png); $g2.Dispose(); $sm.Dispose(); $g.Dispose(); $bmp.Dispose()
}
AppIcon "weather" {
	param($g, $p)
	# sun with short rays, partly behind a cloud
	$g.DrawEllipse($p, 24, 22, 26, 26)
	$thin = New-Object System.Drawing.Pen((C "#00F0FF"), 3); $thin.StartCap = "Round"; $thin.EndCap = "Round"
	foreach ($a in 0, 45, 90, 135, 180, 225, 270) { $r = $a * [math]::PI / 180; $g.DrawLine($thin, (37 + 18 * [math]::Cos($r)), (35 - 18 * [math]::Sin($r)), (37 + 24 * [math]::Cos($r)), (35 - 24 * [math]::Sin($r))) }
	$cloud = New-Object System.Drawing.Drawing2D.GraphicsPath
	$cloud.AddEllipse(30, 50, 22, 22); $cloud.AddEllipse(42, 38, 30, 30); $cloud.AddEllipse(60, 50, 22, 22); $cloud.AddRectangle((New-Object System.Drawing.RectangleF(41, 58, 30, 14)))
	$region = New-Object System.Drawing.Region($cloud)
	$g.FillRegion((New-Object System.Drawing.SolidBrush (C "#0F131B")), $region)
	$outline = New-Object System.Drawing.Drawing2D.GraphicsPath
	$outline.AddArc(30, 50, 22, 22, 90, 180); $outline.AddArc(42, 38, 30, 30, 200, 145); $outline.AddArc(60, 50, 22, 22, 270, 180); $outline.CloseFigure()
	$g.DrawPath($p, $outline)
}
AppIcon "bitrate" { param($g, $p) foreach ($i in 0..3) { $h = 14 + $i * 12; $g.FillRectangle((New-Object System.Drawing.SolidBrush (C "#00F0FF")), 22 + $i * 14, 72 - $h, 9, $h) } }
AppIcon "menu" { param($g, $p) foreach ($y in 32, 48, 64) { $g.DrawLine($p, 24, $y, 72, $y) } }
AppIcon "chlist" { param($g, $p) foreach ($y in 32, 48, 64) { $g.FillEllipse((New-Object System.Drawing.SolidBrush (C "#00F0FF")), 22, $y - 4, 8, 8); $g.DrawLine($p, 38, $y, 74, $y) } }
AppIcon "infobar" { param($g, $p) $g.DrawPath($p, (RR 18 50 60 26 6)); $g.DrawLine($p, 26, 50, 70, 50); $thin = New-Object System.Drawing.Pen((C "#00F0FF"), 2); foreach ($a in 0..4) { $x = 30 + $a * 9; $g.DrawLine($thin, $x, 42, ($x - 4 + $a * 2), 30) } }
AppIcon "about" { param($g, $p) $g.DrawEllipse($p, 22, 22, 52, 52); $g.DrawLine($p, 48, 44, 48, 62); $g.FillEllipse((New-Object System.Drawing.SolidBrush (C "#00F0FF")), 45, 31, 6, 6) }
"apps panel: tiles, buttons, 6 icons"

# Apps grid toggle switches (100 x 40, transparent corners, blended over the tile): off (outlined), on (green),
# on but plugin missing (amber). Text inside: ON / OFF.
$swFonts = New-Object System.Drawing.Text.PrivateFontCollection
$swFonts.AddFontFile((Join-Path $PSScriptRoot "..\Obsidian-FHD\fonts\Inter-Bold.ttf" | Resolve-Path))
$swFont = New-Object System.Drawing.Font($swFonts.Families[0], 20, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$swFmt = New-Object System.Drawing.StringFormat; $swFmt.Alignment = "Center"; $swFmt.LineAlignment = "Center"
foreach ($sw in @(@("switch_off", $null, "#FFFFFF", $false), @("switch_on", "#22C55E", "#0B2A18", $true), @("switch_warn", "#FFB800", "#2E2200", $true))) {
	$bmp = New-Object System.Drawing.Bitmap 100, 40, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = "AntiAlias"; $g.TextRenderingHint = "AntiAliasGridFit"; $g.Clear([System.Drawing.Color]::Transparent)
	if ($sw[3]) {
		$g.FillPath((New-Object System.Drawing.SolidBrush (C $sw[1])), (RR 0 0 99 39 19))
		$g.FillEllipse((New-Object System.Drawing.SolidBrush (C "#FFFFFF")), 64, 5, 30, 30)
		$g.DrawString("ON", $swFont, (New-Object System.Drawing.SolidBrush (C $sw[2])), (New-Object System.Drawing.RectangleF(3, 1, 62, 38)), $swFmt)
	} else {
		$g.DrawPath((New-Object System.Drawing.Pen((C "#FFFFFF"), 3)), (RR 2 2 95 35 17))
		$g.FillEllipse((New-Object System.Drawing.SolidBrush (C "#FFFFFF")), 6, 5, 30, 30)
		$g.DrawString("OFF", $swFont, (New-Object System.Drawing.SolidBrush (C "#FFFFFF")), (New-Object System.Drawing.RectangleF(35, 1, 62, 38)), $swFmt)
	}
	$bmp.Save((Join-Path $apps "$($sw[0]).png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
"apps switches"

# Floating settings page (skin_setup_floating.xml): header icons for the settings card and the help card (40 x 40,
# opaque on the card colour like menu_header.png) and the selected row (958 x 60, square like the submenus).
$s = 40
$bmp = New-Object System.Drawing.Bitmap $s, $s, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = "AntiAlias"; $g.Clear((C "#0F131B"))
$p = New-Object System.Drawing.Pen((C "#00F0FF"), 3); $p.StartCap = "Round"; $p.EndCap = "Round"
foreach ($row in @(@(10, 26), @(20, 12), @(30, 22))) {
	$g.DrawLine($p, 5, $row[0], 35, $row[0])
	$g.FillEllipse((New-Object System.Drawing.SolidBrush (C "#0F131B")), ($row[1] - 5), ($row[0] - 5), 10, 10)
	$g.DrawEllipse($p, ($row[1] - 4), ($row[0] - 4), 8, 8)
}
$bmp.Save((Join-Path $out "..\icons\setup_header.png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
$bmp = New-Object System.Drawing.Bitmap $s, $s, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = "AntiAlias"; $g.Clear((C "#0F131B"))
$p = New-Object System.Drawing.Pen((C "#00F0FF"), 3); $p.StartCap = "Round"; $p.EndCap = "Round"
$g.DrawEllipse($p, 4, 4, 32, 32)
$g.DrawArc($p, 14, 11, 12, 11, 180, 230)
$g.DrawLine($p, 20, 22, 20, 25)
$g.FillEllipse((New-Object System.Drawing.SolidBrush (C "#00F0FF")), 18, 28, 4, 4)
$bmp.Save((Join-Path $out "..\icons\help_header.png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
$bmp = New-Object System.Drawing.Bitmap 958, 60, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.Clear((C "#0F131B"))
# same shape as the Floating submenu selection: square lighter row, cyan bar on its right edge (list inset 20 px so values stay clear of the bar)
$g.FillRectangle((New-Object System.Drawing.SolidBrush (C "#1C2532")), 0, 0, 958, 60)
$g.FillRectangle((New-Object System.Drawing.SolidBrush (C "#00F0FF")), 953, 0, 5, 60)
$bmp.Save((Join-Path $out "sel_setup_floating.png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
# Floating option list (ChoiceBox): selected row 598 x 54 (Choicelist row height), square, cyan bar
$bmp = New-Object System.Drawing.Bitmap 598, 54, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.Clear((C "#0F131B"))
# square like the Floating submenu selection
$g.FillRectangle((New-Object System.Drawing.SolidBrush (C "#1C2532")), 0, 0, 598, 54)
$g.FillRectangle((New-Object System.Drawing.SolidBrush (C "#00F0FF")), 593, 0, 5, 54)
$bmp.Save((Join-Path $out "sel_choice_floating.png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
"setup page + option list: 2 header icons + 2 selection rows"

# Infobar light (skin_templates.xml InfoBarTemplate, skin_weather.xml WeatherBadge): solid on the infobar colour #0C1017,
# a thin cyan line along the top edge (brightest in the middle) and a soft glow spreading down from it. Opaque, so it is
# safe over live video; placed inside the bars' rounded corners.
# Bottom image: the full inner height of the panel (277), with two faint diagonal slashes between the top and the
# separator line (y 998), left of the divider (x 1404). Top image: light only.
foreach ($li in @(@("infobar_light.png", 277, 140, $true), @("infobar_light_top.png", 100, 100, $false))) {
	$w = 1812; $h = $li[1]; $gh = $li[2]
	$bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = "AntiAlias"; $g.Clear((C "#0C1017"))
	$hl = New-Object System.Drawing.Drawing2D.GraphicsPath; $hl.AddEllipse(($w / 2 - 760), (-[int]($gh * 0.9)), 1520, [int]($gh * 1.8))
	$pg = New-Object System.Drawing.Drawing2D.PathGradientBrush($hl); $pg.CenterColor = (C "#122127"); $pg.SurroundColors = @((C "#0C1017")); $g.FillPath($pg, $hl)
	$lb = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Point(-1, 0)), (New-Object System.Drawing.Point(($w + 1), 0)), (C "#0C1017"), (C "#0C1017"))
	$cb = New-Object System.Drawing.Drawing2D.ColorBlend 3; $cb.Colors = @((C "#0C1017"), (C "#3E9AA4"), (C "#0C1017")); $cb.Positions = [single[]]@(0, 0.5, 1); $lb.InterpolationColors = $cb
	$g.FillRectangle($lb, 0, 0, $w, 2)
	if ($li[3]) {
		# slashes in image coordinates (image at 54,771): y 21..227 = screen 792 (top of the HD chip) to 998 (the line under the programme), x right edge < 1404 - 54
		$sb = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(9, 255, 255, 255))  # faint white, lighter than glow or bar
		foreach ($dx in 0, 82) {
			$x = 1150 + $dx
			$pts = [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF(($x + 78), 21)), (New-Object System.Drawing.PointF(($x + 130), 21)), (New-Object System.Drawing.PointF(($x + 52), 227)), (New-Object System.Drawing.PointF($x, 227)))
			$g.FillPolygon($sb, $pts)
		}
	}
	$bmp.Save((Join-Path $out "..\icons\$($li[0])"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
"infobar light"

# Signal finder (Satfinder): SNR / AGC bars, 1860 x 75, left-to-right gradient deep enough for white text on top
foreach ($sb in @(@("bar_snr_big.png", "#0A5B63", "#00C2CF"), @("bar_agc_big.png", "#6B4207", "#E0920A"))) {
	$bmp = New-Object System.Drawing.Bitmap 1860, 75, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp)
	$lb = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Point(-1, 0)), (New-Object System.Drawing.Point(1861, 0)), (C $sb[1]), (C $sb[2]))
	$g.FillRectangle($lb, 0, 0, 1860, 75)
	$bmp.Save((Join-Path $out "..\infobar\$($sb[0])"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
"satfinder bars"
