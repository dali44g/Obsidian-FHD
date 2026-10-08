# enigma2 creates data widgets (renderers) first and plain eLabel/ePixmap afterwards, so at the
# same zPosition a background eLabel is drawn ON TOP of the widgets it should sit behind.
# This moves every background-only eLabel (no text, opaque fill) with zPosition <= 0 to -1.
# eLabels with a positive zPosition are deliberate overlays and are left alone. Idempotent.
param([string]$Skin = "Obsidian-FHD")
$root = Join-Path $PSScriptRoot ".." | Resolve-Path
$files = @("$Skin\skin.xml", "$Skin\skin_templates.xml", "$Skin\skin_plugins.xml")
if ($Skin -eq "Obsidian-FHD") { $files += "tools\screens-obsidian.xml" }
$total = 0
foreach ($f in $files) {
	$path = Join-Path $root $f
	$x = New-Object System.Xml.XmlDocument; $x.PreserveWhitespace = $true; $x.Load($path)
	$n = 0
	foreach ($e in $x.SelectNodes("//screen//eLabel")) {
		if ($e.GetAttribute("text")) { continue }
		if ($e.GetAttribute("transparent") -eq "1") { continue }
		$bg = $e.GetAttribute("backgroundColor")
		if (-not $bg -or $bg -eq "transparent" -or $bg -match "^#ff") { continue }
		$z = $e.GetAttribute("zPosition")
		if ($z -and [int]$z -lt 0) { continue }
		if ($z -and [int]$z -gt 0) { continue }
		$e.SetAttribute("zPosition", "-1"); $n++
	}
	$settings = New-Object System.Xml.XmlWriterSettings; $settings.Encoding = New-Object System.Text.UTF8Encoding($false)
	$w = [System.Xml.XmlWriter]::Create($path, $settings); $x.Save($w); $w.Close()
	Write-Host ("  {0,-32} {1} background labels moved to zPosition -1" -f $f, $n)
	$total += $n
}
Write-Host "Total: $total"
