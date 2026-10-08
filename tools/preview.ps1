# Obsidian-FHD rough preview renderer (no box needed).
# Draws a skin screen to PNG with sample data so you can check layout/overlaps.
# It approximates enigma2 rendering (fonts, colours, borders, radii); it is not pixel exact.
# Usage: powershell -ExecutionPolicy Bypass -File tools\preview.ps1 InfoBar ChannelSelection Menu
[CmdletBinding(PositionalBinding = $false)]
param([string]$Skin = "Obsidian-FHD", [Parameter(ValueFromRemainingArguments = $true)][string[]]$Screens = @("InfoBar", "SecondInfoBar", "ChannelSelection", "Menu", "Setup", "GraphMultiEPG", "MoviePlayer", "Volume"))

Add-Type -AssemblyName System.Drawing
$SkinDir = Join-Path $PSScriptRoot "..\$Skin" | Resolve-Path
$OutDir = Join-Path $PSScriptRoot "..\preview"
New-Item -ItemType Directory -Force $OutDir | Out-Null

$colors = @{}; $screenEls = @{}; $fontFiles = @{}
foreach ($f in "skin.xml", "skin_templates.xml", "skin_plugins.xml", "skin_openatv.xml") {
	$x = New-Object System.Xml.XmlDocument; $x.Load((Join-Path $SkinDir $f))
	foreach ($c in $x.SelectNodes("/skin/colors/color")) { $colors[$c.GetAttribute("name")] = $c.GetAttribute("value") }
	foreach ($s in $x.SelectNodes("/skin/screen")) { if (-not $s.GetAttribute("id")) { $screenEls[$s.GetAttribute("name")] = $s } }
	foreach ($n in $x.SelectNodes("/skin/fonts/font")) { $fontFiles[$n.GetAttribute("name")] = @{ file = $n.GetAttribute("filename"); scale = [int]$n.GetAttribute("scale") } }
}

