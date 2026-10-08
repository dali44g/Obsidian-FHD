# Copy Obsidian-FHD to an OpenPLi box over SSH (uses the scp/ssh built into Windows 10/11).
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\deploy.ps1 -Box 192.168.1.50
#   powershell -ExecutionPolicy Bypass -File tools\deploy.ps1 -Box 192.168.1.50 -Activate
# -Activate stops the GUI, selects Obsidian-FHD as the skin and starts the GUI again.
param(
	[Parameter(Mandatory = $true)][string]$Box,
	[string]$User = "root",
	[switch]$Activate,
	[string]$Skin = "Obsidian-FHD"
)

$ErrorActionPreference = "Stop"
$root = Join-Path $PSScriptRoot ".." | Resolve-Path

Write-Host "Validating skin..."
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "validate-skin.ps1")
if ($LASTEXITCODE -ne 0) { Write-Host "Validation failed, nothing was copied." -ForegroundColor Red; exit 1 }

Write-Host "Copying ${Skin} to ${User}@${Box}:/usr/share/enigma2/ ..."
& ssh "${User}@${Box}" "rm -rf /usr/share/enigma2/$Skin"
& scp -r (Join-Path $root $Skin) "${User}@${Box}:/usr/share/enigma2/"
if ($LASTEXITCODE -ne 0) { Write-Host "Copy failed." -ForegroundColor Red; exit 1 }

if ($Activate) {
	# enigma2 rewrites /etc/enigma2/settings when it stops, so stop it first, then edit.
	Write-Host "Activating skin (GUI restarts)..."
	& ssh "${User}@${Box}" "init 4; sleep 4; sed -i '/^config.skin.primary_skin=/d' /etc/enigma2/settings; echo 'config.skin.primary_skin=$Skin/skin.xml' >> /etc/enigma2/settings; init 3"
} else {
	Write-Host "Done. On the box: Menu > Setup > System > User interface > Skin setup > $Skin (or restart the GUI)."
}
