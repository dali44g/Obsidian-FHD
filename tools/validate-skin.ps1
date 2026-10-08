# Obsidian-FHD static validator.
# Catches the mistakes that make enigma2 skins misbehave, before you copy to the box:
#   - malformed XML
#   - colour names that are not defined in <colors>
#   - font names that are not defined in <fonts>
#   - <panel name="..."> pointing at a screen that does not exist
#   - images referenced by the skin that are missing from the skin folder
#   - screens defined twice
# Usage: powershell -ExecutionPolicy Bypass -File tools\validate-skin.ps1
# Exit code 0 = clean, 1 = errors found.

param([string]$Skin = "Obsidian-FHD")
$SkinDir = Join-Path $PSScriptRoot "..\$Skin" | Resolve-Path
$files = @("skin.xml", "skin_templates.xml", "skin_plugins.xml", "skin_openatv.xml")
$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

# enigma2 named colours that exist without being declared.
$colors = @{}
$fonts = @{}
$screens = @{}
$docs = @{}

foreach ($f in $files) {
	$path = Join-Path $SkinDir $f
	try {
		$xml = New-Object System.Xml.XmlDocument
		$xml.PreserveWhitespace = $false
		$xml.Load($path)
		$docs[$f] = $xml
	} catch {
		$errors.Add("XML parse error in ${f}: $($_.Exception.Message)")
	}
}
if ($errors.Count) { $errors | ForEach-Object { Write-Host "ERROR  $_" -ForegroundColor Red }; exit 1 }

foreach ($f in $docs.Keys) {
	$xml = $docs[$f]
	foreach ($c in $xml.SelectNodes("/skin/colors/color")) { $colors[$c.name] = $c.value }
	foreach ($n in $xml.SelectNodes("/skin/fonts/font")) { $fonts[$n.name] = $n.filename }
	foreach ($s in $xml.SelectNodes("/skin/screen")) {
		$name = $s.GetAttribute("name")
		$id = $s.GetAttribute("id")
		$key = "$name|$id"
		if ($screens.ContainsKey($key)) { $warnings.Add("Screen '$name' defined twice ($($screens[$key]) and $f); the later one wins.") }
		$screens[$key] = $f
	}
}
$screenNames = @{}
foreach ($k in $screens.Keys) { $screenNames[$k.Split("|")[0]] = $true }

# Fonts shipped by OpenPLi in /usr/share/fonts.
$systemFonts = @("ae_AlMateen.ttf", "andale.ttf", "DejaVuSans.ttf", "lcd.ttf", "md_khmurabi_10.ttf", "nmsbd.ttf",
	"LiberationSans-Bold.ttf", "LiberationSans-BoldItalic.ttf", "LiberationSans-Italic.ttf", "LiberationSans-Regular.ttf",
	"wqy-microhei.ttc", "tuxtxt.ttf")
foreach ($k in $fonts.Keys) {
	$fn = $fonts[$k]
	if (-not ($systemFonts -contains $fn) -and -not (Test-Path (Join-Path $SkinDir $fn)) -and -not (Test-Path (Join-Path $SkinDir "fonts/$fn"))) {  # enigma2 also searches <skin>/fonts
		$errors.Add("Font '$k' uses '$fn' which is neither in the skin folder nor shipped by OpenPLi.")
	}
}

$colorAttrs = "^(backgroundColor|foregroundColor|borderColor|shadowColor|backgroundColorSelected|foregroundColorSelected|scrollbarSliderForegroundColor|scrollbarSliderBorderColor|timeColor|.*[Cc]olor[A-Za-z]*|color)$"
$checkedPix = @{}
# Images shipped in /usr/share/enigma2/skin_default (enigma2 falls back to these).
$defaultFiles = @(Get-Content (Join-Path $PSScriptRoot "skin_default_files.txt"))

