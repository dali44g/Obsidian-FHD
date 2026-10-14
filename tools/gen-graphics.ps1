# Obsidian-FHD graphics generator - "Obsidian Telemetry" design system (from the Stitch prototype).
# Regenerates every themed PNG of the skin from the palette below.
# Usage (Windows PowerShell):  powershell -ExecutionPolicy Bypass -File tools\gen-graphics.ps1 [-Skin <SkinFolder>]
# Change the palette, run again, copy the skin to the box, restart the GUI.
# Other skins: tools\skins\<Skin>.ps1 (if present) overrides the palette and font files after the defaults below.
param([string]$Skin = "Obsidian-FHD")

Add-Type -AssemblyName System.Drawing

$SkinDir = Join-Path $PSScriptRoot "..\$Skin" | Resolve-Path
$Root = Join-Path $PSScriptRoot ".." | Resolve-Path
$MonoFile = "JetBrainsMono-Bold.ttf"; $MonoFamily = "JetBrains*"
$UiFile = "Inter-SemiBold.ttf"; $UiBoldFile = "Inter-Bold.ttf"; $UiFamily = "Inter"; $PillStyle = "pill"

# ---- Palette (keep in sync with <colors> in skin.xml) ----
$C = @{
	bg      = "#05080E"   # Level 0 canvas (OLED black)
	surface = "#0A0E15"   # header / footer
	card    = "#0F131B"   # Level 1 cards
	card2   = "#181C23"   # raised chips
	raised  = "#1C2027"
	line    = "#262A32"   # 1px card borders
	line2   = "#3B494B"   # outline-variant
	accent  = "#00F0FF"   # electric cyan (primary telemetry)
	accentD = "#0891B2"   # cyan muted
	amber   = "#FFB800"   # RF amber (AGC / warnings)
	text    = "#DFE2ED"
	variant = "#B9CACB"
	muted   = "#849495"
	slate   = "#64748B"
	selTint = "#062A33"   # opaque cyan tint over bg (rgba(0,240,255,.12))
	red     = "#EF4444"
	green   = "#22C55E"
	yellow  = "#EAB308"
	blue    = "#3B82F6"
	rec     = "#FF5A5F"
}

$skinProfile = Join-Path $PSScriptRoot "skins\$Skin.ps1"
if (Test-Path $skinProfile) { . $skinProfile }

# Fonts from the skin, so baked labels match the on-screen text.
$Fonts = New-Object System.Drawing.Text.PrivateFontCollection
$Fonts.AddFontFile((Join-Path $SkinDir "fonts\$MonoFile"))
$Fonts.AddFontFile((Join-Path $SkinDir "fonts\$UiFile"))
function MonoFont([float]$px) { New-Object System.Drawing.Font(($Fonts.Families | Where-Object { $_.Name -like $MonoFamily } | Select-Object -First 1), $px, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel) }

function Col([string]$hex, [int]$alpha = 255) {
	$c = [System.Drawing.ColorTranslator]::FromHtml($hex)
	return [System.Drawing.Color]::FromArgb($alpha, $c.R, $c.G, $c.B)
}
function Brush([string]$hex, [int]$alpha = 255) { New-Object System.Drawing.SolidBrush((Col $hex $alpha)) }
function PenOf([string]$hex, [float]$w = 1, [int]$alpha = 255) { New-Object System.Drawing.Pen((Col $hex $alpha), $w) }

function New-Canvas([int]$w, [int]$h) {
	$bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp)
	$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
	$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
	$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
	$g.Clear([System.Drawing.Color]::Transparent)
	return @($bmp, $g)
}

function Save-Canvas($canvas, [string]$rel) {
	$canvas[1].Dispose()
	$path = Join-Path $SkinDir $rel
	New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
	$canvas[0].Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
	$canvas[0].Dispose()
	Write-Host "  $rel"
}

function RoundRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
	$p = New-Object System.Drawing.Drawing2D.GraphicsPath
	if ($r -le 0) { $p.AddRectangle((New-Object System.Drawing.RectangleF($x, $y, $w, $h))); return $p }
	$d = 2 * $r
	$p.AddArc($x, $y, $d, $d, 180, 90)
	$p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
	$p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
	$p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
	$p.CloseFigure()
	return $p
}

function Solid([string]$rel, [int]$w, [int]$h, [string]$hex, [int]$alpha = 255) {
	$cv = New-Canvas $w $h
	$cv[1].Clear((Col $hex $alpha))
	Save-Canvas $cv $rel
}

# Solid cyan progress fill (design: flat cyan bar).
function Bar([string]$rel, [int]$w, [int]$h, [string]$hex = $C.accent) { Solid $rel $w $h $hex }

# Segmented LED meter (design: 10-12 discrete ticks). Track drawn dim, fill bright.
function Segments([string]$rel, [int]$w, [int]$h, [string]$hex, [int]$alpha = 255) {
	$cv = New-Canvas $w $h
	$n = [math]::Floor($w / 20)
	$seg = ($w - ($n - 1) * 4) / $n
	for ($i = 0; $i -lt $n; $i++) {
		$cv[1].FillPath((Brush $hex $alpha), (RoundRect ($i * ($seg + 4)) 0 $seg $h 2))
	}
	Save-Canvas $cv $rel
}

# Status dot with soft phosphor glow.
function GlowDot([string]$rel, [int]$size, [string]$hex, [int]$core) {
	$cv = New-Canvas $size $size
	$c = $size / 2
	$cv[1].FillEllipse((Brush $hex 60), 0, 0, $size, $size)
	$cv[1].FillEllipse((Brush $hex), ($c - $core / 2), ($c - $core / 2), $core, $core)
	Save-Canvas $cv $rel
}

Write-Host "Generating Obsidian graphics into $SkinDir"

# ---- Window border set: Level 1 card, 1px hairline, title strip ----
# Sizes must stay identical (title height 40, edges 10).
foreach ($spec in @(
		@{ f = "window/top_edge.png"; w = 100 },
		@{ f = "window/top_left_corner.png"; w = 15 },
		@{ f = "window/top_right_corner.png"; w = 15 })) {
	$cv = New-Canvas $spec.w 40
	$g = $cv[1]
	$g.Clear((Col $C.card2))
	$g.FillRectangle((Brush $C.line), 0, 0, $spec.w, 1)
	$g.FillRectangle((Brush $C.line), 0, 39, $spec.w, 1)
	if ($spec.f -like "*left*") { $g.FillRectangle((Brush $C.line), 0, 0, 1, 40); $g.FillRectangle((Brush $C.accent), 6, 12, 3, 16) }
	if ($spec.f -like "*right*") { $g.FillRectangle((Brush $C.line), $spec.w - 1, 0, 1, 40) }
	Save-Canvas $cv $spec.f
}
foreach ($spec in @(
		@{ f = "window/left_edge.png"; w = 10; h = 100; lx = 0; ly = 0; lw = 1; lh = 100 },
		@{ f = "window/right_edge.png"; w = 10; h = 100; lx = 9; ly = 0; lw = 1; lh = 100 },
		@{ f = "window/bottom_edge.png"; w = 100; h = 10; lx = 0; ly = 9; lw = 100; lh = 1 },
		@{ f = "window/bottom_left_corner.png"; w = 10; h = 10; lx = 0; ly = 9; lw = 10; lh = 1 },
		@{ f = "window/bottom_right_corner.png"; w = 10; h = 10; lx = 0; ly = 9; lw = 10; lh = 1 })) {
	$cv = New-Canvas $spec.w $spec.h
	$g = $cv[1]
	$g.Clear((Col $C.bg))
	$g.FillRectangle((Brush $C.line), $spec.lx, $spec.ly, $spec.lw, $spec.lh)
	if ($spec.f -eq "window/bottom_left_corner.png") { $g.FillRectangle((Brush $C.line), 0, 0, 1, 10) }
	if ($spec.f -eq "window/bottom_right_corner.png") { $g.FillRectangle((Brush $C.line), 9, 0, 1, 10) }
	Save-Canvas $cv $spec.f
}

# ---- Lines / separators ----
$cv = New-Canvas 1920 3
$cv[1].FillRectangle((Brush $C.line), 0, 1, 1920, 1)
Save-Canvas $cv "border/smallshadowline.png"
Solid "border/line.png" 300 1 $C.line
Solid "border/vline.png" 1 300 $C.line
Solid "border/vsmallshadowline.png" 2 933 $C.line

