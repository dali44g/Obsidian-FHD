# Graphics of the "Nova" infobar style (skin_infobar_nova.xml) in Obsidian-FHD/nova:
#   capsule.png      horizontal indigo -> navy gradient for the inside of the capsule (opaque; the rounded ends are eLabels)
#   cover_title.png  the same gradient cut at the title area: hides the big channel name while a programme title is shown
#   ring_00..23.png  progress ring steps (track + coral arc + peach knob), picked by EventTime Progress + ValueRange
#   ring_live.png    full coral ring for channels without a programme guide
# Ring images have a transparent outside and centre; they sit on the capsule (OSD over OSD), never over video.
Add-Type -AssemblyName System.Drawing
$root = Join-Path $PSScriptRoot ".." | Resolve-Path
$out = Join-Path $root "Obsidian-FHD\nova"
New-Item -ItemType Directory -Force $out | Out-Null
function C($hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }

# capsule spans x 150..1770 (1620 wide); the image covers its straight middle part x 194..1726, y 812..1032
$C1 = C "#281652"; $C2 = C "#0E1634"; $CapX = 150; $CapW = 1620
function GradAt($x) { $t = ($x - $CapX) / ($CapW - 1); [System.Drawing.Color]::FromArgb(255, [int]($C1.R + ($C2.R - $C1.R) * $t), [int]($C1.G + ($C2.G - $C1.G) * $t), [int]($C1.B + ($C2.B - $C1.B) * $t)) }
function GradImage($sx, $sy, $w, $h, $name, $edges) {
	$bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp)
	for ($i = 0; $i -lt $w; $i++) { $g.DrawLine((New-Object System.Drawing.Pen (GradAt ($sx + $i))), $i, 0, $i, $h) }
	if ($edges) {
		$g.DrawLine((New-Object System.Drawing.Pen((C "#584296"), 2)), 0, 0, $w, 0)          # outline top
		$g.DrawLine((New-Object System.Drawing.Pen((C "#584296"), 2)), 0, ($h - 1), $w, ($h - 1)) # outline bottom
		$g.DrawLine((New-Object System.Drawing.Pen (C "#7864BE")), 6, 3, ($w - 6), 3)           # light on the top edge
	}
	$bmp.Save((Join-Path $out $name), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); $name
}
GradImage 194 812 1532 250 "capsule.png" $true
GradImage 440 860 810 66 "cover_title.png" $false
GradImage 436 1018 1298 42 "cover_tele.png" $false

# ring: 156 x 156, radius 72, 12 px stroke
$S = 156; $R = 66
for ($k = 0; $k -lt 24; $k++) {
	$bmp = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = "AntiAlias"; $g.Clear([System.Drawing.Color]::Transparent)
	$rect = New-Object System.Drawing.RectangleF(($S / 2 - $R), ($S / 2 - $R), (2 * $R), (2 * $R))
	$g.DrawEllipse((New-Object System.Drawing.Pen((C "#3C2C6E"), 12)), $rect)
	$sweep = 360 * ($k + 0.5) / 24
	$arc = New-Object System.Drawing.Pen((C "#FF6B6B"), 12); $arc.StartCap = "Round"; $arc.EndCap = "Round"
	$g.DrawArc($arc, $rect, -90, $sweep)
	$a = (-90 + $sweep) * [math]::PI / 180
	$kx = $S / 2 + $R * [math]::Cos($a); $ky = $S / 2 + $R * [math]::Sin($a)
	$g.FillEllipse((New-Object System.Drawing.SolidBrush (C "#FFB86B")), ($kx - 9), ($ky - 9), 18, 18)
	$bmp.Save((Join-Path $out ("ring_{0:D2}.png" -f $k)), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
$bmp = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = "AntiAlias"; $g.Clear([System.Drawing.Color]::Transparent)
$g.DrawEllipse((New-Object System.Drawing.Pen((C "#FF6B6B"), 6)), ($S / 2 - $R), ($S / 2 - $R), (2 * $R), (2 * $R))
$bmp.Save((Join-Path $out "ring_live.png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
# solid SNR / AGC bars for the telemetry line (Progress renderer)
foreach ($b in @(@("bar_snr.png", "#00F0FF"), @("bar_agc.png", "#FFB86B"))) {
	$bmp = New-Object System.Drawing.Bitmap 100, 10, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = "AntiAlias"; $g.Clear([System.Drawing.Color]::Transparent)
	$p = New-Object System.Drawing.Drawing2D.GraphicsPath; $p.AddArc(0, 0, 10, 10, 90, 180); $p.AddArc(89, 0, 10, 10, 270, 180); $p.CloseFigure()
	$g.FillPath((New-Object System.Drawing.SolidBrush (C $b[1])), $p)
	$bmp.Save((Join-Path $out $b[0]), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
"nova graphics: capsule, covers, 24 ring steps, live ring, signal bars"
