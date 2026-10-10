# Builds the release packages into dist/:
#   enigma2-plugin-skins-obsidian-fhd_<version>_all.ipk   (opkg install /tmp/<file>.ipk)
#   Obsidian-FHD-<version>.zip                            (manual install: copy the folder to /usr/share/enigma2/)
# The version is read from the "OBSIDIAN FHD  vX.Y" text in skin_templates.xml, the only place it is written.
# Needs only Windows' built-in tar.exe; the .ipk "ar" container is written here directly.
param([string]$Maintainer = "blackattack82")

$ErrorActionPreference = "Stop"
$root = Join-Path $PSScriptRoot ".." | Resolve-Path
$skin = Join-Path $root "Obsidian-FHD"
$tar = Join-Path $env:SystemRoot "System32\tar.exe"
$m = Select-String -Path (Join-Path $skin "skin_templates.xml") -Pattern 'OBSIDIAN FHD\s+v([0-9][0-9.]*)' | Select-Object -First 1
if (-not $m) { throw "Version text 'OBSIDIAN FHD  vX.Y' not found in skin_templates.xml" }
$version = $m.Matches[0].Groups[1].Value
$pkg = "enigma2-plugin-skins-obsidian-fhd"
$dist = Join-Path $root "dist"
$work = Join-Path $dist ".build"
if (Test-Path $work) { Remove-Item -Recurse -Force $work }
New-Item -ItemType Directory -Force (Join-Path $work "data\usr\share\enigma2"), (Join-Path $work "control") | Out-Null
$enc = New-Object System.Text.UTF8Encoding($false)
function WriteLf([string]$path, [string]$text) { [IO.File]::WriteAllText($path, ($text -replace "`r`n", "`n"), $enc) }

# ---- data: the skin folder under /usr/share/enigma2 ----
Copy-Item -Recurse $skin (Join-Path $work "data\usr\share\enigma2\Obsidian-FHD")
$sizeKb = [math]::Ceiling(((Get-ChildItem -Recurse -File $skin | Measure-Object Length -Sum).Sum) / 1024)

# ---- control files ----
WriteLf (Join-Path $work "control\control") @"
Package: $pkg
Version: $version
Description: Obsidian FHD skin for enigma2
 Dark 1080p skin with telemetry-style infobar, cards and cyan/amber accents.
 Works on OpenPLi, OpenATV and other enigma2 images. No Python components.
Section: skin
Priority: optional
Maintainer: $Maintainer
Architecture: all
Installed-Size: $sizeKb
Homepage: https://github.com/blackattack82
Source: Obsidian-FHD

"@
WriteLf (Join-Path $work "control\postinst") @"
#!/bin/sh
echo ""
echo "Obsidian FHD $version installed."
echo "Select it in Menu > Setup > System > User interface > Skin setup, then restart the GUI."
echo ""
exit 0

"@
WriteLf (Join-Path $work "control\postrm") @"
#!/bin/sh
# Fall back to the image default if the removed skin was active.
if grep -q '^config.skin.primary_skin=Obsidian-FHD/' /etc/enigma2/settings 2>/dev/null; then
	sed -i '/^config.skin.primary_skin=Obsidian-FHD\//d' /etc/enigma2/settings
	echo "Obsidian FHD removed; the default skin will be used after the next GUI restart."
fi
exit 0

"@
WriteLf (Join-Path $work "debian-binary") "2.0`n"

# ---- tarballs (owner root, scripts executable) ----
# Windows tar cannot set Unix permissions, so the small control archive is written here directly
# (ustar format) with the maintainer scripts marked executable: opkg runs them directly.
function TarField([byte[]]$h, [int]$off, [int]$len, [string]$s) { $b = [Text.Encoding]::ASCII.GetBytes($s); [Array]::Copy($b, 0, $h, $off, [math]::Min($b.Length, $len)) }
function New-TarGz([string]$dest, [object[]]$entries) {
	$ms = New-Object IO.MemoryStream
	foreach ($e in $entries) {
		$data = [IO.File]::ReadAllBytes($e.Path)
		$h = New-Object byte[] 512
		TarField $h 0 100 $e.Name
		TarField $h 100 8 ("{0}`0" -f [Convert]::ToString($e.Mode, 8).PadLeft(7, '0'))
		TarField $h 108 8 "0000000`0"; TarField $h 116 8 "0000000`0"
		TarField $h 124 12 ("{0}`0" -f [Convert]::ToString($data.Length, 8).PadLeft(11, '0'))
		TarField $h 136 12 ("{0}`0" -f [Convert]::ToString([DateTimeOffset]::UtcNow.ToUnixTimeSeconds(), 8).PadLeft(11, '0'))
		TarField $h 148 8 "        "; TarField $h 156 1 "0"
		TarField $h 257 6 "ustar`0"; TarField $h 263 2 "00"; TarField $h 265 32 "root"; TarField $h 297 32 "root"
		$sum = 0; foreach ($x in $h) { $sum += $x }
		TarField $h 148 8 ("{0}`0 " -f [Convert]::ToString($sum, 8).PadLeft(6, '0'))
		$ms.Write($h, 0, 512); $ms.Write($data, 0, $data.Length)
		$pad = (512 - ($data.Length % 512)) % 512; if ($pad) { $ms.Write((New-Object byte[] $pad), 0, $pad) }
	}
	$ms.Write((New-Object byte[] 1024), 0, 1024)
	$fs = [IO.File]::Create($dest); $gz = New-Object IO.Compression.GZipStream($fs, [IO.Compression.CompressionMode]::Compress)
	$bytes = $ms.ToArray(); $gz.Write($bytes, 0, $bytes.Length); $gz.Close(); $fs.Close()
}
$c = Join-Path $work "control"
New-TarGz (Join-Path $work "control.tar.gz") @(
	@{ Name = "./control"; Path = (Join-Path $c "control"); Mode = 420 },
	@{ Name = "./postinst"; Path = (Join-Path $c "postinst"); Mode = 493 },
	@{ Name = "./postrm"; Path = (Join-Path $c "postrm"); Mode = 493 })