# Text input field (virtual keyboard / input boxes): inset field with cyan focus ring.
$cv = New-Canvas 974 78
$cv[1].FillPath((Brush $C.bg), (RoundRect 0 0 973 77 8))
$cv[1].DrawPath((PenOf $C.accent 2 160), (RoundRect 1 1 971 75 8))
Save-Canvas $cv "buttons/vkey_text.png"

# ---- Progress bars (flat cyan) ----
Bar "infobar/pbar.png" 1380 12
Bar "infobar/pbargmepg.png" 1110 12
Bar "window/progress.png" 600 15
Bar "window/sprogress.png" 129 18
Bar "progress_big.png" 840 24
Bar "progress_medium.png" 840 18
Bar "progress_small.png" 840 12
Bar "infobar/pbar_amber.png" 600 12 $C.amber

# ---- Signal meters (SNR / AGC): solid rounded bars ----
# Sized to the widget width: Pixmap/Progress crop instead of scaling, so a wider image would lose its right end.
function Pill([string]$rel, [int]$w, [int]$h, [string]$hex) {
	$cv = New-Canvas $w $h
	$cv[1].FillPath((Brush $hex), (RoundRect 0 0 $w $h ($h / 2)))
	Save-Canvas $cv $rel
}
Pill "infobar/seg_snr.png" 260 10 $C.accent
Pill "infobar/seg_agc.png" 260 10 $C.amber
Pill "infobar/seg_track.png" 260 10 $C.line
Pill "infobar/seg_snr280.png" 280 10 $C.accent
Pill "infobar/seg_track280.png" 280 10 $C.line
Segments "infobar/pbar_grey.png" 300 30 $C.accent

# Volume
$cv = New-Canvas 30 300
$cv[1].FillRectangle((Brush $C.accent), 0, 0, 30, 300)
Save-Canvas $cv "infobar/volumeslider.png"
Segments "infobar/volumeslider_h.png" 300 10 $C.accent

# ---- Seek bar (PositionGauge) ----
# The pointer image is the filled part plus a knob; enigma2 slides it along,
# so width = track width + knob (18) and the skin passes "<track>,4" as offset.
function SeekTrack([string]$rel, [int]$w) {
	$cv = New-Canvas $w 12
	$cv[1].FillPath((Brush $C.line), (RoundRect 0 3 ($w - 1) 6 2))
	Save-Canvas $cv $rel
}
function SeekPointer([string]$rel, [int]$track) {
	$w = $track + 18
	$cv = New-Canvas $w 18
	$g = $cv[1]
	$g.FillRectangle((Brush $C.accent), 0, 6, $track + 9, 6)
	$g.FillEllipse((Brush $C.accent 70), $track, 0, 18, 18)
	$g.FillEllipse((Brush "#FFFFFF"), $track + 4, 4, 10, 10)
	Save-Canvas $cv $rel
}
SeekTrack "dvr/scale1024.png" 1536
SeekPointer "dvr/position_pointer1024.png" 1536
SeekPointer "dvr/position_pointer1.png" 720

# ---- Backdrops ----
foreach ($f in @("infobar/hd.png", "infobar/bl80.png")) {
	$cv = New-Canvas 1920 330
	$rect = New-Object System.Drawing.Rectangle(0, 0, 1920, 330)
	$blend = New-Object System.Drawing.Drawing2D.ColorBlend(3)
	$blend.Colors = @((Col $C.bg 0), (Col $C.bg 190), (Col $C.bg 245))
	$blend.Positions = @(0.0, 0.45, 1.0)
	$br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, (Col $C.bg 0), (Col $C.bg 245), 90.0)
	$br.InterpolationColors = $blend
	$cv[1].FillRectangle($br, $rect)
	Save-Canvas $cv $f
}
# ---- Status dots ----
foreach ($k in @("red", "green", "yellow", "blue")) {
	GlowDot "buttons/$k.png" 34 $C[$k] 12
	GlowDot "buttons/${k}30.png" 30 $C[$k] 10
}
GlowDot "buttons/grey.png" 34 $C.slate 12
GlowDot "buttons/rec.png" 30 $C.rec 14
GlowDot "icons/dot_cyan.png" 20 $C.accent 8
GlowDot "icons/dot_red.png" 20 $C.rec 10

# ---- 4-colour action strip pills (design component #1) ----
# Dark glass pill, 1px accent border, glowing dot, mono "RED" tag. The key text
# itself is drawn by the skin next to the tag.
foreach ($k in @("red", "green", "yellow", "blue")) {
	$cv = New-Canvas 400 44
	$g = $cv[1]
	if ($PillStyle -eq "dot") {  # dot style: no box, a coloured dot just before the key text
		$g.FillEllipse((Brush $C[$k]), 74, 15, 14, 14)
		Save-Canvas $cv "buttons/pill_$k.png"; continue
	}
	$g.FillPath((Brush $C.card), (RoundRect 0.5 0.5 399 43 6))
	$g.DrawPath((PenOf $C[$k] 1 150), (RoundRect 0.5 0.5 399 43 6))
	$g.FillEllipse((Brush $C[$k] 70), 10, 12, 20, 20)
	$g.FillEllipse((Brush $C[$k]), 15, 17, 10, 10)
	$g.DrawString($k.ToUpper(), (MonoFont 17), (Brush $C.text), 34, 11)
	Save-Canvas $cv "buttons/pill_$k.png"
}

# ---- Remote key chips (MENU, INFO, OK ... ) 53x38 ----
$keys = [ordered]@{
	"key_0" = "0"; "key_1" = "1"; "key_2" = "2"; "key_3" = "3"; "key_4" = "4"; "key_5" = "5"; "key_6" = "6"; "key_7" = "7"; "key_8" = "8"; "key_9" = "9"
	"key_audio" = "AUD"; "key_channel" = "CH"; "key_exit" = "EXIT"; "key_f1" = "F1"; "key_f2" = "F2"; "key_f3" = "F3"; "key_help" = "HELP"
	"key_info" = "INFO"; "key_left" = "<"; "key_menu" = "MENU"; "key_next" = ">>"; "key_ok" = "OK"; "key_prev" = "<<"; "key_prevnext" = "<>"
	"key_radio" = "RAD"; "key_right" = ">"; "key_text" = "TXT"; "key_tv" = "TV"; "key_video" = "PVR"
}
foreach ($k in $keys.Keys) {
	$cv = New-Canvas 53 38
	$g = $cv[1]
	$g.FillPath((Brush $C.raised), (RoundRect 2 5 49 28 4))
	$g.DrawPath((PenOf $C.line2 1), (RoundRect 2 5 49 28 4))
	$sf = New-Object System.Drawing.StringFormat; $sf.Alignment = "Center"; $sf.LineAlignment = "Center"
	$size = if ($keys[$k].Length -ge 4) { 12 } else { 14 }
	$g.DrawString($keys[$k], (MonoFont $size), (Brush $C.text), (New-Object System.Drawing.RectangleF(2, 5, 49, 28)), $sf)
	Save-Canvas $cv "buttons/$k.png"
}
foreach ($k in @("red", "green", "yellow", "blue")) {
	$cv = New-Canvas 53 38
	$g = $cv[1]
	$g.FillPath((Brush $C.raised), (RoundRect 2 5 49 28 4))
	$g.DrawPath((PenOf $C[$k] 1 170), (RoundRect 2 5 49 28 4))
	$g.FillEllipse((Brush $C[$k]), 21, 13, 12, 12)
	Save-Canvas $cv "buttons/key_$k.png"
}


# ---- EPG NOW/NEXT/MORE tabs ----
foreach ($t in @(@{ f = "border/epg_off.png"; fill = $C.card2; edge = $C.line }, @{ f = "border/epg_now_on.png"; fill = $C.selTint; edge = $C.accent }, @{ f = "border/epg_next_on.png"; fill = $C.selTint; edge = $C.accent })) {
	$cv = New-Canvas 225 50
	$cv[1].FillPath((Brush $t.fill), (RoundRect 1 1 222 47 6))
	$cv[1].DrawPath((PenOf $t.edge 1.5), (RoundRect 1 1 222 47 6))
	Save-Canvas $cv $t.f
}

# ---- EPG timeline markers ----
$cv = New-Canvas 8 826
$cv[1].FillRectangle((Brush $C.line), 3, 0, 1, 826)
Save-Canvas $cv "window/timeline.png"
$cv = New-Canvas 28 826
$cv[1].FillRectangle((Brush $C.rec), 13, 0, 2, 826)
$cv[1].FillPolygon((Brush $C.rec), [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF(6, 0)), (New-Object System.Drawing.PointF(22, 0)), (New-Object System.Drawing.PointF(14, 10))))
Save-Canvas $cv "window/timeline-now.png"

