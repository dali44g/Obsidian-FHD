# Menu artwork: one 160x160 icon per OpenATV menu key (mainmenu/<key>.png), loaded by
# Screens/Menu.py for list rows and for the large "menuimage" of the focused entry.
# Dot-sourced from gen-graphics.ps1 (generator functions available).
# Style: light line glyph with an accent detail, optionally on a dark round badge.

function MenuGlyph([string]$rel, [string]$kind) {
	$cv = New-Canvas 160 160; $g = $cv[1]
	if ($MenuBadge -ne $false) {  # optional round badge behind the glyph ($MenuBadge = $false draws the glyph alone)
		$g.FillEllipse((Brush $C.card2), 4, 4, 152, 152)
		$g.DrawEllipse((PenOf $C.line2 2), 5, 5, 150, 150)
	}
	$p = RoundPen $C.text 7; $a = RoundPen $C.accent 7; $sun = Brush $C.accent
	switch ($kind) {
		"info" { $g.DrawEllipse($p, 46, 46, 68, 68); $g.DrawLine($p, 80, 74, 80, 98); $g.FillEllipse($sun, 75, 56, 10, 10) }
		"timer" { $g.DrawEllipse($p, 44, 46, 72, 72); $g.DrawLines($a, [System.Drawing.PointF[]]@((PF 80 60), (PF 80 82), (PF 96 92))); $g.DrawLine($p, 70, 38, 90, 38) }
		"gear" {
			for ($i = 0; $i -lt 8; $i++) { $t = $i * [math]::PI / 4; $g.DrawLine($p, (80 + 30 * [math]::Cos($t)), (80 + 30 * [math]::Sin($t)), (80 + 42 * [math]::Cos($t)), (80 + 42 * [math]::Sin($t))) }
			$g.DrawEllipse($p, 52, 52, 56, 56); $g.FillEllipse($sun, 72, 72, 16, 16)
		}
		"screen" { $g.DrawPath($p, (RoundRect 38 48 84 56 6)); $g.DrawLine($p, 64, 118, 96, 118); $g.DrawLine($a, 80, 104, 80, 118) }
		"audio" {
			$g.DrawPolygon($p, [System.Drawing.PointF[]]@((PF 44 68), (PF 60 68), (PF 80 52), (PF 80 108), (PF 60 92), (PF 44 92)))
			$g.DrawArc($a, 76, 62, 36, 36, -50, 100); $g.DrawArc($p, 72, 48, 60, 64, -50, 100)
		}
		"rec" { $g.DrawEllipse($p, 44, 44, 72, 72); $g.FillEllipse((Brush $C.rec), 62, 62, 36, 36) }
		"film" { $g.DrawPath($p, (RoundRect 42 50 76 60 6)); foreach ($x in 50, 70, 90, 110) { $g.FillRectangle($sun, ($x - 4), 42, 8, 6); $g.FillRectangle($sun, ($x - 4), 112, 8, 6) }; $g.DrawPolygon($p, [System.Drawing.PointF[]]@((PF 72 68), (PF 92 80), (PF 72 92))) }
		"chip" { $g.DrawPath($p, (RoundRect 52 52 56 56 6)); foreach ($o in 62, 80, 98) { $g.DrawLine($p, $o, 40, $o, 52); $g.DrawLine($p, $o, 108, $o, 120); $g.DrawLine($p, 40, $o, 52, $o); $g.DrawLine($p, 108, $o, 120, $o) }; $g.FillRectangle($sun, 70, 70, 20, 20) }
		"disk" { $g.DrawPath($p, (RoundRect 40 54 80 52 8)); $g.FillEllipse($sun, 98, 82, 10, 10); $g.DrawLine($p, 52, 70, 84, 70) }
		"guide" { foreach ($y in 56, 80, 104) { $g.DrawLine($p, 44, $y, 116, $y) }; $g.DrawLine($a, 44, 56, 76, 56); $g.DrawLine($a, 92, 80, 116, 80) }
		"dish" { $g.DrawArc($p, 40, 40, 72, 72, 45, 180); $g.DrawLine($p, 54, 54, 104, 104); $g.DrawLine($p, 78, 78, 108, 56); $g.FillEllipse($sun, 102, 48, 14, 14); $g.DrawLine($p, 80, 112, 80, 124) }
		"key" { $g.DrawEllipse($p, 40, 58, 40, 40); $g.DrawLine($p, 80, 78, 122, 78); $g.DrawLine($a, 108, 78, 108, 94); $g.DrawLine($a, 120, 78, 120, 90) }
		"lock" { $g.DrawArc($p, 58, 40, 44, 50, 180, 180); $g.DrawLine($p, 58, 66, 58, 74); $g.DrawLine($p, 102, 66, 102, 74); $g.DrawPath($p, (RoundRect 48 74 64 46 6)); $g.FillEllipse($sun, 74, 90, 12, 12) }
		"box" { $g.DrawPolygon($p, [System.Drawing.PointF[]]@((PF 80 40), (PF 118 58), (PF 118 102), (PF 80 120), (PF 42 102), (PF 42 58))); $g.DrawLines($p, [System.Drawing.PointF[]]@((PF 42 58), (PF 80 76), (PF 118 58))); $g.DrawLine($a, 80, 76, 80, 120) }
		"update" { $g.DrawArc($p, 44, 44, 72, 72, 200, 270); $g.DrawLines($a, [System.Drawing.PointF[]]@((PF 56 46), (PF 48 62), (PF 64 66))); $g.DrawLine($p, 80, 66, 80, 94); $g.DrawLines($p, [System.Drawing.PointF[]]@((PF 70 76), (PF 80 66), (PF 90 76))) }
		"backup" { $g.DrawLine($p, 80, 42, 80, 92); $g.DrawLines($a, [System.Drawing.PointF[]]@((PF 64 76), (PF 80 92), (PF 96 76))); $g.DrawLines($p, [System.Drawing.PointF[]]@((PF 44 96), (PF 44 116), (PF 116 116), (PF 116 96))) }
		"globe" { $g.DrawEllipse($p, 44, 44, 72, 72); $g.DrawEllipse($p, 64, 44, 32, 72); $g.DrawLine($p, 44, 80, 116, 80); $g.FillEllipse($sun, 104, 44, 14, 14) }
		"power" { $g.DrawArc($p, 46, 48, 68, 68, -55, 290); $g.DrawLine($a, 80, 38, 80, 80) }
		"remote" { $g.DrawPath($p, (RoundRect 60 36 40 88 12)); $g.FillEllipse($sun, 73, 48, 14, 14); foreach ($y in 76, 92, 108) { $g.FillEllipse((Brush $C.text), 70, $y, 6, 6); $g.FillEllipse((Brush $C.text), 84, $y, 6, 6) } }
		"lang" { $g.DrawPath($p, (RoundRect 38 46 60 44 8)); $g.DrawPath($a, (RoundRect 66 76 56 40 8)); $g.DrawLine($p, 52, 62, 82, 62); $g.DrawLine($p, 52, 74, 74, 74) }
		"list" { foreach ($y in 56, 80, 104) { $g.FillEllipse($sun, 44, ($y - 5), 10, 10); $g.DrawLine($p, 64, $y, 116, $y) } }
		"stack" { foreach ($y in 50, 74, 98) { $g.DrawPath($p, (RoundRect 46 $y 68 16 4)) }; $g.FillEllipse($sun, 100, 102, 8, 8) }
		"logs" { $g.DrawPath($p, (RoundRect 50 40 60 80 6)); foreach ($y in 60, 76, 92) { $g.DrawLine($p, 62, $y, 98, $y) }; $g.DrawLine($a, 62, 106, 84, 106) }
		"cec" { $g.DrawPath($p, (RoundRect 36 50 60 40 6)); $g.DrawPath($p, (RoundRect 82 74 42 34 6)); $g.DrawLine($a, 66, 98, 90, 98) }
		"plugin" { $g.DrawPath($p, (RoundRect 46 46 30 30 5)); $g.DrawPath($p, (RoundRect 84 46 30 30 5)); $g.DrawPath($p, (RoundRect 46 84 30 30 5)); $g.FillPath($sun, (RoundRect 84 84 30 30 5)) }
		"palette" { $g.DrawEllipse($p, 42, 44, 76, 72); foreach ($d in @(@(62, 62), @(86, 58), @(98, 80))) { $g.FillEllipse($sun, $d[0], $d[1], 12, 12) }; $g.FillEllipse((Brush $C.card2), 60, 88, 18, 18); $g.DrawEllipse($p, 60, 88, 18, 18) }
		default { $g.FillEllipse($sun, 70, 70, 20, 20) }
	}
	Save-Canvas $cv $rel
}

