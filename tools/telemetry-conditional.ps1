# Makes tuner telemetry (SNR / AGC / BER labels, values and meter tracks) hide itself when
# there is no tuner data, e.g. on IPTV streams. Idempotent.
$SkinDir = Join-Path $PSScriptRoot "..\Obsidian-FHD" | Resolve-Path
$targets = @{
	"skin_templates.xml" = @("InfoBarTemplate", "ChannelSelectionTemplate")
	"skin.xml" = @("ChannelSelectionRadio")
	"..\tools\screens-obsidian.xml" = @("ChannelSelectionRadio")
}
$labelType = @{ "SNR" = "SNR"; "AGC" = "AGC"; "BER" = "BER"; "TUNERS" = "LOCK"; "RF" = "LOCK" }
$count = 0
foreach ($f in $targets.Keys) {
	$path = Join-Path $SkinDir $f
	$x = New-Object System.Xml.XmlDocument; $x.PreserveWhitespace = $true; $x.Load($path)
	foreach ($sn in $targets[$f]) {
		$s = $x.SelectSingleNode("/skin/screen[@name='$sn']")
		if (-not $s) { continue }
		# Remember which meter each track belongs to (track sits at the same position as its Progress).
		$progressAt = @{}
		foreach ($w in $s.SelectNodes("widget[@render='Progress' and @source='session.FrontendStatus']")) {
			$progressAt[$w.GetAttribute("position")] = $w.SelectSingleNode("convert[@type='FrontendInfo']").InnerText
		}
		foreach ($el in @($s.ChildNodes | Where-Object { $_.NodeType -eq "Element" })) {
			$kind = $null
			if ($el.LocalName -eq "eLabel" -and $labelType.ContainsKey($el.GetAttribute("text"))) { $kind = $labelType[$el.GetAttribute("text")]; $render = "FixedLabel" }
			elseif ($el.LocalName -eq "ePixmap" -and $el.GetAttribute("pixmap") -eq "infobar/seg_track.png" -and $progressAt.ContainsKey($el.GetAttribute("position"))) { $kind = $progressAt[$el.GetAttribute("position")]; $render = "Pixmap" }
			if ($kind) {
				$w = $x.CreateElement("widget")
				$w.SetAttribute("source", "session.FrontendStatus"); $w.SetAttribute("render", $render)
				foreach ($a in $el.Attributes) { $w.SetAttribute($a.Name, $a.Value) }
				foreach ($t in @($kind, "")) {
					$c = $x.CreateElement("convert")
					if ($t) { $c.SetAttribute("type", "FrontendInfo"); $c.InnerText = $t } else { $c.SetAttribute("type", "ConditionalShowHide") }
					[void]$w.AppendChild($c)
				}
				[void]$s.ReplaceChild($w, $el); $count++
				continue
			}
			# Value labels / meters fed by FrontendInfo SNR/AGC/BER/SNRdB: add ConditionalShowHide.
			if ($el.LocalName -eq "widget" -and $el.GetAttribute("source") -eq "session.FrontendStatus") {
				$fi = $el.SelectSingleNode("convert[@type='FrontendInfo']")
				if ($fi -and $fi.InnerText -in @("SNR", "AGC", "BER", "SNRdB") -and -not $el.SelectSingleNode("convert[@type='ConditionalShowHide']") -and $el.GetAttribute("render") -ne "Progress") {
					$c = $x.CreateElement("convert"); $c.SetAttribute("type", "ConditionalShowHide"); [void]$el.AppendChild($c); $count++
				}
			}
		}
	}
	$settings = New-Object System.Xml.XmlWriterSettings; $settings.Encoding = New-Object System.Text.UTF8Encoding($false)
	$wr = [System.Xml.XmlWriter]::Create($path, $settings); $x.Save($wr); $wr.Close()
}
Write-Host "Telemetry elements made conditional: $count"