# ---- Mute badge / speaker icon ----
$cv = New-Canvas 45 45
$g = $cv[1]
$g.FillPath((Brush $C.card), (RoundRect 0.5 0.5 44 44 8))
$g.DrawPath((PenOf $C.rec 1 160), (RoundRect 0.5 0.5 44 44 8))
$sp = New-Object System.Drawing.Drawing2D.GraphicsPath
$sp.AddPolygon([System.Drawing.PointF[]]@(
		(New-Object System.Drawing.PointF(10, 18)), (New-Object System.Drawing.PointF(16, 18)),
		(New-Object System.Drawing.PointF(23, 11)), (New-Object System.Drawing.PointF(23, 34)),
		(New-Object System.Drawing.PointF(16, 27)), (New-Object System.Drawing.PointF(10, 27))))
$g.FillPath((Brush $C.text), $sp)
$pen = PenOf $C.rec 3
$pen.StartCap = $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawLine($pen, 27, 17, 35, 28)
$g.DrawLine($pen, 35, 17, 27, 28)
Save-Canvas $cv "infobar/mute.png"

$cv = New-Canvas 30 24
$g = $cv[1]
$sp = New-Object System.Drawing.Drawing2D.GraphicsPath
$sp.AddPolygon([System.Drawing.PointF[]]@(
		(New-Object System.Drawing.PointF(2, 8)), (New-Object System.Drawing.PointF(7, 8)),
		(New-Object System.Drawing.PointF(13, 2)), (New-Object System.Drawing.PointF(13, 22)),
		(New-Object System.Drawing.PointF(7, 16)), (New-Object System.Drawing.PointF(2, 16))))
$g.FillPath((Brush $C.accent), $sp)
$g.DrawArc((PenOf $C.accent 2), 10, 6, 10, 12, -60, 120)
$g.DrawArc((PenOf $C.accent 2), 10, 2, 16, 20, -60, 120)
Save-Canvas $cv "infobar/vol_box.png"

# ---- Logo (from the Stitch prototype's enigma2_logo) ----
$logoSrc = Join-Path $Root "stitch_enigma2_comprehensive_ui_skin\enigma2_logo\screen.png"
if (Test-Path $logoSrc) {
	$src = [System.Drawing.Image]::FromFile($logoSrc)
	foreach ($s in @(@{ f = "icons/logo_small.png"; n = 56 }, @{ f = "icons/logo_big.png"; n = 220 })) {
		$cv = New-Canvas $s.n $s.n
		$cv[1].InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
		$cv[1].DrawImage($src, 0, 0, $s.n, $s.n)
		Save-Canvas $cv $s.f
	}
	# Floating menu footer (44 px on the card): the logo's own dark square repainted in the card colour, opaque.
	$cv = New-Canvas 44 44
	$cv[1].Clear((Col $C.card))
	$cv[1].InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
	$cv[1].DrawImage($src, 0, 0, 44, 44)
	$bmp = $cv[0]; $card = Col $C.card
	for ($y = 0; $y -lt 44; $y++) { for ($x = 0; $x -lt 44; $x++) {
		$p = $bmp.GetPixel($x, $y)
		if ([math]::Max([math]::Max($p.R, $p.G), $p.B) -lt 34) { $bmp.SetPixel($x, $y, $card) }
	} }
	Save-Canvas $cv "icons/logo_card.png"
	$src.Dispose()
}


# =====================================================================
# Icon set (flat Obsidian style). Same file names and sizes as the base
# skin, so every screen and Python list that loads them picks them up.
# =====================================================================
$Fonts.AddFontFile((Join-Path $SkinDir "fonts\$UiBoldFile"))
function InterFont([float]$px) { New-Object System.Drawing.Font(($Fonts.Families | Where-Object { $_.Name -eq $UiFamily } | Select-Object -First 1), $px, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel) }
function Centered() { $sf = New-Object System.Drawing.StringFormat; $sf.Alignment = "Center"; $sf.LineAlignment = "Center"; return $sf }
function RoundPen([string]$hex, [float]$w, [int]$alpha = 255) {
	$p = PenOf $hex $w $alpha
	$p.StartCap = $p.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
	$p.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
	return $p
}
function PF([float]$x, [float]$y) { New-Object System.Drawing.PointF($x, $y) }

# Mono text chip (badges, sort modes, tuner types).
function Chip([string]$rel, [int]$w, [int]$h, [string]$text, [string]$fg = $C.text, [string]$edge = $C.line2, [string]$fill = $C.bg, [float]$size = 0) {
	$cv = New-Canvas $w $h
	$g = $cv[1]
	$r = [math]::Min(5, $h / 4)
	$g.FillPath((Brush $fill), (RoundRect 1 1 ($w - 2) ($h - 2) $r))
	$g.DrawPath((PenOf $edge 1.2), (RoundRect 1 1 ($w - 2) ($h - 2) $r))
	if ($size -le 0) { $size = [math]::Min($h * 0.5, ($w - 6) / [math]::Max(1, $text.Length) * 1.55) }
	$g.DrawString($text, (MonoFont $size), (Brush $fg), (New-Object System.Drawing.RectangleF(0, 1, $w, $h)), (Centered))
	Save-Canvas $cv $rel
}

# Selected-row marker for every list (tiled vertically by enigma2).
$cv = New-Canvas 4 8
$cv[1].Clear((Col $C.accent))
Save-Canvas $cv "window/sel_bar.png"

# ---- MessageBox icons 80x80: card with coloured ring + glyph ----
function MsgIcon([string]$rel, [string]$hex, [string]$kind) {
	$cv = New-Canvas 80 80
	$g = $cv[1]
	$g.FillPath((Brush $C.card2), (RoundRect 1 1 78 78 12))
	$g.DrawPath((PenOf $C.line 1), (RoundRect 1 1 78 78 12))
	$g.FillEllipse((Brush $hex 40), 14, 14, 52, 52)
	$g.DrawEllipse((PenOf $hex 3), 15.5, 15.5, 49, 49)
	switch ($kind) {
		"x" { $p = RoundPen $hex 5; $g.DrawLine($p, 31, 31, 49, 49); $g.DrawLine($p, 49, 31, 31, 49) }
		"i" { $g.FillEllipse((Brush $hex), 36.5, 26, 7, 7); $g.DrawLine((RoundPen $hex 6), 40, 38, 40, 53) }
		"!" { $g.DrawLine((RoundPen $hex 6), 40, 27, 40, 44); $g.FillEllipse((Brush $hex), 36.5, 49, 7, 7) }
		"?" { $g.DrawString("?", (InterFont 34), (Brush $hex), (New-Object System.Drawing.RectangleF(14, 15, 52, 52)), (Centered)) }
	}
	Save-Canvas $cv $rel
}
MsgIcon "icons/input_error.png" $C.red "x"
MsgIcon "icons/input_info.png" $C.accent "i"
MsgIcon "icons/input_question.png" $C.accent "?"
MsgIcon "icons/input_warning.png" $C.amber "!"

# ---- Checkboxes (SelectionList / multi file lists) ----
function CheckBox([string]$rel, [int]$w, [int]$h, [string]$state) {
	$cv = New-Canvas $w $h
	$g = $cv[1]
	$s = [math]::Min($w, $h) - 8; $x = ($w - $s) / 2; $y = ($h - $s) / 2
	switch ($state) {
		"on" {
			$g.FillPath((Brush $C.accent), (RoundRect $x $y $s $s 5))
			$p = RoundPen $C.bg 3.2
			$g.DrawLines($p, [System.Drawing.PointF[]]@((PF ($x + $s * 0.24) ($y + $s * 0.52)), (PF ($x + $s * 0.43) ($y + $s * 0.70)), (PF ($x + $s * 0.77) ($y + $s * 0.32))))
		}
		"off" { $g.FillPath((Brush $C.bg), (RoundRect $x $y $s $s 5)); $g.DrawPath((PenOf $C.line2 2), (RoundRect $x $y $s $s 5)) }
		"error" {
			$g.DrawPath((PenOf $C.red 2), (RoundRect $x $y $s $s 5))
			$p = RoundPen $C.red 3; $g.DrawLine($p, $x + $s * 0.3, $y + $s * 0.3, $x + $s * 0.7, $y + $s * 0.7); $g.DrawLine($p, $x + $s * 0.7, $y + $s * 0.3, $x + $s * 0.3, $y + $s * 0.7)
		}
	}
	Save-Canvas $cv $rel
}
CheckBox "icons/lock_on.png" 38 36 "on"
CheckBox "icons/lock_off.png" 38 36 "off"
CheckBox "icons/lock_error.png" 38 36 "error"
$cv = New-Canvas 36 35
$cv[1].DrawLines((RoundPen $C.accent 4), [System.Drawing.PointF[]]@((PF 8 18), (PF 15 25), (PF 28 10)))
Save-Canvas $cv "icons/mark_select.png"

