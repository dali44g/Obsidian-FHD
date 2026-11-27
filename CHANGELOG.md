# Changelog

All notable changes to Obsidian FHD. To update, run the install command from the README again.

## 1.8.1

**New**
- Slate style pack: dark look with big cards for menus, settings, channel list and infobar
  - 4 colours: Terracotta, Ice, Amber, Jade (Obsidian Apps > Styles)
  - main menu as a card row or a sidebar over live TV, with receiver stats
  - channel list layouts: Mini TV, Open and Cards
- Posters 1.1.0: film backdrops in the Floating and Slate channel lists (off by default)
- Live Subtitles 1.1.0
  - 25 languages, spoken and subtitles (before: 7 spoken, translated to English, French or Arabic)
  - works on satellite and terrestrial (DVB) channels, in Live and Synced mode (Synced needs a timeshift folder on USB or hard disk)
  - new: Persian, Portuguese, Dutch, Bulgarian, Croatian, Serbian, Bosnian, Slovenian, Macedonian, Albanian, Romanian, Greek, Polish, Czech, Slovak, Hungarian, Ukrainian, Russian
  - new PC translator (version 3): all languages on your PC, models download on demand
  - one-line PC setup for Windows, Mac and Linux; guides in English, French and Arabic
  - speech models: Recommended (adapts to your PC), Base, Small, Medium or Custom
  - DASH channels say so and play directly; the setup page shows the PC's progress
  - cloud fallback is now off by default
- Dock 1.1.0: Slate theme, and a subtitle Offset row for the current channel

**Changed**
- Obsidian Apps and Styles open faster
- Customise page: the selection moves at once, the preview follows

**Fixed**
- Posters: better matching of Arabic and other non-Latin titles (reported by Enigma Architect)
- Quad PiP editor: cut or overlapping text (reported by mohamedothman)
- Halo, Glass, Cinema and Edge: long programme titles now scroll (suggested by saragusa)
- Edge main menu: the selected item's right edge is no longer cut (reported by saragusa)
- Cinema infobar: channel name stays beside the picon on all images; shorter no-guide view (reported by saragusa)
- OpenATV: the dish movement popup no longer stays on screen (reported by mj_84)
- PIN screen: digits are no longer cut
- Live Subtitles: untranslated, hidden or blank subtitles in some cases

## 1.8.0