Push-Location (Join-Path $work "data")
& $tar --format=ustar --uid 0 --gid 0 --uname root --gname root -czf (Join-Path $work "data.tar.gz") ./usr
Pop-Location

# ---- ar container: debian-binary, control.tar.gz, data.tar.gz ----
New-Item -ItemType Directory -Force $dist | Out-Null
$ipk = Join-Path $dist ("{0}_{1}_all.ipk" -f $pkg, $version)
$out = [IO.File]::Create($ipk)
$ascii = [Text.Encoding]::ASCII
$magic = $ascii.GetBytes("!<arch>`n"); $out.Write($magic, 0, $magic.Length)
$mtime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
foreach ($name in "debian-binary", "control.tar.gz", "data.tar.gz") {
	$bytes = [IO.File]::ReadAllBytes((Join-Path $work $name))
	$hdr = "{0,-16}{1,-12}{2,-6}{3,-6}{4,-8}{5,-10}``" -f ($name + "/"), $mtime, 0, 0, 100644, $bytes.Length
	$h = $ascii.GetBytes($hdr + "`n"); $out.Write($h, 0, $h.Length)
	$out.Write($bytes, 0, $bytes.Length)
	if ($bytes.Length % 2) { $out.WriteByte(10) }
}
$out.Close()

# ---- zip for manual install ----
$zip = Join-Path $dist ("Obsidian-FHD-{0}.zip" -f $version)
if (Test-Path $zip) { Remove-Item $zip }
$zipWork = Join-Path $work "zip"
New-Item -ItemType Directory -Force $zipWork | Out-Null
Copy-Item -Recurse $skin (Join-Path $zipWork "Obsidian-FHD")
# User-facing notes (the repository README is for developers).
WriteLf (Join-Path $zipWork "INSTALL.txt") @"
Obsidian FHD $version - skin for enigma2 (OpenPLi, OpenATV and other images), 1920x1080

Easiest: install the .ipk package instead of this zip
  1. Copy enigma2-plugin-skins-obsidian-fhd_${version}_all.ipk to /tmp on the receiver.
  2. Run: opkg install /tmp/enigma2-plugin-skins-obsidian-fhd_${version}_all.ipk
     (or use your image's "install local extension" menu).

Manual install with this zip
  1. Copy the Obsidian-FHD folder to /usr/share/enigma2/ on the receiver
     (result: /usr/share/enigma2/Obsidian-FHD/skin.xml).
  2. Menu > Setup > System > User interface > Skin setup: choose Obsidian-FHD.
  3. Restart the GUI.

Picons in the channel list are an image setting: enable them in the channel selection settings.

Fonts: Inter, JetBrains Mono and Noto Kufi Arabic, SIL Open Font License (see Obsidian-FHD/fonts/*-OFL.txt).

"@
# Built with tar (forward-slash paths): Compress-Archive on Windows PowerShell 5 writes backslashes,
# which unzip on the receiver/Linux turns into broken file names.
Push-Location $zipWork
& $tar -a -cf $zip "Obsidian-FHD" "INSTALL.txt"
Pop-Location

Remove-Item -Recurse -Force $work
# Stable name for the one-command installer (release/ in the public repo)
Copy-Item $ipk (Join-Path $dist ("{0}_all.ipk" -f $pkg)) -Force
Write-Host ("Built version {0}:" -f $version)
Get-ChildItem $dist -File | ForEach-Object { Write-Host ("  {0,-55} {1,8:N0} KB" -f $_.Name, ($_.Length / 1KB)) }