# Parental-control padlock.
function Padlock([string]$rel, [int]$w, [int]$h, [string]$hex) {
	$cv = New-Canvas $w $h
	$g = $cv[1]
	$bw = $w * 0.62; $bh = $h * 0.42; $bx = ($w - $bw) / 2; $by = $h * 0.46
	$g.DrawArc((PenOf $hex ([math]::Max(2, $w * 0.08))), ($w * 0.32), ($h * 0.16), ($w * 0.36), ($h * 0.5), 180, 180)
	$g.DrawLine((PenOf $hex ([math]::Max(2, $w * 0.08))), ($w * 0.32), ($h * 0.41), ($w * 0.32), $by)
	$g.DrawLine((PenOf $hex ([math]::Max(2, $w * 0.08))), ($w * 0.68), ($h * 0.41), ($w * 0.68), $by)
	$g.FillPath((Brush $hex), (RoundRect $bx $by $bw $bh 3))
	$g.FillEllipse((Brush $C.bg), ($w / 2 - 2.5), ($by + $bh * 0.35), 5, 5)
	Save-Canvas $cv $rel
}
Padlock "icons/lock.png" 42 44 $C.amber
Padlock "icons/icon_crypt.png" 18 24 $C.amber

# ---- File-type icons ----
function Folder([string]$rel, [int]$s, [string]$hex) {
	$cv = New-Canvas $s $s
	$g = $cv[1]
	$p = New-Object System.Drawing.Drawing2D.GraphicsPath
	$p.AddPolygon([System.Drawing.PointF[]]@((PF ($s * 0.08) ($s * 0.22)), (PF ($s * 0.40) ($s * 0.22)), (PF ($s * 0.50) ($s * 0.32)), (PF ($s * 0.92) ($s * 0.32)), (PF ($s * 0.92) ($s * 0.82)), (PF ($s * 0.08) ($s * 0.82))))
	$g.FillPath((Brush $hex 230), $p)
	$g.FillRectangle((Brush $C.bg 80), ($s * 0.08), ($s * 0.40), ($s * 0.84), 1.5)
	Save-Canvas $cv $rel
}
Folder "extensions/directory.png" 30 $C.amber
# Bouquet (channel list folder): dark tile with a stack of cyan "channel rows".
function BouquetIcon([string]$rel, [int]$s, [int]$padLeft = 0) {
	# padLeft: transparent space on the left. The channel list draws folder icons at x=0 of the
	# row (under the selection bar) and offers no skin margin for them, so the gap lives in the image.
	$cv = New-Canvas ($s + $padLeft) $s; $g = $cv[1]; $g.TranslateTransform($padLeft, 0)
	$m = [Math]::Max(1, $s * 0.04)
	$g.FillPath((Brush $C.raised), (RoundRect $m $m ($s - 2 * $m) ($s - 2 * $m) ($s * 0.22)))
	$g.DrawPath((PenOf $C.line2 ([Math]::Max(1, $s / 38))), (RoundRect $m $m ($s - 2 * $m) ($s - 2 * $m) ($s * 0.22)))
	$x = $s * 0.24; $w = $s * 0.52; $h = $s * 0.1
	$alphas = @(255, 170, 95)
	for ($i = 0; $i -lt 3; $i++) {
		$y = $s * (0.28 + 0.17 * $i)
		$g.FillEllipse((Brush $C.accent $alphas[$i]), $x, $y, $h, $h)
		$g.FillPath((Brush $C.accent $alphas[$i]), (RoundRect ($x + $h * 1.6) $y ($w - $h * 1.6) $h ($h / 2)))
	}
	Save-Canvas $cv $rel
}
BouquetIcon "icons/folder.png" 38 18
BouquetIcon "icons/folder_big.png" 96
# Bouquet marker (section divider inside a bouquet).
$cv = New-Canvas 56 38; $cv[1].FillPath((Brush $C.amber), (RoundRect 24 16 26 6 3)); Save-Canvas $cv "icons/marker.png"

$cv = New-Canvas 30 30; $g = $cv[1]
$g.FillPath((Brush $C.accentD), (RoundRect 3 6 24 18 3))
foreach ($yy in @(8, 19)) { foreach ($xx in @(5, 10, 15, 20)) { $g.FillRectangle((Brush $C.bg), $xx, $yy, 3, 2) } }
$g.FillPolygon((Brush $C.text), [System.Drawing.PointF[]]@((PF 13 11.5), (PF 19 15), (PF 13 18.5)))
Save-Canvas $cv "extensions/movie.png"

$cv = New-Canvas 30 30; $g = $cv[1]
$g.FillEllipse((Brush $C.accent), 6, 18, 8, 7); $g.FillEllipse((Brush $C.accent), 17, 16, 8, 7)
$g.DrawLine((PenOf $C.accent 2.2), 13, 21, 13, 7); $g.DrawLine((PenOf $C.accent 2.2), 24, 19, 24, 5)
$g.DrawLine((PenOf $C.accent 3), 13, 7, 24, 5)
Save-Canvas $cv "extensions/music.png"

$cv = New-Canvas 30 30; $g = $cv[1]
$g.DrawPath((PenOf $C.variant 2), (RoundRect 4 6 22 18 3))
$g.FillPolygon((Brush $C.accent), [System.Drawing.PointF[]]@((PF 6 22), (PF 12 14), (PF 16 19), (PF 19 16), (PF 24 22)))
$g.FillEllipse((Brush $C.amber), 18, 9, 4, 4)
Save-Canvas $cv "extensions/picture.png"

# Default plugin tile (shown when a plugin has no own icon).
$cv = New-Canvas 150 60; $g = $cv[1]
$g.FillPath((Brush $C.card2), (RoundRect 1 1 148 58 8)); $g.DrawPath((PenOf $C.line2 1), (RoundRect 1 1 148 58 8))
$g.FillPath((Brush $C.accent), (RoundRect 18 20 22 20 4))
$g.DrawLine((RoundPen $C.accent 3), 23, 20, 23, 13); $g.DrawLine((RoundPen $C.accent 3), 35, 20, 35, 13)
$g.DrawLine((RoundPen $C.accent 3), 29, 40, 29, 47)
$g.DrawString("PLUGIN", (MonoFont 18), (Brush $C.variant), 52, 19)
Save-Canvas $cv "icons/plugin.png"

# ---- Tree / expandable list markers ----
function Chevron([string]$rel, [int]$w, [int]$h, [string]$dir, [string]$hex, [float]$s) {
	$cv = New-Canvas $w $h; $g = $cv[1]
	$cx = $w / 2; $cy = $h / 2; $p = RoundPen $hex ([math]::Max(2.5, $s / 4))
	if ($dir -eq "right") { $g.DrawLines($p, [System.Drawing.PointF[]]@((PF ($cx - $s / 4) ($cy - $s / 2)), (PF ($cx + $s / 4) $cy), (PF ($cx - $s / 4) ($cy + $s / 2)))) }
	elseif ($dir -eq "left") { $g.DrawLines($p, [System.Drawing.PointF[]]@((PF ($cx + $s / 4) ($cy - $s / 2)), (PF ($cx - $s / 4) $cy), (PF ($cx + $s / 4) ($cy + $s / 2)))) }
	else { $g.DrawLines($p, [System.Drawing.PointF[]]@((PF ($cx - $s / 2) ($cy - $s / 4)), (PF $cx ($cy + $s / 4)), (PF ($cx + $s / 2) ($cy - $s / 4)))) }
	Save-Canvas $cv $rel
}
Chevron "icons/expandable.png" 45 38 "right" $C.muted 14
Chevron "icons/expanded.png" 45 38 "down" $C.accent 14
Chevron "icons/expandable-plugins.png" 91 76 "right" $C.muted 24
Chevron "icons/expanded-plugins.png" 91 76 "down" $C.accent 24
Chevron "buttons/left.png" 34 34 "left" $C.accent 14
Chevron "buttons/right.png" 34 34 "right" $C.accent 14
$cv = New-Canvas 45 38; $cv[1].FillRectangle((Brush $C.line2), 22, 0, 1, 38); Save-Canvas $cv "icons/verticalline.png"
$cv = New-Canvas 91 76; $cv[1].FillRectangle((Brush $C.line2), 45, 0, 1, 76); Save-Canvas $cv "icons/verticalline-plugins.png"
$cv = New-Canvas 52 38; $cv[1].FillEllipse((Brush $C.accent), 21, 14, 10, 10); Save-Canvas $cv "icons/bullet.png"