**New**
- Obsidian Live Subtitles app (beta): subtitles for channels that have none, made from the channel's speech, in its language or translated into yours
  - speech recognition on your own PC (Docker, everything stays at home) or with a free Groq key (cloud)
  - uses the channel's own subtitles when it sends them (WebVTT and CEA-608 captions on IPTV)
  - Synced mode: the picture is held a few seconds so the words match the lips (IPTV through the receiver's relay)
  - several Groq keys: when one reaches the free limit, the next takes over at once
  - can pause by itself when the channel already speaks the subtitle language: your choice with the Same language setting (Pause subtitles / Show subtitles)
  - comes back by itself after a network drop
  - Groq key entered from your phone with a QR code; log shared to a phone with secrets removed
- Obsidian Stream app (beta): watch this receiver's channels on your phone, tablet or another TV at home, in an IPTV app such as TiviMate, IPTV Smarters or VLC (Xtream Codes login or M3U link, with the TV guide and picons)
  - one device at a time: live TV pauses on the receiver while a device watches and comes back by itself when it stops; OK on the remote takes the TV back
  - home network only, off until you turn it on, with its own password; it passes your own subscription to one device at a time and adds no viewers
  - tested with IPTV channels; satellite channels have not been tested yet
  - French and Arabic
- Dock 1.0.2: new Live Subtitles shortcut (when that app is installed): a card shows whether the subtitles are on, OK starts or stops them, without leaving live TV
- Obsidian Apps: a "Need help?" button (HELP key) on each app page and About: it shows a QR code that opens that app's guide on the new website on your phone, in the language of your menus
- OpenPLi: support its Bitrate plugin in infobar measurements and compact/full windows; weather city falls back when the provider omits the observation point, with OAWeather-Pli setup guidance (reported by sety)
- Posters 1.0.5: independent Now/Next artwork in the second infobar across all styles; text cards stay full width when artwork is unavailable (suggested by mohamedothman)
- Bitrate: new Position setting (Obsidian Apps > Bitrate, YELLOW): keep the card under the clock, or show one short line in the Classic infobar under SNR / AGC (suggested by raboha)
- Nova infobar: decryption info line (CI module, card or softcam, e.g. "CI0") above the capsule, left of the chips; shown only on channels where the receiver reports it, so free and IPTV channels stay as before (suggested by وليد شنب)
- Floating menu: a card with the description of the selected entry (main menu and submenus), hidden when the entry has none (idea by mj_84)
- Halo and Glass infobars: SD and 4K badges (4K also on HDR / HLG channels), and a 4:3 badge next to 16:9 (reported by mj_84)

**Changed**
- Top bar of the channel list, event view and menus: the date in the infobar's style (TUE  17.11.2026), a little larger (idea by mj_84)
- Menu icons (Classic, Floating, Edge): about 1.5x larger symbols, same row sizes (suggested by brahimi Miloud)
- Window title bar: taller (52 px), with a larger title and accent line
- Obsidian Apps: apps can bring their own tile, page art and preview
- Dock 1.0.2: the Apps card shows an add-on's own icon (Live Subtitles showed the generic one); French and Arabic

**Fixed**
- Halo and Glass infobars: include SDR / HDR / HDR10 / HLG from service metadata on OpenPLi as well as OpenATV; separate and widen the SNR percentage and dB fields, including when the image swaps their order (reported by Dervis)
- Second infobar: the lower infobar uses its no-poster layout in every style, keeping raised artwork and poster panels out of the telemetry card (reported by mohamedothman)
- Glass/Halo: TMDB metadata and satellite details use separate rows; decryption and audio information keep their own space (reported by mohamedothman)
- Edge channel list: reserve progress space in single-line and two-line rows without widening the sidebar or changing image settings (reported by mohamedothman)
- Dashboard fan: unavailable RPM readings are explained instead of displaying N/A; zero RPM remains a valid reading (reported by mohamedothman)
- Timeshift: hide the live TV infobar while the timeshift controls are shown, preventing overlapping channel details and clocks (reported by Mohamedzalata)
- Posters 1.0.4 and Cast 1.0.2: the hard disk was refused as "on the receiver flash" when the image runs from that disk (OpenMultiboot, EgamiBoot, NeoBoot), and each disk is listed once (reported by mahermotawea86, sat_abdel, 1995Gh3ssan and sety)
- Cinema infobar: a few words of Arabic programme descriptions (or a long channel name) no longer show in the top-left corner of the screen (reported by naf2010)
- Cinema infobar: the second infobar no longer overlaps its ECM / telemetry card; it shows the compact channel layout (the programme is in the cards above) (reported by saragusa)
- Halo and Glass infobars: the REC badge shows again during a recording when the weather bar is on (it was hidden behind the bar); it now sits just under the bar (reported by mj_84)
- Halo and Glass infobars: the resolution badge is wider, so SDR / HLG / HDR10 after the resolution are no longer cut off (reported by mj_84 and Dervis)
- Floating menu dashboard (and K7): the network card shows the connection in use (the default route), not a switched-off Wi-Fi stick, and its download / upload rates again
- Posters 1.0.4 and Mawaqit 1.1.2: the phone QR code showed "No network" on some receivers connected by cable; the receiver's address is now also read from the network card, and another port is used when the usual one is taken (reported by Kamelrasul)
- OpenATV 7.6 / 8: Parental control, OpenWebif, File Commander and Nameserver setup screens use the Obsidian design again (the image refused them for two missing fields), and pictures some plugin screens asked for but the skin did not ship are no longer requested

**Website**
- New website with a guide for each app, in English, French and Arabic; the "Need help?" QR on the receiver opens it
- Weather and Bitrate have their own guide pages; new Permanent clock page
- Live Subtitles guide: install, settings, privacy and troubleshooting, plus a step-by-step PC server setup (Docker Desktop, two copy-paste commands, Groq vs PC comparison) and help when Docker Desktop does not start on Windows (WSL, virtualisation)

## 1.7.2

**New**
- Obsidian Dock app: a shortcut strip over live TV, with Apps, Plugins, Audio and Subtitles cards; follows your style, or pick the Glass or Depth look
- Cinema infobar: a new style with the film poster and rating (Obsidian Posters), or the picon when there is none; weather and bitrate
- Synthwave infobar: today's weather (temperature and icon) under the date, with OAWeather
- Matchday infobar: a weather tab on the clock panel (icon, city, temperature), with OAWeather

**Changed**
- Messages: rounded card and lighter icons
- Obsidian Apps: 12 apps per page (4 × 3 grid), more pages when needed; the page number is in the footer
- Obsidian Apps: performance optimized (faster cards, smoother navigation), with updated Posters 1.0.3, Mawaqit 1.1.1 and Cast 1.0.1
- Style packs: updated with their Dock look
- Wi-Fi Scan (OpenATV 8): new Obsidian layout with the band and a clearer signal
- Halo infobar: the day next to the time, the date as 12.11.2026 and larger, a larger resolution badge (reported by mj_84)
- Nova infobar: larger signal bars and SNR / AGC values (reported by ozgurc67)

**Fixes**
- Style packs: the download no longer asks for 10 MB of free space, 2 MB is enough (the packs are under 1 MB) (reported by hamid735)
- Nova infobar: the temperature no longer hides under the weather icon (reported by waelb)
- Nova infobar: long translations of NEXT (Turkish SONRAKİ) no longer break onto two lines (reported by ozgurc67)
- Date and Time Settings (OpenATV): the date and time format options are now shown (reported by Genaro75)
- Style packs: when a pack needs a newer skin, the message now says to update the skin first, instead of blaming the internet connection
- Posters: drives linked into /media are found, and when no drive can be used the message says why for each one (read-only, full...) (reported by mahermotawea86)
- Plugins, apps and style packs install with Flash Expander: the free space is checked where they go (/usr), not on the flash

## 1.7.1

- Performance improvements: lighter on CPU and memory, as fast as early versions again.
- Faster zapping and smoother scrolling.
- Faster channel list and menus.
- K7 style pack: same performance improvements.
- Obsidian Posters 1.0.1: no more short freezes when zapping, lighter poster cache.

## 1.7.0

**New**
- Obsidian Posters app: a film or series poster, rating and short plot with the infobar. Needs your own free TMDB key, entered from your phone with a QR code.
- Poster modes for the Glass, Halo, Nova, K7, Matchday and Synthwave infobars.
- Matchday style pack: sports TV look for the menus, settings, channel list and infobar, with live receiver stats.
- Obsidian Cast app: send a photo from your phone to the TV by scanning a code. OK shows it full screen, Green saves it to USB or HDD. Home network only.

**Changed**
- Messages now appear in a small centred card; long text scrolls (idea by mahermotawea86).
- OpenATV: network screens redesigned in the Obsidian style.
- Classic channel list: five upcoming programmes and scrolling descriptions (idea by mj_84).
- Classic channel list: channels without guide data show their satellite or stream details, plus SNR and AGC when playing.
- Second infobar: long descriptions scroll (idea by mj_84).
- Synthwave infobar: frequency and signal bar, hidden on IPTV (idea by dragonfb).
- Smaller skin download (about 0.7 MB less): style pack previews now come with each pack.
- Obsidian Apps: OK opens Mawaqit and Cast directly; Yellow opens their settings.
- Mawaqit: sign in and choose your mosque from your phone with a QR code.

**Fixes**
- OpenPLi: GUI crash when opening some menu entries (reported by kamaxx and Dervis).
- Halo and Glass infobars: no more N/A for BER on IPTV.
- OpenBH and OpenPLi: selection bar missing in 2-line Floating and Nova channel lists (reported by fadhel1974).
- Style pack download: clearer error messages.
- Downloads and updates: Python fallback when wget and curl fail, and the real error is shown (reported by kamaxx and onur1995).

## 1.6.3

**New**
- Synthwave style pack: neon 80s menus, settings pages with live hardware info, channel list and infobar. Mix it with other styles in Styles > Customise.

**Changed**
- K7 infobar: shows the temperature in the LCD when OAWeather is set up; the channel number moves next to the name (suggested by damirlja).
- Floating channel list: the next five programmes, and long descriptions scroll so they can be read in full (suggested by Moost).
- New option to hide the clock at the top right of the Halo and Glass infobars (Menu > Obsidian Apps > Styles > Customise) (suggested by MakaveliTheDon).
- Styles: new 4-column layout; the Look page is now called Customise.

**Fixes**
- K7 infobar: the progress bar shows again on OpenATV 8.0.1 (reported by damirlja).
- Second infobar: the next programme's title shows again on OpenATV 8 (reported by mj_84).
- Online update works on OpenPLi when wget fails ("Connection reset by peer") (reported by kamaxx).
- Settings: slider bars no longer cover the setting names (reported by Bella Italia).
- Footer keys: long translations such as Greek are no longer cut off (reported by W@Rp).
- Nova infobar: no more "n/a" when OAWeather isn't set up.
- OpenPLi: no more crash risk in the Classic and Edge menus when menu numbers are on.
- Styles: the K7 download size shows 0.4 MB.

## 1.6.2

**New**
- Nova style pack: the Nova infobar in purple or Obsidian colours, and a Nova channel list on a starry sky with a mini TV.
- K7 style pack: silver / olive console menus, channel list and infobar with LCD readouts.
- Look page (Obsidian Apps > Styles): mix your own style from different packs.

**Changed**
- Styles cards show which parts each style has (menus, channel list, infobar) and which ones are in use.
- The Infobar style app moved to the Look page. Your current choices are kept.
- The new Obsidian logo on the GUI restart screen and as the picon of channels without one.
- The Nova infobar moved into the Nova style pack. If you used it, you get the Glass infobar after updating; download Nova from Obsidian Apps > Styles to get it back.

**Fixes**
- Channel list: the provider of the selected satellite channel is shown again instead of "-" (read from the channel list when the image does not report it).
- Classic channel list: the info card shows the frequency of the channel you browse to (e.g. 16.0°E · 11595 V 30000), not only the one you watch (requested by mj_84).
- Infobar: the duplicate video size under the tuners is replaced by the BER value (signal errors), next to SNR and AGC.
- OpenATV Image Backup: the list rows are tall enough for their text (reported by Bella Italia).
- Updating with a style pack installed: the skin and its packs are now installed together, so the update cannot stop halfway.

## 1.6.1

**Fixes**
- OpenPLi scarthgap: installing, updating and downloading styles no longer fail with "Download failed" (the image's BusyBox has no `head -c`) (reported by sety).
- OpenBH and OpenPLi: fixed a GUI crash when opening Setup or other submenus with the Edge style (reported by naf2010 and sety).
- OpenBH: the Device Manager (Extra Settings) and its mountpoint setup are now designed full screen with device icons, instead of showing an empty screen (reported by fadhel1974).
- OpenATV zap history: channel names and programme details remain visible when a channel has no picon (reported by Greenwich).
- Channel provider (Classic, Floating and Edge): when stored provider information is missing, the highlighted channel can use live provider information only if its full service reference matches the currently playing channel. Other channels never inherit the playing channel's provider.
- Infobar (standard and Nova): the next programme now shows its start and end times beside the NEXT label, with its duration displayed separately on the right. Nova now includes the next programme's duration too.

**EPG**
- Graphical EPG, infobar EPG (OpenATV) and GraphMultiEPG (OpenPLi): the channel being watched is marked by its cyan name only, no longer with the same teal background as the selection, which looked like a channel selector stuck on that row.
- Graphical EPG (OpenATV) and GraphMultiEPG (OpenPLi): the information panel shows the picon and name of the channel under the cursor, because the image does not highlight the selected channel in the channel column.

**Channel list**
- Classic channel list: the progress bar of the selected channel keeps a visible track instead of a solid cyan bar.

## 1.6.0

**New: Edge style (free download from Obsidian Apps)**
- A new full look for the main menu, submenus, settings screens and the channel list: dark panels, a hardware panel with CPU and memory rings and a network chart, a path sidebar that shows where you are in the menus, and coloured key chips.
- Edge channel list: a panel over live TV with an information card for the selected channel (current and next three programmes, picon, delivery, provider), and a plain teal selection that fits every row height.
- Edge is a separate style pack: it is downloaded only when you choose it, and removed again in one step. Packs always come from the same release as the skin.

**New: Styles app**
- Obsidian Apps has one Styles app with a card per style (Classic, Floating, Edge), an "IN USE" ribbon and a page per style to use, download or remove it. Menus and the channel list can each use a different style.
- Settings pages of apps show a scrollbar when there are more settings than fit on the page.

**New: Obsidian Mawaqit (free add-on, installed from Obsidian Apps)**
- Prayer times of your mosque from mawaqit.net: sign in once with your MAWAQIT account (only a token is kept, never the password) and search your mosque by name or city, also in Arabic.
- A full-screen prayer screen (Courtyard theme) with the current time, the next prayer and its countdown, Shuruq and Jumu'a, the Hijri date and iqama times, plus a Display mode for a receiver used as a prayer-times screen.
- Over live TV: the day's prayers beside the picture with the infobar, an optional next-prayer tab at the top right, a reminder card that stays from 5 minutes before the adhan (5 to 20 minutes, or only at the adhan), and adhan and iqama alerts (a flashing card, then a countdown to the iqama). The flashing time can be set.
- English, French and Arabic. Nothing is shown until you are signed in and have chosen a mosque.

**Infobar**
- The infobar shows the current audio track: language, codec and track number when there are several (for example FRA · AC3 · 2/3) (idea by mj_84).
- The second infobar labels the PIDs (SID, VPID, APID, PCR, TSID, ONID) instead of showing bare numbers (idea by mj_84).
- The menu dashboard shows a memory ring on every image, the CPU load, the temperature, the tuners and the network link speed.

**Channel list**
- The current programme next to each channel is shown in amber instead of dark grey, readable on the dark list in every channel list style (reported by Adnan1980).
- The channel information card is hidden on bouquets, providers, satellites and empty lists instead of showing an empty card.
- The prime-time programme is back in the channel information card, a resolution chip was added, the satellite is shown once, and "-" is shown when a channel has no provider (tester feedback).

**EPG**
- OpenATV and PurE2: Obsidian designs for the vertical EPG, the infobar EPG and the quick EPG.

**Compatibility and reliability**
- OpenBH: the Green Panel is now full screen like the plugin browser, with larger text, icons and descriptions (reported by naf2010).
- Fixed a GUI crash when a short choice message opened on OpenBH and EGAMI, for example Image Manager > Downloads on OpenBH 6 (reported by lordfayez1212 and الفاضل1900).
- OpenBH and OpenPLi: the skin selection list shows the skin name and its status instead of the preview file path on OpenBH (reported by lordfayez1212).
- Installing and updating downloads from the latest GitHub Release, with the repository copy as a fallback; every package is downloaded before anything is changed, with network time limits.

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
