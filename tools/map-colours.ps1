# Maps hard-coded hex colours in screens (mostly plugin screens) onto the Obsidian palette.
# Only colour attributes inside <screen> elements are touched. Idempotent.
$SkinDir = Join-Path $PSScriptRoot "..\Obsidian-FHD" | Resolve-Path

function Classify([string]$hex) {
	$h = $hex.TrimStart("#").ToLower()
	if ($h.Length -eq 6) { $h = "00" + $h }
	$a = [Convert]::ToInt32($h.Substring(0, 2), 16)
	$r = [Convert]::ToInt32($h.Substring(2, 2), 16); $g = [Convert]::ToInt32($h.Substring(4, 2), 16); $b = [Convert]::ToInt32($h.Substring(6, 2), 16)
	if ($a -ge 0xf0) { return $null }                       # (almost) fully transparent: keep
	$max = [Math]::Max($r, [Math]::Max($g, $b)); $min = [Math]::Min($r, [Math]::Min($g, $b))
	$lum = 0.2126 * $r + 0.7152 * $g + 0.0722 * $b
	$sat = if ($max -eq 0) { 0 } else { ($max - $min) / $max }
	if ($a -ge 0x20 -and $lum -lt 90) { return "aGlass" }    # translucent dark panel
	if ($sat -gt 0.45 -and $max -gt 120) {
		if ($r -gt 180 -and $g -lt 110) { return "aRed" }
		if ($r -gt 180 -and $g -gt 120 -and $b -lt 100) { return "aAmber" }
		if ($g -gt $r -and $g -gt $b -and $b -lt 140) { return "aGreen" }
		return "aAccent"
	}
	if ($lum -lt 60) { if ($sat -gt 0.3 -and $b -gt $r) { return "aSelBg" } else { return "aCard" } }
	if ($lum -lt 115) { return "aLine2" }
	if ($lum -lt 200) { return "aMuted" }
	return "aText"
}

$enc = New-Object System.Text.UTF8Encoding($false)
$total = 0; $summary = @{}
foreach ($f in "skin.xml", "skin_plugins.xml") {
	$path = Join-Path $SkinDir $f
	$x = New-Object System.Xml.XmlDocument; $x.PreserveWhitespace = $true; $x.Load($path)
	foreach ($el in $x.SelectNodes("/skin/screen//*")) {
		foreach ($a in @($el.Attributes)) {
			if ($a.Name -notmatch "[Cc]olor") { continue }
			$parts = $a.Value.Split(",")
			$changed = $false
			for ($i = 0; $i -lt $parts.Count; $i++) {
				$p = $parts[$i].Trim()
				if ($p -notmatch "^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$") { continue }
				$m = Classify $p
				if ($m) { $summary["$p -> $m"] = 1 + [int]$summary["$p -> $m"]; $parts[$i] = $m; $changed = $true; $total++ }
			}
			if ($changed) { $a.Value = ($parts -join ",") }
		}
	}
	$settings = New-Object System.Xml.XmlWriterSettings; $settings.Encoding = $enc
	$w = [System.Xml.XmlWriter]::Create($path, $settings); $x.Save($w); $w.Close()
}
$summary.GetEnumerator() | Sort-Object Name | ForEach-Object { "  {0,-28} x{1}" -f $_.Name, $_.Value }
Write-Host "Mapped $total colour values."