# ---- Infobar / list technical badges ----
Chip "infobar/ico_dolby_on.png" 50 32 "DD" $C.text
Chip "infobar/ico_format_16_9.png" 60 32 "16:9" $C.text
Chip "infobar/ico_format_4_3.png" 60 32 "4:3" $C.text
Chip "infobar/ico_format_hd.png" 60 32 "HD" $C.text
Chip "infobar/ico_format_4k.png" 60 32 "4K" $C.amber $C.amber "#332500"
Chip "infobar/ico_hbbtv_on.png" 70 32 "HBBTV" $C.text
Chip "infobar/ico_pdc.png" 58 32 "PDC" $C.text
Chip "infobar/ico_sub_on.png" 50 32 "SUB" $C.text
Chip "infobar/ico_txt_on.png" 50 32 "TXT" $C.text
Padlock "infobar/ico_crypt_on.png" 24 32 $C.amber
Chip "icons/ico_dvb_s-fs8.png" 36 36 "S" $C.accent $C.accentD
Chip "icons/ico_dvb_c-fs8.png" 36 36 "C" $C.accent $C.accentD
Chip "icons/ico_dvb_t-fs8.png" 36 36 "T" $C.accent $C.accentD
Chip "icons/ico_stream-fs8.png" 36 36 "IP" $C.accent $C.accentD
Chip "icons/scan-s.png" 96 96 "DVB-S" $C.accent $C.accentD $C.card2 20
Chip "icons/scan-c.png" 96 96 "DVB-C" $C.accent $C.accentD $C.card2 20
Chip "icons/scan-t.png" 96 96 "DVB-T" $C.accent $C.accentD $C.card2 20

# Sort / play-mode chips (movie list, media player).
$modes = [ordered]@{ "ask" = "?"; "az" = "A-Z"; "za" = "Z-A"; "default" = "DEF"; "faz" = "fAZ"; "fza" = "fZA"; "loop" = "LOOP"; "movielist" = "LIST"; "newtop" = "NEW"; "oldtop" = "OLD"; "pause" = "II"; "playlist" = "PLS"; "playlistquit" = "QUIT"; "quit" = "QUIT"; "rep" = "REP"; "shuffle" = "SHUF" }
foreach ($k in $modes.Keys) { Chip "icons/$k.png" 45 25 $modes[$k] $C.variant $C.line2 $C.card2 11 }

# ---- Timer state icons 30x30 ----
function Badge([string]$rel, [int]$s, [string]$hex, [string]$text, [bool]$filled = $false) {
	$cv = New-Canvas $s $s; $g = $cv[1]
	if ($filled) { $g.FillEllipse((Brush $hex), 2, 2, $s - 4, $s - 4) } else { $g.FillEllipse((Brush $hex 45), 2, 2, $s - 4, $s - 4); $g.DrawEllipse((PenOf $hex 2), 3, 3, $s - 6, $s - 6) }
	if ($text) { $g.DrawString($text, (MonoFont ($s * 0.46)), (Brush $(if ($filled) { $C.bg } else { $hex })), (New-Object System.Drawing.RectangleF(0, 1, $s, $s)), (Centered)) }
	Save-Canvas $cv $rel
}
Badge "icons/timer_autotimer.png" 30 $C.accent "A"
Badge "icons/timer_pip.png" 30 $C.accent "P"
Badge "icons/timer_zap.png" 30 $C.accent "Z"
Badge "icons/timer_rep.png" 30 $C.amber "R"
Badge "icons/timer_prep.png" 30 $C.amber "~"
Badge "icons/timer_wait.png" 30 $C.accentD ""
Badge "icons/timer_off.png" 30 $C.slate ""
Badge "icons/timer_rec.png" 30 $C.rec "" $true
$cv = New-Canvas 30 30; $g = $cv[1]; $g.FillEllipse((Brush $C.green 45), 2, 2, 26, 26); $g.DrawEllipse((PenOf $C.green 2), 3, 3, 24, 24); $g.DrawLines((RoundPen $C.green 2.6), [System.Drawing.PointF[]]@((PF 9 15.5), (PF 13.5 20), (PF 21 10.5))); Save-Canvas $cv "icons/timer_done.png"
$cv = New-Canvas 21 21; $cv[1].FillEllipse((Brush $C.rec 70), 0, 0, 21, 21); $cv[1].FillEllipse((Brush $C.rec), 5, 5, 11, 11); Save-Canvas $cv "icons/record.png"

# ---- Recordings: play state + watched progress ----
$cv = New-Canvas 30 30; $cv[1].FillPolygon((Brush $C.accent), [System.Drawing.PointF[]]@((PF 10 7), (PF 23 15), (PF 10 23))); Save-Canvas $cv "icons/movie_play.png"
$cv = New-Canvas 30 30; $cv[1].FillPolygon((Brush $C.accent), [System.Drawing.PointF[]]@((PF 8 7), (PF 21 15), (PF 8 23))); $cv[1].FillEllipse((Brush $C.rec), 19, 3, 9, 9); Save-Canvas $cv "icons/movie_play_rec.png"
for ($q = 0; $q -le 4; $q++) {
	$cv = New-Canvas 30 30; $g = $cv[1]
	$g.DrawEllipse((PenOf $C.line2 3), 5, 5, 20, 20)
	if ($q -gt 0) { $g.DrawArc((PenOf $C.accent 3), 5, 5, 20, 20, -90, 90 * $q) }
	Save-Canvas $cv "icons/part_${q}_4.png"
}
$cv = New-Canvas 30 30; $cv[1].FillEllipse((Brush $C.accent 60), 5, 5, 20, 20); $cv[1].FillEllipse((Brush $C.accent), 10, 10, 10, 10); Save-Canvas $cv "icons/part_new.png"
$cv = New-Canvas 30 30; $cv[1].DrawEllipse((PenOf $C.line2 3), 5, 5, 20, 20); Save-Canvas $cv "icons/part_unwatched.png"

$cv = New-Canvas 34 36; $g = $cv[1]; $p = RoundPen $C.muted 2.4
$g.DrawLine($p, 7, 10, 27, 10); $g.DrawLine($p, 14, 6, 20, 6); $g.DrawPath($p, (RoundRect 10 10 14 20 2)); $g.DrawLine($p, 15, 15, 15, 25); $g.DrawLine($p, 19, 15, 19, 25)
Save-Canvas $cv "icons/trashcan.png"

# ---- Media transport glyphs 24x24 ----
$cv = New-Canvas 24 24; $cv[1].FillPolygon((Brush $C.text), [System.Drawing.PointF[]]@((PF 7 4), (PF 20 12), (PF 7 20))); Save-Canvas $cv "icons/ico_mp_play.png"
$cv = New-Canvas 24 24; $cv[1].FillPath((Brush $C.text), (RoundRect 5 4 5 16 1)); $cv[1].FillPath((Brush $C.text), (RoundRect 14 4 5 16 1)); Save-Canvas $cv "icons/ico_mp_pause.png"
$cv = New-Canvas 24 24; $cv[1].FillPath((Brush $C.text), (RoundRect 5 5 14 14 2)); Save-Canvas $cv "icons/ico_mp_stop.png"
$cv = New-Canvas 24 24; $cv[1].FillPolygon((Brush $C.text), [System.Drawing.PointF[]]@((PF 3 5), (PF 12 12), (PF 3 19))); $cv[1].FillPolygon((Brush $C.text), [System.Drawing.PointF[]]@((PF 12 5), (PF 21 12), (PF 12 19))); Save-Canvas $cv "icons/ico_mp_forward.png"
$cv = New-Canvas 24 24; $cv[1].FillPolygon((Brush $C.text), [System.Drawing.PointF[]]@((PF 21 5), (PF 12 12), (PF 21 19))); $cv[1].FillPolygon((Brush $C.text), [System.Drawing.PointF[]]@((PF 12 5), (PF 3 12), (PF 12 19))); Save-Canvas $cv "icons/ico_mp_rewind.png"

# Streaming clients indicator.
$cv = New-Canvas 30 30; $g = $cv[1]
$g.FillEllipse((Brush $C.accent), 12, 18, 6, 6)
$g.DrawArc((RoundPen $C.accent 2.4), 8, 13, 14, 14, 220, 100); $g.DrawArc((RoundPen $C.accent 2.4), 3, 7, 24, 24, 220, 100)
Save-Canvas $cv "buttons/stream.png"

