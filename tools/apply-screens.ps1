# Replaces screens in Obsidian-FHD/skin.xml with the hand-built versions in tools/screens-obsidian.xml
# (matched by name; screens not yet in skin.xml are appended). Safe to run repeatedly.
$SkinDir = Join-Path $PSScriptRoot "..\Obsidian-FHD" | Resolve-Path
$skinPath = Join-Path $SkinDir "skin.xml"
$skin = New-Object System.Xml.XmlDocument; $skin.PreserveWhitespace = $true; $skin.Load($skinPath)
$src = New-Object System.Xml.XmlDocument; $src.PreserveWhitespace = $true; $src.Load((Join-Path $PSScriptRoot "screens-obsidian.xml"))
$done = @()
foreach ($s in $src.SelectNodes("/skin/screen")) {
	$name = $s.GetAttribute("name")
	$new = $skin.ImportNode($s, $true)
	$old = @($skin.SelectNodes("/skin/screen[@name='$name']") | Where-Object { -not $_.GetAttribute("id") -or $_.GetAttribute("id") -eq "0" })[0]
	if ($old) { [void]$old.ParentNode.ReplaceChild($new, $old); $done += $name }
	else { [void]$skin.DocumentElement.AppendChild($skin.CreateWhitespace("`n`t")); [void]$skin.DocumentElement.AppendChild($new); $done += "$name (new)" }
}
$settings = New-Object System.Xml.XmlWriterSettings; $settings.Encoding = New-Object System.Text.UTF8Encoding($false)
$w = [System.Xml.XmlWriter]::Create($skinPath, $settings); $skin.Save($w); $w.Close()
Write-Host ("Applied {0} screens: {1}" -f $done.Count, ($done -join ", "))