$menuKinds = [ordered]@{
	info = "information build_info_screen commit_info_screen debug_info_screen distribution_info_screen geolocation_info_screen memory_info_screen network_info_screen picture_info_screen receiver_info_screen service_info_screen storage_info_screen streaming_info_screen system_info_screen translation_info_screen tuner_info_screen multiboot_info_screen"
	timer = "timermenu timer_edit crontimer_edit powertimer_edit time_setup sleep"
	gear = "setup user_interface usage_setup specialfeatures_menu extended osdsetup setup_osd3d display_setup led_setup"
	screen = "video_menu video_setup hdmirecord_setup scart_switch rfmod_setup"
	audio = "audio_menu audio_setup volume_adjust autolanguage_setup subtitle_setup"
	rec = "rec recording_setup timshift_setup"
	film = "movie_selection playback_setup"
	chip = "system device_setup"
	disk = "harddisk device_manager swap_manager SDswap flash_expander"
	guide = "epg epg_setup setup_epgenhanced setup_epggraphical setup_epginfobar setup_epginfobargraphical setup_epgmulti setup_epgvertical deleteepgcache loadepgcache saveepgcache"
	dish = "scan auto_scan manual_scan tuner_setup tuner_basic_settings fallbacktuner_settings"
	key = "cam softcam_settings cardserver_settings cccam_info oscam_info autocam_settings softcsa_settings streamrelay_settings ci_selection"
	lock = "parental_setup password_setup"
	box = "software_manager manage_plugins package_manager install_local advanced_software"
	update = "software_update upgrade_settings upgrade_source flash_online"
	backup = "backup_additional backup_default backup_excluded backup_image backup_image_dbackup backup_image_dflash backup_system restore_system software_restore advanced_restore factory_reset"
	globe = "network dns_setup Inadyn_setup netsamba_setup netushare_setup networkservices_setup minidlna_setup zerotier_setup wol_standby"
	power = "shutdown standby deep_standby restart restart_enigma maintenance_mode"
	remote = "remote_setup remotecode buttonsetup_setup keyboard input_device_setup"
	lang = "locale_setup"
	list = "channelselection_setup"
	stack = "multiboot chkroot_multiboot kexec_multiboot"
	logs = "logs_setup script_manager"
	cec = "hdmicec"
	plugin = "plugin_selection"
	palette = "skin_setup"
}
foreach ($kind in $menuKinds.Keys) { foreach ($key in ($menuKinds[$kind] -split " ")) { MenuGlyph "mainmenu/$key.png" $kind } }
MenuGlyph "mainmenu/missing.png" "plugin"