# Unhandled key flash.
Chip "icons/unhandled-key.png" 34 45 "!" $C.amber $C.amber "#332500" 22

# ---- Graphical EPG cells (scaled to each cell by GraphMultiEPG) ----
Solid "epg/OtherEvent.png" 8 100 $C.card2
Solid "epg/CurrentEvent.png" 8 100 "#0B2A33"
Solid "epg/SelectedEvent.png" 8 100 "#0E4A57"
Solid "epg/RecordingEvent.png" 8 100 "#3A0D10"
Solid "epg/CurrentService.png" 8 100 $C.selTint
Solid "epg/DisabledEvent.png" 8 100 $C.bg
Solid "epg/BorderTop.png" 8 2 $C.bg
Solid "epg/BorderBottom.png" 8 2 $C.bg
Solid "epg/BorderLeft.png" 2 8 $C.bg
Solid "epg/BorderRight.png" 2 8 $C.bg

# ---- Rating stars 150x30 ----
function Stars([string]$rel, [bool]$filled) {
	$cv = New-Canvas 150 30; $g = $cv[1]
	for ($i = 0; $i -lt 5; $i++) {
		$cx = 15 + $i * 30; $cy = 15; $pts = @()
		for ($k = 0; $k -lt 10; $k++) { $r = $(if ($k % 2 -eq 0) { 12 } else { 5 }); $a = [math]::PI / 5 * $k - [math]::PI / 2; $pts += (PF ($cx + $r * [math]::Cos($a)) ($cy + $r * [math]::Sin($a))) }
		if ($filled) { $g.FillPolygon((Brush $C.amber), [System.Drawing.PointF[]]$pts) } else { $g.DrawPolygon((PenOf $C.line2 1.5), [System.Drawing.PointF[]]$pts) }
	}
	Save-Canvas $cv $rel
}
Stars "dvr/starsbar_empty.png" $false
Stars "dvr/starsbar_filled.png" $true

# ---- Media player slider / misc ----
$cv = New-Canvas 900 24; $cv[1].FillPath((Brush $C.line), (RoundRect 0 9 899 6 2)); Save-Canvas $cv "dvr/mpslider.png"
$cv = New-Canvas 39 24; $cv[1].FillEllipse((Brush $C.accent 70), 10, 3, 18, 18); $cv[1].FillEllipse((Brush "#FFFFFF"), 14, 7, 10, 10); Save-Canvas $cv "dvr/pointer.png"
Solid "window/slider100.png" 1920 9 $C.accent
$cv = New-Canvas 126 11; $cv[1].FillPath((Brush $C.line), (RoundRect 0 3 125 5 2)); Save-Canvas $cv "progress_bg.png"
$cv = New-Canvas 12 27; $cv[1].FillPolygon((Brush $C.accent), [System.Drawing.PointF[]]@((PF 0 0), (PF 12 0), (PF 6 10))); $cv[1].FillRectangle((Brush $C.accent), 5, 10, 2, 17); Save-Canvas $cv "position_arrow.png"
$cv = New-Canvas 285 300; $cv[1].DrawPath((PenOf $C.line2 2), (RoundRect 1 1 283 298 10)); Save-Canvas $cv "icons/pic_frame.png"
$cv = New-Canvas 1860 78; $cv[1].FillPath((Brush $C.card 235), (RoundRect 0.5 0.5 1859 77 10)); $cv[1].DrawPath((PenOf $C.line 1), (RoundRect 0.5 0.5 1859 77 10)); Save-Canvas $cv "infobar/bar_big.png"

# Wizard / media player placeholders.
$cv = New-Canvas 116 116; $g = $cv[1]
$g.FillPath((Brush $C.card2), (RoundRect 0.5 0.5 115 115 10)); $g.DrawPath((PenOf $C.line2 1), (RoundRect 0.5 0.5 115 115 10))
$g.FillEllipse((Brush $C.accent), 34, 66, 20, 16); $g.FillEllipse((Brush $C.accent), 62, 60, 20, 16)
$g.DrawLine((PenOf $C.accent 4), 52, 74, 52, 36); $g.DrawLine((PenOf $C.accent 4), 80, 68, 80, 30); $g.DrawLine((PenOf $C.accent 6), 52, 36, 80, 30)
Save-Canvas $cv "no_coverArt.png"


# ---- Virtual keyboard (69x68 cells = left cap 10 + middle 49 + right cap 10) ----
# Background caps are opaque (drawn without blending) so they include the card colour.
function KeyPart([string]$rel, [string]$part, [string]$fill, [string]$edge, [float]$edgeW, [string]$under) {
	$w = $(if ($part -eq "m") { 49 } else { 10 })
	$cv = New-Canvas $w 68; $g = $cv[1]
	if ($under) { $g.Clear((Col $under)) }
	# draw a full-width key and crop the slice we need
	$full = New-Object System.Drawing.Bitmap(69, 68)
	$fg = [System.Drawing.Graphics]::FromImage($full); $fg.SmoothingMode = "AntiAlias"
	if ($under) { $fg.Clear((Col $under)) }
	if ($fill) { $fg.FillPath((Brush $fill), (RoundRect 3 4 63 60 7)) }
	if ($edge) { $fg.DrawPath((PenOf $edge $edgeW), (RoundRect (3 + $edgeW / 2) (4 + $edgeW / 2) (63 - $edgeW) (60 - $edgeW) 7)) }
	$fg.Dispose()
	$sx = $(switch ($part) { "l" { 0 } "m" { 10 } "r" { 59 } })
	$g.DrawImage($full, (New-Object System.Drawing.Rectangle(0, 0, $w, 68)), (New-Object System.Drawing.Rectangle($sx, 0, $w, 68)), [System.Drawing.GraphicsUnit]::Pixel)
	$full.Dispose()
	Save-Canvas $cv $rel
}
foreach ($p in "l", "m", "r") {
	KeyPart "buttons/vkey_bg_$p.png" $p $C.raised $C.line 1 $C.card
	KeyPart "buttons/vkey_sel_$p.png" $p $null $C.accent 3 $null
	foreach ($k in "red", "green", "yellow", "blue") { KeyPart "buttons/vkey_${k}_$p.png" $p $null $C[$k] 2 $null }
}
function KeyGlyph([string]$rel, [string]$text, [float]$size = 15, [string]$hex = $C.text) {
	$cv = New-Canvas 44 34
	$cv[1].DrawString($text, (MonoFont $size), (Brush $hex), (New-Object System.Drawing.RectangleF(0, 0, 44, 34)), (Centered))
	Save-Canvas $cv $rel
}
KeyGlyph "buttons/vkey_clear.png" "CLR"
KeyGlyph "buttons/vkey_delete.png" "DEL"
KeyGlyph "buttons/vkey_exit.png" "ESC"
KeyGlyph "buttons/vkey_first.png" "|<" 18
KeyGlyph "buttons/vkey_last.png" ">|" 18
KeyGlyph "buttons/vkey_left.png" "<" 22
KeyGlyph "buttons/vkey_right.png" ">" 22
KeyGlyph "buttons/vkey_locale.png" "LANG" 12
KeyGlyph "buttons/vkey_space.png" "SPACE" 12 $C.muted
KeyGlyph "buttons/vkey_space_alt.png" "_" 22 $C.muted
# Backspace: arrow-tag outline with an x.
$cv = New-Canvas 44 34; $g = $cv[1]
$g.DrawPolygon((RoundPen $C.text 2), [System.Drawing.PointF[]]@((PF 4 17), (PF 13 7), (PF 39 7), (PF 39 27), (PF 13 27)))
$g.DrawLine((RoundPen $C.text 2), 21, 12, 30, 22); $g.DrawLine((RoundPen $C.text 2), 30, 12, 21, 22)
Save-Canvas $cv "buttons/vkey_backspace.png"
# Enter: return arrow in cyan.
$cv = New-Canvas 44 34; $g = $cv[1]
$g.DrawLines((RoundPen $C.accent 3), [System.Drawing.PointF[]]@((PF 34 6), (PF 34 20), (PF 10 20)))
$g.FillPolygon((Brush $C.accent), [System.Drawing.PointF[]]@((PF 4 20), (PF 13 13), (PF 13 27)))
Save-Canvas $cv "buttons/vkey_enter.png"
# Shift states: 0 = off, 1 = shift, 2 = caps lock, 3 = alt.
function ShiftGlyph([string]$rel, [string]$hex, [bool]$filled, [string]$extra) {
	$cv = New-Canvas 44 34; $g = $cv[1]
	$pts = [System.Drawing.PointF[]]@((PF 22 4), (PF 35 17), (PF 28 17), (PF 28 27), (PF 16 27), (PF 16 17), (PF 9 17))
	if ($filled) { $g.FillPolygon((Brush $hex), $pts) } else { $g.DrawPolygon((RoundPen $hex 2), $pts) }
	if ($extra) { $g.FillRectangle((Brush $hex), 16, 30, 12, 3) }
	Save-Canvas $cv $rel
}
ShiftGlyph "buttons/vkey_shift.png" $C.text $false ""
ShiftGlyph "buttons/vkey_shift0.png" $C.text $false ""
ShiftGlyph "buttons/vkey_shift1.png" $C.accent $false ""
ShiftGlyph "buttons/vkey_shift2.png" $C.accent $true "caps"
ShiftGlyph "buttons/vkey_shift3.png" $C.amber $true ""
Write-Host "Done."

