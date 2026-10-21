# Changelog

All notable changes to Obsidian FHD. To update, run the install command from the README again.

## 1.5.2

**Channel list**
- Redesigned the channel information card with a framed picon, clearer channel name, provider and technical details.
- Added the current programme description and kept the next three events. Removed the prime-time event.
- Improved provider visibility and masked sensitive information in displayed IPTV URLs.
- Fixed cut-off transponder information during channel scanning.

**EPG and playback**
- Styled the graphical EPG with TV preview to match Obsidian.
- Improved the movie playback infobar with a clearer background, progress bar, times and remote controls.
- Replaced an incompatible converter option that could hide the playback progress bar on PurE2.

**Compatibility and reliability**
- Improved PurE2 compatibility for Skin Setup, infobar style selection and Softcam information.
- Refreshes the saved infobar style at GUI startup and adapts to changes in optional components.
- Preserves text when automatic text fitting is unavailable.

## 1.5.1

**New**
- Permanent Clock in Obsidian Apps: Minimal, Flip and Stacked designs, with white or yellow digits, three sizes, left / centre / right positions and optional seconds. Settings have a live preview, Save and Cancel; saved changes apply without a GUI restart.
- The clock is time-only, with borderless digits and translucent Flip cards. It hides in standby and with other skins, and pauses when the separate Permanent Clock plugin is enabled. The separate plugin keeps its own appearance.
- Channel lists show the next three EPG events and the programme airing at prime time. The image's graphical EPG prime-time setting is used when available (otherwise 20:15); after that time, the following evening is shown. Uses only the receiver's local EPG data.
- Provider information in the channel list and Halo, Glass and Nova infobars, where supplied by the service.

**Improvements and fixes**
- Receiver identification prefers image hardware metadata over legacy compatibility aliases, avoiding incorrect Vu+ model names on other receivers.
- Broader temperature and fan RPM detection, including thermal, hwmon and HiSilicon sources. Missing readings show N/A; sensor discovery is cached.
- Classic channel list: removed the duplicate transponder frequency and signal panel to make room for the guide.
- Floating channel list: the upcoming-events card hides with the current-programme card when the selected channel has no EPG.
- PurE2: added compatible skin-selector and remote-button setup screens.
- Floating skin selection now appears over live TV, with its preview inside the settings card instead of covering the title and help.
- Halo infobar: the missing-EPG placeholder no longer overlaps programme times.

## 1.5.0