# Load the skin's own TTFs so the preview uses the same typefaces.
$pfc = New-Object System.Drawing.Text.PrivateFontCollection
$familyOf = @{}
foreach ($k in $fontFiles.Keys) {
	$p = Join-Path $SkinDir ("fonts\" + $fontFiles[$k].file)
	if (Test-Path $p) { $before = $pfc.Families.Count; $pfc.AddFontFile($p) }
}
function GetFont([string]$spec, [float]$fallbackSize = 28) {
	$name = "Regular"; $size = $fallbackSize
	if ($spec) { $name = $spec.Split(";")[0]; $size = [float]$spec.Split(";")[1] }
	$scale = 100; if ($fontFiles.ContainsKey($name) -and $fontFiles[$name].scale) { $scale = $fontFiles[$name].scale }
	$px = $size * $scale / 100.0
	$famName = switch -Wildcard ($name) { "Mono*" { "JetBrains Mono" } default { "Inter" } }
	$fam = $pfc.Families | Where-Object { $_.Name -eq $famName } | Select-Object -First 1
	if (-not $fam) { $fam = New-Object System.Drawing.FontFamily("Arial") }
	$style = if ($name -in @("Bold", "MonoBold", "SemiBold")) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
	if (-not $fam.IsStyleAvailable($style)) { $style = [System.Drawing.FontStyle]::Regular }
	return New-Object System.Drawing.Font($fam, $px, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

function ToColor([string]$v) {
	if (-not $v) { return $null }
	if ($colors.ContainsKey($v)) { $v = $colors[$v] }
	$h = $v.TrimStart("#")
	if ($h.Length -eq 6) { $h = "00" + $h }
	$a = 255 - [Convert]::ToInt32($h.Substring(0, 2), 16)  # enigma2 alpha is inverted
	return [System.Drawing.Color]::FromArgb($a, [Convert]::ToInt32($h.Substring(2, 2), 16), [Convert]::ToInt32($h.Substring(4, 2), 16), [Convert]::ToInt32($h.Substring(6, 2), 16))
}

function Coord([string]$s, [int]$parent, [int]$size) {
	$s = $s.Trim()
	if ($s -eq "center") { return [int](($parent - $size) / 2) }
	$s = $s -replace "^c", ([string][int]($parent / 2)) -replace "^e", ([string]$parent)
	return [int](Invoke-Expression $s)
}

function RoundPath($x, $y, $w, $h, $r) {
	$p = New-Object System.Drawing.Drawing2D.GraphicsPath
	$r = [Math]::Min($r, [Math]::Min($w, $h) / 2)
	if ($r -le 0) { $p.AddRectangle((New-Object System.Drawing.RectangleF($x, $y, $w, $h))); return $p }
	$d = 2 * $r
	$p.AddArc($x, $y, $d, $d, 180, 90); $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
	$p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90); $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
	$p.CloseFigure(); return $p
}

# Sample data. Keys are "<Converter>:<argument>" of the last converter in a widget.
$sample = @{
	"ServiceName:Name" = "Sky Sport UHD"; "EventName:Name" = "Premier League: Liverpool vs Manchester City"; "EventName:NameNow" = "Premier League: Liverpool vs Manchester City"
	"EventName:NameNext" = "Matchday 28 Live Analysis"; "EventName:FullDescription" = "Live coverage from Anfield of the Premier League blockbuster clash. Multi-camera UHD production with spatial Dolby Atmos audio direct from the pitch-side microphones."
	"EventName:Genre" = "LIVE SPORT  FOOTBALL"; "EventName:SmallRating" = "FSK 12"
	"CryptoInfo:VerboseInfo" = "OSCam  CAID 1811  PID 0x0256  hops 1  ecm 64 ms  Remote_SkyLink"; "ClockToText:Format:%H:%M" = "21:42"; "ClockToText:Format:%-H:%M" = "21:42"
	"ClockToText:Format:%H:%M:%S" = "21:42:08"; "ClockToText:Format:%a %d %b %Y" = "Sat 03 Oct 2026"; "ClockToText:Date" = "Saturday, 03 October 2026"
	"RemainingToText:InMinutes" = "+58 min"; "ClockToText:InMinutes" = "135 min"
	"FrontendInfo:SNRdB" = "15.8 dB"; "FrontendInfo:SNR" = "96 %"; "FrontendInfo:AGC" = "84 %"; "FrontendInfo:BER" = "0"; "FrontendInfo:STRING" = "A B C D"
	"ServiceOrbitalPosition:" = "19.2E"; "TransponderInfo:" = "11493 H 22000 2/3 8PSK DVB-S2 Astra 19.2E"
	"PliExtraInfo:TransponderInfo" = "11493 H 22000 2/3 8PSK  DVB-S2  Astra 19.2E"; "PliExtraInfo:TunerSystem" = "DVB-S2"
	"PliExtraInfo:TransponderFrequency" = "11493"; "PliExtraInfo:TransponderPolarization" = "H"; "PliExtraInfo:TransponderSymbolRate" = "22000 2/3"
	"PliExtraInfo:ResolutionString" = "2160p50"; "PliExtraInfo:Resolution" = "3840x2160p50 16:9"; "PliExtraInfo:VideoCodec" = "HEVC"; "PliExtraInfo:Gamma" = "HDR10"
	"PliExtraInfo:CryptoBar" = "S V I Nd Co N Bi D"; "PliExtraInfo:CurrentCrypto" = "Nagra 1811"; "PliExtraInfo:PIDInfo" = "Pids:0x0200 0x0256 0x0020 SID:0x0001"
	"ServicePosition:Position,ShowHours" = "0:42:10"; "ServicePosition:Remaining,Plus,ShowHours" = "+0:51:33"; "TextCase:ToUpper" = "MAIN MENU / SETUP"
}
$visibleFlags = @("Is4K", "IsHDR", "IsMultichannel", "IsWidescreen", "HasTelext", "IsCrypted", "LOCK", "SubtitlesAvailable", "SNR", "SNRdB", "AGC", "BER")
$fakeEpg = @("22:15  Matchday 28 Live", "23:00  Premier League Review", "00:30  Football Classics", "01:30  Sky Sports News")

function DrawScreen($g, $el, [int]$ox, [int]$oy, [int]$pw, [int]$ph) {
	foreach ($w in $el.ChildNodes) {
		if ($w.NodeType -ne "Element") { continue }
		if ($w.LocalName -eq "panel") { DrawScreen $g $screenEls[$w.GetAttribute("name")] $ox $oy $pw $ph; continue }
		if ($w.LocalName -notin @("eLabel", "ePixmap", "widget")) { continue }
		$ot = $w.GetAttribute("objectTypes"); if ($ot -and $ot -notmatch "StaticText$") { continue }  # draw one variant of dual definitions
		$sz = $w.GetAttribute("size"); $pos = $w.GetAttribute("position")
		if ($pos -eq "fill") { $x = 0; $y = 0; $wd = $pw; $ht = $ph } else {
			if (-not $sz -or -not $pos) { continue }
			$wd = [int]$sz.Split(",")[0]; $ht = [int]$sz.Split(",")[1]
			$x = Coord $pos.Split(",")[0] $pw $wd; $y = Coord $pos.Split(",")[1] $ph $ht
		}
		$x += $ox; $y += $oy
		$r = 0; if ($w.GetAttribute("cornerRadius")) { $r = [int]$w.GetAttribute("cornerRadius").Split(";")[0] }
		$render = $w.GetAttribute("render"); $name = $w.GetAttribute("name"); $src = $w.GetAttribute("source")
		$convs = @($w.SelectNodes("convert") | ForEach-Object { $_.GetAttribute("type") + ":" + $_.InnerText.Trim() })
		$cond = ($convs | Where-Object { $_ -eq "ConditionalShowHide:" }).Count -gt 0
		$valConvs = @($convs | Where-Object { $_ -ne "ConditionalShowHide:" })
		$key = if ($valConvs.Count) { $valConvs[-1] } else { "" }
		if ($cond -and $valConvs.Count) { $flag = $valConvs[-1].Split(":")[1]; if ($flag -notin $visibleFlags -and $src -ne "session.RecordState") { continue } }
		if ($cond -and $src -match "^key_") { $text = $null }
		if ($key -match "^ClockToText" -and $valConvs.Count -gt 1 -and $valConvs[0] -match "^EventTime:StartTime") { $text = "20:45" }
		elseif ($key -match "^ClockToText" -and $valConvs.Count -gt 1 -and $valConvs[0] -match "^EventTime:EndTime") { $text = $(if ($key -match "- ") { "- 23:00" } else { "23:00" }) }
		elseif ($key -match "^ClockToText:InMinutes") { $text = "135 min" }
		else { $text = $sample[$key] }
		if ($w.GetAttribute("text")) { $text = $w.GetAttribute("text") }
		if ($src -eq "Title") { $text = "Channel Selection" }
		if ($src -match "^key_(red|green|yellow|blue)$" -and $render -eq "Label") { $text = @{ key_red = "Record / Exit"; key_green = "Subservices / Audio"; key_yellow = "Audio PID Track"; key_blue = "Extensions" }[$src] }
		$fg = ToColor ($(if ($w.GetAttribute("foregroundColor")) { $w.GetAttribute("foregroundColor") } else { "foreground" }))
		$bgAttr = $w.GetAttribute("backgroundColor")
		$transparent = $w.GetAttribute("transparent") -eq "1"
		$pix = $w.GetAttribute("pixmap")
		if (($w.LocalName -eq "eLabel" -or $render -in @("FixedLabel", "Label")) -and $bgAttr -and -not $transparent -and $bgAttr -ne "transparent") {
			$g.FillPath((New-Object System.Drawing.SolidBrush((ToColor $bgAttr))), (RoundPath $x $y $wd $ht $r))
		}
		$bw = $w.GetAttribute("borderWidth")
		if ($bw -and [int]$bw -gt 0 -and $w.GetAttribute("borderColor") -and $w.LocalName -ne "widget" -or ($bw -and $render -in @("FixedLabel", "Label") -and -not $transparent)) {
			if ($w.GetAttribute("borderColor")) { $g.DrawPath((New-Object System.Drawing.Pen((ToColor $w.GetAttribute("borderColor")), [int]$bw)), (RoundPath ($x + 0.5) ($y + 0.5) ($wd - 1) ($ht - 1) $r)) }
		}
		if ($render -eq "Pig") {
			$br = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle($x, $y, $wd, $ht)), [System.Drawing.Color]::FromArgb(255, 30, 90, 50), [System.Drawing.Color]::FromArgb(255, 20, 40, 30), 90.0)
			$g.FillRectangle($br, $x, $y, $wd, $ht); continue
		}
		if ($render -eq "Picon") { $g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 20, 24, 30))), (RoundPath $x $y $wd $ht 4)); $g.DrawString("SKY", (GetFont "MonoBold;34"), (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)), (New-Object System.Drawing.RectangleF($x, $y, $wd, $ht)), (New-Object System.Drawing.StringFormat -Property @{ Alignment = "Center"; LineAlignment = "Center" })); continue }
		if ($render -eq "ChannelNumber") { $text = "1" }
		if ($render -eq "VideoSize") { $text = "3840x2160" }
		if ($render -eq "NextEpgInfo") { $text = $fakeEpg -join "`n" }
		if ($name -eq "VolumeText") { $text = "42" }
		if ($pix -and ($render -in @("Progress", "PositionGauge") -or $name -eq "Volume")) {
			$file = Join-Path $SkinDir $pix
			$frac = if ($key -match "AGC") { 0.84 } elseif ($key -match "SNR") { 0.96 } else { 0.62 }
			if ($render -eq "PositionGauge") { $frac = 0.45 }
			if (Test-Path $file) { $img = [System.Drawing.Image]::FromFile($file); $g.SetClip((New-Object System.Drawing.RectangleF($x, $y, ($wd * $frac), $ht))); $g.DrawImage($img, $x, $y, $img.Width, $img.Height); $g.ResetClip(); $img.Dispose() }
			continue
		}
		if ($render -eq "PositionGauge") { continue }
		if ($pix -and $pix -notmatch "^/") {
			if ($cond -and $src -match "^key_" -and $render -eq "Pixmap") { }  # colour key pills: show
			elseif ($cond -and $pix -notmatch "rec") { continue }
			$file = Join-Path $SkinDir $pix
			if (Test-Path $file) { $img = [System.Drawing.Image]::FromFile($file); $g.DrawImage($img, $x, $y, [Math]::Min($wd, $img.Width), [Math]::Min($ht, $img.Height)); $img.Dispose() }
			continue
		}
		if ($render -eq "Listbox" -or $name -in @("list", "config")) {
			if ($name -in @("filelist", "playlist")) { $items = @("..", "Music", "Videos", "Pictures", "01 - Intro.mp3", "02 - Signal Lock.mp3", "03 - Orbit.flac", "04 - Transponder.mp3", "05 - Carrier.mp3", "06 - Downlink.mp3", "07 - Uplink.mp3", "08 - Outro.mp3") } else { $items = @("Live TV & Infobar", "Bouquet Manager", "EPG Timeline", "Recordings & PVR", "Timers", "Tuner Config", "Setup", "Plugins", "Information", "Standby / Restart") }
			$isChan = $w.GetAttribute("serviceNameFont")
			if ($isChan) { $items = @("1   Sky Sport UHD", "2   Sky Cinema Premiere HD", "3   BBC One UHD", "4   Eurosport 4K", "5   DAZN 1 HD", "6   Canal+ Foot UHD", "7   ZDF HD", "8   Das Erste HD", "9   arte HD", "10  3sat HD", "11  phoenix HD", "12  ONE HD") }
			if ($w.GetAttribute("itemHeight")) { $ih = [int]$w.GetAttribute("itemHeight") } else { $ih = 72 }
			$selPix = $w.GetAttribute("selectionPixmap")
			$fnt = if ($isChan) { GetFont $w.GetAttribute("serviceNameFont") } else { GetFont $(if ($w.GetAttribute("font")) { $w.GetAttribute("font") } else { "Regular;30" }) }
			for ($i = 0; $i -lt $items.Count -and ($i + 1) * $ih -le $ht; $i++) {
				$iy = $y + $i * $ih
				$sel = ($i -eq 0)
				if ($sel) {
					if ($selPix -and (Test-Path (Join-Path $SkinDir $selPix))) { $img = [System.Drawing.Image]::FromFile((Join-Path $SkinDir $selPix)); $g.SetClip((New-Object System.Drawing.RectangleF($x, $iy, $wd, $ih))); $g.DrawImage($img, $x, $iy, $img.Width, $img.Height); $g.ResetClip(); $img.Dispose() }
					else { $g.FillRectangle((New-Object System.Drawing.SolidBrush((ToColor "selectorcolor"))), $x, $iy, $wd, $ih); $g.FillRectangle((New-Object System.Drawing.SolidBrush((ToColor "aAccent"))), $x, $iy, 4, $ih) }
				}
				$fgc = if ($sel) { if ($w.GetAttribute("foregroundColorSelected")) { $w.GetAttribute("foregroundColorSelected") } else { "selectedFG" } } else { "foreground" }
				$tx = $x + 30
				if ($isChan) {
					$num, $nm = $items[$i] -split "\s{2,}", 2
					$g.DrawString($num.Trim(), (GetFont "MonoBold;30"), (New-Object System.Drawing.SolidBrush((ToColor $(if ($sel) { "aAccent" } else { "aSlate" })))), ($x + 20), ($iy + 8))
					$g.DrawString($nm, $fnt, (New-Object System.Drawing.SolidBrush((ToColor $fgc))), ($x + 90), ($iy + 4))
					$g.DrawString("Premier League: Liverpool vs Manchester City", (GetFont "Regular;24"), (New-Object System.Drawing.SolidBrush((ToColor $(if ($sel) { "aVariant" } else { "aMuted" })))), ($x + 90), ($iy + 40))
					$g.FillRectangle((New-Object System.Drawing.SolidBrush((ToColor "aLine"))), ($x + $wd - 120), ($iy + 32), 80, 6)
					$g.FillRectangle((New-Object System.Drawing.SolidBrush((ToColor "aAccent"))), ($x + $wd - 120), ($iy + 32), (80 * (0.2 + 0.07 * $i)), 6)
				} else {
					$sf = New-Object System.Drawing.StringFormat; $sf.LineAlignment = "Center"
					$g.DrawString($items[$i], $fnt, (New-Object System.Drawing.SolidBrush((ToColor $fgc))), (New-Object System.Drawing.RectangleF($tx, $iy, ($wd - 60), $ih)), $sf)
				}
			}
			continue
		}
		if ($render -eq "Progress") { continue }
		if ($text) {
			$fnt = GetFont $w.GetAttribute("font")
			$sf = New-Object System.Drawing.StringFormat
			$sf.Alignment = switch ($w.GetAttribute("halign")) { "right" { "Far" } "center" { "Center" } default { "Near" } }
			$sf.LineAlignment = switch ($w.GetAttribute("valign")) { "center" { "Center" } "bottom" { "Far" } default { "Near" } }
			if ($w.GetAttribute("noWrap") -eq "1") { $sf.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap; $sf.Trimming = "EllipsisCharacter" }
			$g.DrawString($text, $fnt, (New-Object System.Drawing.SolidBrush($fg)), (New-Object System.Drawing.RectangleF($x, $y, $wd, $ht)), $sf)
		}
	}
}