# Vertical usage bar (Memory info screen).
Solid "window/vslider.png" 8 900 $C.accent
# Vertical volume pill (right edge): fill + track, 10x300
Solid "infobar/volumeslider_v.png" 10 300 $C.accent
Solid "infobar/volumetrack_v.png" 10 300 $C.line2

MsgIcon "icons/input_message.png" $C.slate "i"

# ---- Everyday images that otherwise fall back to the image's skin_default (same sizes) ----
function Dot([string]$rel, [int]$w, [int]$h, [string]$hex, [bool]$filled) {
	$cv = New-Canvas $w $h; $s = [math]::Min($w, $h) - 3
	if ($filled) { $cv[1].FillEllipse((Brush $hex), (($w - $s) / 2), (($h - $s) / 2), $s, $s) }
	else { $cv[1].DrawEllipse((PenOf $hex 1.5), (($w - $s) / 2), (($h - $s) / 2), $s, $s) }
	Save-Canvas $cv $rel
}
function Arrow([string]$rel, [int]$w, [int]$h, [bool]$up, [string]$hex) {
	$cv = New-Canvas $w $h; $cx = $w / 2; $cy = $h / 2; $s = $w * 0.6; $d = if ($up) { -1 } else { 1 }
	$cv[1].DrawLines((RoundPen $hex 3), [System.Drawing.PointF[]]@((PF ($cx - $s / 2) ($cy - $d * $s / 4)), (PF $cx ($cy + $d * $s / 4)), (PF ($cx + $s / 2) ($cy - $d * $s / 4))))
	Save-Canvas $cv $rel
}
function Cross([string]$rel, [int]$s, [string]$hex) {
	$cv = New-Canvas $s $s; $m = $s * 0.25; $p = RoundPen $hex ([math]::Max(2.5, $s / 10))
	$cv[1].DrawLine($p, $m, $m, ($s - $m), ($s - $m)); $cv[1].DrawLine($p, ($s - $m), $m, $m, ($s - $m))
	Save-Canvas $cv $rel
}
function Spinner([int]$i) {
	$cv = New-Canvas 27 27; $g = $cv[1]
	$g.DrawEllipse((PenOf $C.line2 3), 3, 3, 21, 21)
	$g.DrawArc((RoundPen $C.accent 3), 3, 3, 21, 21, ($i * 51 - 90), 100)
	Save-Canvas $cv "spinner/wait$($i + 1).png"
}
function Drive([string]$rel, [int]$w, [int]$h) {
	$cv = New-Canvas $w $h; $g = $cv[1]; $m = [math]::Max(1, $w * 0.1)
	$g.DrawPath((RoundPen $C.accent ([math]::Max(1.5, $w / 22))), (RoundRect $m ($h * 0.15) ($w - 2 * $m) ($h * 0.7) ([math]::Max(2, $w / 10))))
	$g.FillEllipse((Brush $C.amber), ($w - 2 * $m - $w * 0.14), ($h * 0.62), ($w * 0.1), ($w * 0.1))
	Save-Canvas $cv $rel
}
function StreamIcon([string]$rel, [int]$w, [int]$h) {
	$cv = New-Canvas $w $h; $g = $cv[1]; $cx = $w / 2; $cy = $h * 0.62; $p = RoundPen $C.accent ([math]::Max(1.5, $w / 20))
	foreach ($r in @(0.18, 0.34)) { $rr = [math]::Min($w, $h) * $r * 1.6; $g.DrawArc($p, ($cx - $rr), ($cy - $rr), (2 * $rr), (2 * $rr), 225, 90) }
	$d = [math]::Min($w, $h) * 0.16; $g.FillEllipse((Brush $C.accent), ($cx - $d / 2), ($cy - $d / 2), $d, $d)
	Save-Canvas $cv $rel
}
Arrow "arrowup.png" 37 70 $true $C.accent
Arrow "arrowdown.png" 37 70 $false $C.accent
foreach ($k in "red", "green", "yellow", "blue") {
	Dot "buttons/button_$k.png" 15 16 $C[$k] $true
	Dot "buttons/button_${k}_off.png" 15 16 $C.slate $false
}
$cv = New-Canvas 20 20; $cv[1].FillPolygon((Brush $C.accent), [System.Drawing.PointF[]]@((PF 5 3), (PF 17 10), (PF 5 17))); Save-Canvas $cv "buttons/play.png"
Chip "buttons/repeat-on.png" 70 30 "REPEAT" $C.accent $C.accent $C.selTint
Chip "buttons/repeat-off.png" 70 30 "REPEAT" $C.slate $C.line $C.bg
Solid "epg_now.png" 318 25 $C.selTint
Solid "epg_next.png" 318 25 $C.card2
Solid "epg_more.png" 318 25 $C.card
$cv = New-Canvas 14 14; $cv[1].DrawEllipse((PenOf $C.accent 1.5), 1, 1, 12, 12); $cv[1].DrawLines((RoundPen $C.accent 1.5), [System.Drawing.PointF[]]@((PF 7 3.5), (PF 7 7), (PF 9.5 8.5))); Save-Canvas $cv "icons/clock.png"
Drive "icons/hdd.png" 50 60
Drive "icons/hdd24.png" 24 24
StreamIcon "icons/stream.png" 60 50
StreamIcon "icons/stream24.png" 24 24
Chip "icons/icon_rec.png" 34 21 "REC" $C.rec $C.rec "#2A0E10"
Chip "icons/icon_rec_off.png" 34 21 "REC" $C.slate $C.line $C.bg
Padlock "icons/lockBouquet.png" 28 29 $C.amber
Padlock "icons/unlock.png" 28 29 $C.slate
Padlock "icons/unlockBouquet.png" 28 29 $C.slate
Cross "icons/redx.png" 40 $C.rec
Cross "icons/selectioncross.png" 30 $C.accent
GlowDot "nim_active.png" 9 $C.accent 5
GlowDot "yellow_circle23x23.png" 23 $C.yellow 13
Solid "position_pointer.png" 550 10 $C.accent
Segments "volume.png" 214 21 $C.accent
Solid "timeline.png" 1 560 $C.line
$cv = New-Canvas 19 273; $g = $cv[1]; $g.FillRectangle((Brush $C.amber), 8, 8, 3, 265); $g.FillPolygon((Brush $C.amber), [System.Drawing.PointF[]]@((PF 2 0), (PF 17 0), (PF 9.5 10))); Save-Canvas $cv "timeline-now.png"
$cv = New-Canvas 34 45; $g = $cv[1]
$g.FillPolygon((Brush $C.text), [System.Drawing.PointF[]]@((PF 3 17), (PF 9 17), (PF 17 10), (PF 17 35), (PF 9 28), (PF 3 28)))
$p = RoundPen $C.rec 2.5; $g.DrawLine($p, 21, 18, 31, 28); $g.DrawLine($p, 31, 18, 21, 28); Save-Canvas $cv "mute.png"
0..6 | ForEach-Object { Spinner $_ }