**New**
- Obsidian Apps: a new main-menu entry replaces "Obsidian FHD Settings". A grid of apps with on / off switches (Weather, Bitrate, Floating menu, Floating channel list, About & update); each app has its own page with a preview, details and a Turn on / off button. In English, French and Arabic.
- About & update: shows the installed version, checks for a newer release, installs it, and YELLOW opens What's new (this changelog).
- Floating channel list (optional, off by default): the channel list as floating cards over live TV, with a programme card for the selected channel and colour keys; MENU opens the channel options in the same style.
- With the Floating menu, settings pages and option lists are floating too: a help card with the description of the selected setting, the settings card, and a key card.
- New key bar: short coloured pills and the action text instead of boxes, and key chips (OK / EXIT / MENU) on Obsidian's own screens.
- Install extensions (OpenATV) in the Obsidian layout.
- Infobar styles in Obsidian Apps: Halo (new default: solid dark bars with a soft teal light), Glass (the see-through bars of earlier versions) and Nova (one floating indigo capsule with a progress ring, clock and today's weather, no top bar).
- Install plugin from Obsidian Apps: the Weather and Bitrate pages can install OAWeather / BitrateViewer without leaving the screen.
- Signal finder in the Obsidian design: coloured SNR / AGC bars, measurements card with a LOCK badge, tuning card.

**Fixes**
- Header: long screen titles no longer run into the tuner letters on IPTV channels or without signal.
- Infobar on OpenBH and other images: long codec names (e.g. "MPEG4 H.264") no longer wrap, and multi-line ECM info shows only its first line.

## 1.4.1

**Fixes**
- OpenViX and OpenBH: the skin did not load ("Tag 'font' needs an existing filename"). System fonts missing on an image are now replaced by fonts bundled in the skin; images that have them (OpenATV, OpenPLi) keep exactly the same fonts.
- OpenATV: frequency and symbol rate in the infobar, second infobar and menu header show 12558 / 27500 instead of 12558000 / 27500000.
- OpenPLi: the header boxes and the signal card no longer show "Project-Id-Version: enigma2 ..." text, and the main menu shows its icons instead of small white marks.
- Obsidian FHD Settings: if the screen cannot open, a message now shows the reason instead of nothing happening.

**New**
- Bitrate: video and audio bitrate in a small card under the clock (or under the weather bar) and in the second infobar, on satellite, cable and terrestrial channels. Needs the BitrateViewer plugin; on/off in Obsidian FHD Settings ("Show bitrate in infobar").
- AutoTimer overview: every AutoTimer shows all its lines (name and time, days, channels), with a legend card for the icons.

## 1.4.0

**New: Floating menu (optional, Classic stays the default)**
- Menu cards floating over live TV, with a header (menu icon, menu name, clock) and a clear selected row.
- Submenus open in their own card beside a small card showing where you are (for example "Main Menu > Setup").
- Live dashboard beside the main menu:
  - temperature, CPU load, fan speed and uptime
  - RAM ring, flash space (with a LOW warning) and up to 3 disks found automatically (SSD / HDD / USB / SD, with the drive model)
  - network card: IP address, interface, download and upload speed, ONLINE / OFFLINE badge
- Footer with the skin version, your image and your receiver.
- Texts follow the receiver language: English, French and Arabic.
- Turn it on: Menu → Setup → Usage & GUI (OpenPLi: Setup → System) → Obsidian FHD Settings → Menu style → Floating.

**Obsidian FHD Settings**
- New "Menu style" option (Classic / Floating) next to "Show weather in infobar".
- The weather bar can now be hidden here without disabling the OAWeather plugin.
- About card with the skin version and links.
- Update check: when a newer version is published, the Floating menu footer and the About card say so, and YELLOW (Update now) installs it.

**Infobar**
- SNR / AGC signal meters are now solid rounded bars instead of segments.
- Second infobar on OpenATV: removed the "Invalid type" text (the HDR/SDR line now shows only on OpenPLi).

**Other**
- Settings lists from plugins that set no font of their own (E2iPlayer and others) now use a readable value font.
- Updating or reinstalling the skin no longer resets your Obsidian FHD settings.

**Privacy note:** the ONLINE badge checks the connection by briefly connecting to a public DNS server (1.1.1.1 or 8.8.8.8) at most once a minute, only while the Floating menu is open. Nothing is sent.

## 1.3.2

**Fixes for OpenATV 8**
- Main menu: the highlight is stuck on "Information" and does not move with UP/DOWN. Fixed; it also works on OpenATV 7.x and OpenPLi as before.
- Second infobar: the CAID line on the right is empty on OpenATV. It now shows the CA system, CAID, provider and SID (for example `Conax:0B00:…`, or `FTA` on free channels).
- "2nd InfoBar ECM" setting: it showed OpenATV's default screen instead of the Obsidian one. Fixed.
- Menu header on satellite: the SNR / AGC / BER box stayed empty. It now shows the values whenever a tuner is locked.

**Weather bar**
- Forecast days use short names (Sun, Mon / dim., lun.) with bigger weather icons. Arabic keeps the full day names, because the short Arabic form is a single letter.

**Tip:** to see the CAID and ECM details, set Menu → Setup → System → OSD settings → Second InfoBar to "2nd InfoBar ECM", then press OK twice.

## 1.3.1

**Top of the screen**
- New top status bar, matching the infobar: today's weather (icon, temperature, condition, city, feels like),
  a 5-day forecast and the clock with date and STREAM / LOCK. It replaces the dark fade in the top-left corner.
- Without the OAWeather plugin, the clock shows as a small floating card instead.
- Full day names in the forecast (Arabic previously showed only one letter).

**Fixes**
- OpenATV 8: pressing OK in the main menu always opened "Information". The highlighted entry now opens.
- Channel list: the programme title on the selected row is now green, so it stands apart from the channel name.
- Background jobs screen (copy, download, backup progress) now shows its information on OpenATV.
- Removed a skin error on OpenATV caused by the satellite position line (it still shows on OpenPLi).

## 1.3

**Weather (requires the OAWeather plugin; nothing changes without it)**
- Weather in the infobar.
- OAWeather overview, favourites, hourly detail and detail popup screens redesigned in the Obsidian style.

**Other**
- Arabic text now uses the Noto Kufi Arabic font; English and French keep the current fonts.
- Virtual keyboard: typed letters are visible again.
- Satellite: SNR and AGC numbers next to the signal bars whenever a tuner is locked.
- EMC (Enhanced Movie Center) settings screen in the Obsidian layout.

## 1.2

- Rounded "pill" highlight with cyan text on every list, replacing the old selection bar.
- Menu icons for each entry (OpenATV and OpenPLi).
- Infobar without programme guide: shows "LIVE · No programme guide for this channel" instead of empty space.
- Channel list: programme text of the selected row highlighted.
- Picon tile with the channel number below it in the infobar.
- Default picon for channels without a logo.
- Vertical volume indicator.
- Screenshots added to the README.

## 1.1

- First public release on GitHub.
- One-command installer (`install.sh`) and a ready-to-install package.
- Redesigned screens: history zap list, plugin installer, processing popup, skin settings with preview,
  audio and subtitle selection.
- Channel list RF card with SNR and AGC bars while a tuner is locked.
- Licence: CC BY-NC-SA 4.0.
