# Applies the Obsidian card layout to every screen that uses the shared templates.
# Idempotent: running it again changes nothing. Run validate-skin.ps1 afterwards.
#   - screens whose own widgets span both columns are switched to the *Flat template variants
#   - widgets inside the left/right content cards become transparent over aCard
#   - every list gets the slim cyan scrollbar; settings lists get 52px rows
param([switch]$DryRun)

$SkinDir = Join-Path $PSScriptRoot "..\Obsidian-FHD" | Resolve-Path
$docs = @{}; $scr = @{}
foreach ($f in "skin.xml", "skin_templates.xml", "skin_plugins.xml") {
	$x = New-Object System.Xml.XmlDocument; $x.PreserveWhitespace = $true; $x.Load((Join-Path $SkinDir $f)); $docs[$f] = $x
	foreach ($s in $x.SelectNodes("/skin/screen")) { $scr[$s.GetAttribute("name")] = $s }
}

function Uses($el, [string]$target, [int]$depth = 0) {
	if ($depth -gt 8 -or -not $el) { return $false }
	foreach ($p in $el.SelectNodes(".//panel")) { $n = $p.GetAttribute("name"); if ($n -eq $target) { return $true }; if (Uses $scr[$n] $target ($depth + 1)) { return $true } }
	return $false
}
function Rect($w) {
	$p = $w.GetAttribute("position"); $s = $w.GetAttribute("size")
	if ($p -notmatch "^\s*\d+\s*,\s*\d+\s*$" -or $s -notmatch "^\s*\d+\s*,\s*\d+\s*$") { return $null }
	$a = $p.Split(","); $b = $s.Split(",")
	return @{ x = [int]$a[0]; y = [int]$a[1]; w = [int]$b[0]; h = [int]$b[1] }
}
function InCard($r) {
	if (-not $r) { return $false }
	$right = ($r.x -ge 772 -and $r.y -ge 96 -and ($r.y + $r.h) -le 1016 -and ($r.x + $r.w) -le 1900)
	$left = ($r.x -ge 24 -and ($r.x + $r.w) -le 758 -and $r.y -ge 556 -and ($r.y + $r.h) -le 1016)
	return ($right -or $left)
}
$darkBg = @("", "background", "black", "secondBG", "noTransBG", "aBg", "#000000", "#00000000")
$stats = @{ flat = @(); widgets = 0; scroll = 0; rows = 0 }

foreach ($f in "skin.xml", "skin_plugins.xml") {
	$x = $docs[$f]
	foreach ($s in $x.SelectNodes("/skin/screen")) {
		$name = $s.GetAttribute("name")
		$own = @($s.ChildNodes | Where-Object { $_.NodeType -eq "Element" -and $_.LocalName -in @("widget", "eLabel", "ePixmap") })
		# Every list: slim cyan scrollbar.
		foreach ($w in $s.SelectNodes(".//widget[@scrollbarMode]")) {
			if ($w.GetAttribute("scrollbarMode") -eq "showNever") { continue }
			if (-not $w.HasAttribute("scrollbarWidth")) { $w.SetAttribute("scrollbarWidth", "4"); $w.SetAttribute("scrollbarSliderBorderWidth", "0"); $w.SetAttribute("scrollbarSliderForegroundColor", "aAccent"); $stats.scroll++ }
			# Text views (ScrollLabel) pass borderWidth to their scrollbar: keep it borderless.
			if (-not $w.HasAttribute("borderWidth")) { $w.SetAttribute("borderWidth", "0"); $stats.scroll++ }
		}
		# Settings lists: taller rows.
		foreach ($w in $s.SelectNodes(".//widget[@name='config']")) {
			$ih = $w.GetAttribute("itemHeight"); $font = $w.GetAttribute("font")
			if ($ih -match "^(3[0-9]|4[0-6])$" -and ($font -eq "" -or [int]($font.Split(";")[1]) -le 30)) { $w.SetAttribute("itemHeight", "52"); $stats.rows++ }
		}
		if (-not (Uses $s "SelectionTemplate")) { continue }
		# Does any own widget span both columns? Then use the flat variant.
		$spans = $false
		foreach ($w in $own) { $r = Rect $w; if ($r -and $r.x -lt 756 -and ($r.x + $r.w) -gt 776 -and ($r.y + $r.h) -gt 560 -and $r.y -lt 1016 -and $r.w -lt 1900) { $spans = $true } }
		if ($spans) {
			foreach ($p in $s.SelectNodes("panel")) {
				$pn = $p.GetAttribute("name")
				if ($pn -in @("PigTemplate", "SelectionTemplate")) { $p.SetAttribute("name", "${pn}Flat") }
			}
			if (Uses $s "SelectionTemplate") { Write-Host "  note: $name spans columns but reaches cards via '$(($s.SelectNodes('panel') | ForEach-Object { $_.GetAttribute('name') }) -join ',')'" }
			$stats.flat += $name
			continue
		}
		foreach ($w in $own) {
			$r = Rect $w
			if (-not (InCard $r)) { continue }
			if ($w.GetAttribute("render") -in @("Pig", "Picon")) { continue }
			$src = $w.GetAttribute("source"); $nm = $w.GetAttribute("name")
			if ($src -match "^key_" -or $nm -match "^key_") { continue }
			$changed = $false
			if ($w.LocalName -ne "ePixmap") {
				$bg = $w.GetAttribute("backgroundColor")
				if ($bg -in $darkBg) { $w.SetAttribute("backgroundColor", "aCard"); $changed = $true }
				if ($w.GetAttribute("transparent") -ne "1" -and $bg -ne "transparent" -and -not ($w.LocalName -eq "eLabel" -and -not $w.GetAttribute("text"))) { $w.SetAttribute("transparent", "1"); $changed = $true }
			}
			if ($changed) { $stats.widgets++ }
		}
	}
}

Write-Host ("Flat variant: {0} screens ({1})" -f $stats.flat.Count, ($stats.flat -join ", "))
Write-Host ("Card-normalised widgets: {0}   scrollbars styled: {1}   settings lists resized: {2}" -f $stats.widgets, $stats.scroll, $stats.rows)
if ($DryRun) { Write-Host "Dry run: nothing written."; exit 0 }
$enc = New-Object System.Text.UTF8Encoding($false)
foreach ($f in "skin.xml", "skin_plugins.xml") {
	$path = Join-Path $SkinDir $f
	$settings = New-Object System.Xml.XmlWriterSettings; $settings.Encoding = $enc; $settings.OmitXmlDeclaration = ($docs[$f].FirstChild.NodeType -ne "XmlDeclaration")
	$w = [System.Xml.XmlWriter]::Create($path, $settings); $docs[$f].Save($w); $w.Close()
}
Write-Host "Written."