# ---- Step 2: network, input devices, small info badges ----
function LineIcon([string]$rel, [int]$s, [string]$hex, [string]$kind) {
	$cv = New-Canvas $s $s; $g = $cv[1]; $k = $s / 48; $p = RoundPen $hex (2.5 * $k)
	switch ($kind) {
		"wired" {
			$g.DrawPath($p, (RoundRect (18 * $k) (8 * $k) (12 * $k) (10 * $k) (2 * $k)))
			$g.DrawPath($p, (RoundRect (6 * $k) (30 * $k) (12 * $k) (10 * $k) (2 * $k)))
			$g.DrawPath($p, (RoundRect (30 * $k) (30 * $k) (12 * $k) (10 * $k) (2 * $k)))
			$g.DrawLine($p, (24 * $k), (18 * $k), (24 * $k), (24 * $k)); $g.DrawLine($p, (12 * $k), (24 * $k), (36 * $k), (24 * $k))
			$g.DrawLine($p, (12 * $k), (24 * $k), (12 * $k), (30 * $k)); $g.DrawLine($p, (36 * $k), (24 * $k), (36 * $k), (30 * $k))
		}
		"wireless" {
			foreach ($r in 8, 15, 22) { $g.DrawArc($p, (24 * $k - $r * $k), (36 * $k - $r * $k), (2 * $r * $k), (2 * $r * $k), 225, 90) }
			$g.FillEllipse((Brush $hex), (21 * $k), (33 * $k), (6 * $k), (6 * $k))
		}
		"keyboard" {
			$g.DrawPath($p, (RoundRect (5 * $k) (13 * $k) (38 * $k) (22 * $k) (4 * $k)))
			foreach ($y in 19, 25) { foreach ($x in 11, 17, 23, 29, 35) { $g.FillRectangle((Brush $hex), ($x * $k), ($y * $k), (2.5 * $k), (2.5 * $k)) } }
			$g.DrawLine($p, (16 * $k), (31 * $k), (32 * $k), (31 * $k))
		}
		"mouse" {
			$g.DrawPath($p, (RoundRect (14 * $k) (8 * $k) (20 * $k) (32 * $k) (10 * $k)))
			$g.DrawLine($p, (24 * $k), (12 * $k), (24 * $k), (19 * $k))
		}
		"rc" {
			$g.DrawPath($p, (RoundRect (16 * $k) (4 * $k) (16 * $k) (40 * $k) (5 * $k)))
			$g.FillEllipse((Brush $C.rec), (21 * $k), (8 * $k), (6 * $k), (6 * $k))
			foreach ($y in 19, 25, 31) { foreach ($x in 20, 26) { $g.FillEllipse((Brush $hex), ($x * $k), ($y * $k), (3 * $k), (3 * $k)) } }
		}
	}
	Save-Canvas $cv $rel
}
foreach ($n in @("wired", "wireless")) {
	LineIcon "icons/network_$n.png" 48 $C.text $n
	LineIcon "icons/network_$n-active.png" 54 $C.accent $n
	LineIcon "icons/network_$n-inactive.png" 54 $C.slate $n
}
foreach ($n in @(@("keyboard", "keyboard"), @("mouse", "mouse"), @("rcnew", "rc"), @("rcold", "rc"))) {
	LineIcon "icons/input_$($n[0]).png" 48 $C.text $n[1]
	LineIcon "icons/input_$($n[0])-configured.png" 54 $C.accent $n[1]
}
Chip "icons/icon_txt.png" 26 16 "TXT" $C.text $C.line2 $C.bg 9
Chip "icons/icon_dolby.png" 26 16 "DD" $C.text $C.line2 $C.bg 9
Chip "icons/icon_format.png" 29 16 "16:9" $C.text $C.line2 $C.bg 8
Chip "icons/icon_view.png" 26 16 "VIEW" $C.text $C.line2 $C.bg 7
Chip "icons/repeat_on.png" 22 15 "R" $C.accent $C.accent $C.selTint 9
Chip "icons/repeat_off.png" 22 15 "R" $C.slate $C.line $C.bg 9
$cv = New-Canvas 15 10; $cv[1].FillPath((Brush $C.amber), (RoundRect 1 2 13 6 3)); Save-Canvas $cv "icons/icon_event.png"
BouquetIcon "icons/ico_service_group-fs8.png" 25
$cv = New-Canvas 119 110; $g = $cv[1]; $p = RoundPen $C.accent 4
$g.DrawArc($p, 10, 10, 80, 80, 45, 180); $g.DrawLine($p, 22, 22, 78, 78); $g.DrawLine($p, 50, 50, 84, 30)
$g.FillEllipse((Brush $C.amber), 80, 24, 12, 12); $g.DrawLine($p, 50, 78, 50, 102); $g.DrawLine($p, 30, 102, 70, 102)
foreach ($r in 12, 22) { $g.DrawArc((RoundPen $C.amber 3), (98 - $r), (18 - $r), (2 * $r), (2 * $r), 100, 70) }
Save-Canvas $cv "icons/dish_scan.png"

# ---- Plugin manager (OpenATV Install Plugins): category tiles and package status badges ----
function CatTile([string]$rel, [bool]$open) {
	$cv = New-Canvas 66 56; $g = $cv[1]
	$fill = if ($open) { $C.selTint } else { $C.card2 }; $edge = if ($open) { $C.accent } else { $C.line2 }
	$g.FillPath((Brush $fill), (RoundRect 6 2 52 52 12)); $g.DrawPath((PenOf $edge 1.5), (RoundRect 6 2 52 52 12))
	$p = RoundPen $C.accent 3.5
	if ($open) { $g.DrawLines($p, [System.Drawing.PointF[]]@((PF 22 23), (PF 32 33), (PF 42 23))) }
	else { $g.DrawLines($p, [System.Drawing.PointF[]]@((PF 27 18), (PF 37 28), (PF 27 38))) }
	Save-Canvas $cv $rel
}
CatTile "icons/plugin_expandable.png" $false
CatTile "icons/plugin_expanded.png" $true
# tree branch in front of the packages of an opened category
$cv = New-Canvas 66 56; $g = $cv[1]; $p = PenOf $C.line2 2
$g.DrawLine($p, 32, 0, 32, 56); $g.DrawLine($p, 32, 28, 52, 28); $g.FillEllipse((Brush $C.accentD), 49, 24, 8, 8)
Save-Canvas $cv "icons/plugin_vertical.png"
function StatusBadge([string]$rel, [string]$hex, [bool]$filled, [string]$glyph) {
	$cv = New-Canvas 52 52; $g = $cv[1]
	if ($filled) { $g.FillEllipse((Brush $hex), 4, 4, 44, 44); $gc = $C.bg } else { $g.FillEllipse((Brush $C.card2), 4, 4, 44, 44); $g.DrawEllipse((PenOf $hex 2), 5, 5, 42, 42); $gc = $hex }
	$p = RoundPen $gc 3.5
	switch ($glyph) {
		"down" { $g.DrawLine($p, 26, 15, 26, 34); $g.DrawLines($p, [System.Drawing.PointF[]]@((PF 18 27), (PF 26 35), (PF 34 27))) }
		"up" { $g.DrawLine($p, 26, 37, 26, 18); $g.DrawLines($p, [System.Drawing.PointF[]]@((PF 18 25), (PF 26 17), (PF 34 25))) }
		"check" { $g.DrawLines($p, [System.Drawing.PointF[]]@((PF 16 27), (PF 23 34), (PF 37 19))) }
		"minus" { $g.DrawLine($p, 17, 26, 35, 26) }
	}
	Save-Canvas $cv $rel
}
StatusBadge "icons/installable.png" $C.accent $false "down"
StatusBadge "icons/install.png" $C.accent $true "down"
StatusBadge "icons/installed.png" $C.green $true "check"
StatusBadge "icons/upgradeable.png" $C.amber $true "up"
StatusBadge "icons/remove.png" $C.rec $true "minus"

# Skin-specific extra graphics (defined by tools\skins\<Skin>.ps1 as $AfterHook).
# ---- Default picon (shown by the Picon renderer for channels without a logo), 220x132 ----
$cv = New-Canvas 220 132; $g = $cv[1]
$g.FillPath((Brush $C.card2), (RoundRect 2 2 216 128 12)); $g.DrawPath((PenOf $C.line2 2), (RoundRect 2 2 216 128 12))
$g.DrawPath((RoundPen $C.text 5), (RoundRect 70 30 80 52 7))
$g.DrawLine((RoundPen $C.text 5), 94, 100, 126, 100); $g.DrawLine((RoundPen $C.text 5), 110, 82, 110, 100)
$g.FillEllipse((Brush $C.accent), 140, 22, 18, 18)
Save-Canvas $cv "picon_default.png"

# Menu entry icons (mainmenu/<key>.png), shared generator; OpenATV loads them by key, OpenPLi via <menuicons> in skin.xml
if ($Skin -eq "Obsidian-FHD") { $MenuBadge = $false; . (Join-Path $PSScriptRoot "menu-icons.ps1") }

if ($AfterHook) { . $AfterHook }
