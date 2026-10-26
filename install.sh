#!/bin/sh
# Obsidian FHD installer / updater for enigma2 (OpenATV, OpenPLi and others).
# Usage on the receiver (SSH or telnet):
#   wget -qO- https://raw.githubusercontent.com/dali44g/Obsidian-FHD/main/install.sh | sh
# Installs or updates the skin, and updates the style packs that are already installed (e.g. Edge).
# All or nothing: every package is downloaded first; if one download fails, nothing on the receiver is changed.
# Each package comes from the latest GitHub Release (GitHub counts these downloads), with the copy in the repository
# as a fallback (no release yet, or an old wget that cannot follow GitHub's redirect).
RELEASE="https://github.com/dali44g/Obsidian-FHD/releases/latest/download"
# Testing a pre-release: /etc/enigma2/obsidian-test-server (absent for users) holds "github:<tag>" or "http(s)://<server>/".
if [ -f /etc/enigma2/obsidian-test-server ]; then
	TEST=$(head -n 1 /etc/enigma2/obsidian-test-server | tr -d ' \r')
	case "$TEST" in
		*[!A-Za-z0-9.:/_-]*) TEST="" ;;  # only plain addresses (letters, digits . : / _ -)
	esac
	case "$TEST" in
		github:?*) RELEASE="https://github.com/dali44g/Obsidian-FHD/releases/download/${TEST#github:}" ;;
		http://?*|https://?*) RELEASE="${TEST%/}" ;;
	esac
	[ "$RELEASE" != "https://github.com/dali44g/Obsidian-FHD/releases/latest/download" ] && echo "Test source: $RELEASE"
fi
REPO="https://raw.githubusercontent.com/dali44g/Obsidian-FHD/main/release"
SKIN="enigma2-plugin-skins-obsidian-fhd"
PACKS="enigma2-plugin-skins-obsidian-fhd-edge"

WORK=$(mktemp -d /tmp/obsidian-install.XXXXXX) || exit 1
trap 'rm -rf "$WORK"' EXIT
trap 'exit 1' HUP INT TERM

# fetch <package> -> $WORK/<package>_all.ipk, only a real package ("!<arch>" header; not an error page or empty file).
# Network time limits so a stuck download cannot hang the receiver.
fetch() {
	FILE="$WORK/$1_all.ipk"
	for URL in "$RELEASE/$1_all.ipk" "$REPO/$1_all.ipk"; do
		rm -f "$FILE"
		# wget first; curl when wget is missing or fails (e.g. an old BusyBox wget without HTTPS)
		{ command -v wget >/dev/null 2>&1 && wget -T 30 -t 1 -q -O "$FILE" "$URL"; } ||
			{ command -v curl >/dev/null 2>&1 && curl -fsSL --connect-timeout 15 --max-time 120 -o "$FILE" "$URL"; }
		if [ -s "$FILE" ] && [ "$(dd if="$FILE" bs=7 count=1 2>/dev/null)" = "!<arch>" ]; then
			return 0
		fi
	done
	rm -f "$FILE"
	return 1
}

installed() {
	opkg status "$1" 2>/dev/null | grep -q "^Status:.* installed"
}

LIST="$SKIN"
for P in $PACKS; do
	installed "$P" && LIST="$LIST $P"
done

echo "Downloading Obsidian FHD ..."
for P in $LIST; do
	if ! fetch "$P"; then
		echo "Download failed ($P). Nothing was changed. Check the internet connection of the receiver."
		exit 1
	fi
done

FREE_KB=$(df -k /usr/share/enigma2 | awk 'NR==2 {print $4}')
if [ -n "$FREE_KB" ] && [ "$FREE_KB" -lt 6000 ]; then
	echo "Not enough free space on the receiver (${FREE_KB} KB free, about 6 MB needed). Nothing was changed."
	exit 1
fi

# Upgrade the skin and its installed packs in one solver transaction: an old
# Edge pack requires the old skin version until both packages are replaced.
set --
for P in $LIST; do
	set -- "$@" "$WORK/${P}_all.ipk"
done
opkg install --force-reinstall "$@"
RC=$?
if [ $RC -ne 0 ]; then
	echo "Installation failed (Obsidian FHD and installed style packs, opkg exit code $RC)."
	exit $RC
fi
echo ""
echo "Done. Select Obsidian-FHD in the skin settings (or restart the GUI if it is already active)."