foreach ($f in $docs.Keys) {
	$xml = $docs[$f]
	foreach ($el in $xml.SelectNodes("//*")) {
		# Window style <color name="Background" color="x"/> uses color= for the value.
		foreach ($a in $el.Attributes) {
			$an = $a.Name; $av = $a.Value
			if ($an -match $colorAttrs -and $an -ne "colposition") {
				if ($el.LocalName -eq "color" -and $el.ParentNode.LocalName -eq "colors") { continue }
				if ($el.LocalName -eq "color" -and $an -eq "name") { continue }
				foreach ($cv in $av.Split(",")) {
					$cv = $cv.Trim()
					if ($cv -match "^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$" -or $cv -match "^0x") { continue }
					if ($an -like "Cool*" -and $cv -match "^\d+$") { continue }  # EMC list flags (CoolDateColor="1"), not colours
					if (-not $colors.ContainsKey($cv)) { $errors.Add("${f}: undefined colour '$cv' in <$($el.LocalName)> attribute $an") }
				}
			}
			if ($an -in @("font", "secondfont", "serviceNumberFont", "serviceNameFont", "serviceInfoFont", "setEventItemFont", "setEventTimeFont", "setServiceFont") -or $an -match "Font$") {
				$fname = $av.Split(";")[0]
				if ($el.LocalName -eq "text" -and $fname -match "^\d+$") { $fname = "" }  # XML list templates: font = index into the template's fonts list
				if ($fname -and -not $fonts.ContainsKey($fname)) { $errors.Add("${f}: undefined font '$fname' in <$($el.LocalName)> attribute $an") }
			}
			if ($an -in @("pixmap", "pointer", "selectionPixmap", "backgroundPixmap", "sliderPixmap", "filename", "seek_pointer") -and $el.LocalName -ne "font" -and $el.LocalName -ne "include") {
				$p = $av.Split(":")[0].Replace("#cached", "")
				if ($p -match "^/" -or $p -match "^~/") { continue }  # plugin-supplied, only present if that plugin is installed
				if ($p -match "^\.\./") { $warnings.Add("${f}: '$p' lives outside the skin folder (shared OpenPLi asset).") ; continue }
				if (-not $checkedPix.ContainsKey($p)) {
					$checkedPix[$p] = (Test-Path (Join-Path $SkinDir $p)) -or ($defaultFiles -contains $p)
					if (-not $checkedPix[$p]) {
						$errors.Add("${f}: image '$p' exists neither in the skin folder nor in OpenPLi skin_default.")
					}
				}
			}
		}
		if ($el.LocalName -eq "panel") {
			$pn = $el.GetAttribute("name")
			if ($pn -and -not $screenNames.ContainsKey($pn)) { $errors.Add("${f}: <panel name='$pn'> refers to a screen that does not exist.") }
		}
		# Python template strings: gFont("Name", n)
		if ($el.LocalName -eq "convert" -and $el.InnerText -match "gFont") {
			foreach ($m in [regex]::Matches($el.InnerText, 'gFont\(\s*"([^"]+)"')) {
				if (-not $fonts.ContainsKey($m.Groups[1].Value)) { $errors.Add("${f}: undefined font '$($m.Groups[1].Value)' in a TemplatedMultiContent template") }
			}
		}
	}
}

$warnings | Sort-Object -Unique | ForEach-Object { Write-Host "warn   $_" -ForegroundColor Yellow }
$errors | Sort-Object -Unique | ForEach-Object { Write-Host "ERROR  $_" -ForegroundColor Red }
Write-Host ""
Write-Host ("Screens: {0}  Colours: {1}  Fonts: {2}  Images checked: {3}" -f $screenNames.Count, $colors.Count, $fonts.Count, $checkedPix.Count)
if ($errors.Count) { Write-Host "$(($errors | Sort-Object -Unique).Count) error(s)." -ForegroundColor Red; exit 1 }
Write-Host "No errors." -ForegroundColor Green
exit 0