foreach ($name in $Screens) {
	$s = $screenEls[$name]
	if (-not $s) { Write-Host "No screen '$name'"; continue }
	$bmp = New-Object System.Drawing.Bitmap(1920, 1080)
	$g = [System.Drawing.Graphics]::FromImage($bmp)
	$g.SmoothingMode = "AntiAlias"; $g.TextRenderingHint = "AntiAliasGridFit"
	# Fake TV picture behind OSD.
	$br = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle(0, 0, 1920, 1080)), [System.Drawing.Color]::FromArgb(255, 24, 70, 40), [System.Drawing.Color]::FromArgb(255, 10, 25, 20), 70.0)
	$g.FillRectangle($br, 0, 0, 1920, 1080)
	$pos = $s.GetAttribute("position"); $size = $s.GetAttribute("size")
	if ($pos -eq "fill" -or -not $size) { $sx = 0; $sy = 0; $sw = 1920; $sh = 1080 } else {
		$sw = [int]$size.Split(",")[0]; $sh = [int]$size.Split(",")[1]
		$sx = Coord $pos.Split(",")[0] 1920 $sw; $sy = Coord $pos.Split(",")[1] 1080 $sh
	}
	$bg = $s.GetAttribute("backgroundColor")
	if ($s.GetAttribute("flags") -match "wfNoBorder" -and $bg -ne "transparent") {
		$g.FillRectangle((New-Object System.Drawing.SolidBrush((ToColor $(if ($bg) { $bg } else { "background" })))), $sx, $sy, $sw, $sh)
	}
	DrawScreen $g $s $sx $sy $sw $sh
	$out = Join-Path $OutDir "$name.png"
	$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
	Write-Host "  preview/$name.png"
}
