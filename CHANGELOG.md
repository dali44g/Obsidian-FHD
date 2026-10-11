# Changelog

All notable changes to Obsidian FHD. To update, run the install command from the README again.

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
