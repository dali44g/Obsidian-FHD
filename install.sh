#!/bin/sh
# Obsidian FHD installer / updater for enigma2 (OpenATV, OpenPLi and others).
# Usage on the receiver (SSH or telnet):
#   wget -qO- https://raw.githubusercontent.com/dali44g/Obsidian-FHD/main/install.sh | sh
URL="https://raw.githubusercontent.com/dali44g/Obsidian-FHD/main/release/enigma2-plugin-skins-obsidian-fhd_all.ipk"
IPK="/tmp/enigma2-plugin-skins-obsidian-fhd_all.ipk"

echo "Downloading Obsidian FHD ..."
rm -f "$IPK"
if command -v wget >/dev/null 2>&1; then
	wget -q -O "$IPK" "$URL"
else
	curl -fsSL -o "$IPK" "$URL"
fi
if [ ! -s "$IPK" ]; then
	echo "Download failed. Check the internet connection of the receiver."
	exit 1
fi

FREE_KB=$(df -k /usr/share/enigma2 | awk 'NR==2 {print $4}')
if [ -n "$FREE_KB" ] && [ "$FREE_KB" -lt 6000 ]; then
	echo "Not enough free space on the receiver (${FREE_KB} KB free, about 6 MB needed)."
	rm -f "$IPK"
	exit 1
fi

opkg install --force-reinstall "$IPK"
RC=$?
rm -f "$IPK"
if [ $RC -ne 0 ]; then
	echo "Installation failed (opkg exit code $RC)."
	exit $RC
fi
echo ""
echo "Done. Select Obsidian-FHD in the skin settings (or restart the GUI if it is already active)."
