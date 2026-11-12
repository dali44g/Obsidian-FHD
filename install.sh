#!/bin/sh
# Obsidian FHD installer / updater for enigma2 (OpenATV, OpenPLi and others).
# Usage on the receiver (SSH or telnet):
#   wget -qO- https://raw.githubusercontent.com/dali44g/Obsidian-FHD/main/install.sh | sh
# Installs or updates the skin, updates the style packs that are already installed (e.g. Edge), then the installed Obsidian apps.
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
PACKS="enigma2-plugin-skins-obsidian-fhd-edge enigma2-plugin-skins-obsidian-fhd-nova enigma2-plugin-skins-obsidian-fhd-k7 enigma2-plugin-skins-obsidian-fhd-synthwave enigma2-plugin-skins-obsidian-fhd-matchday"

WORK=$(mktemp -d /tmp/obsidian-install.XXXXXX) || exit 1
trap 'rm -rf "$WORK"' EXIT
trap 'exit 1' HUP INT TERM

# Last download fallback: Python's own HTTPS client
PY_FETCH='import sys;u=sys.version_info[0]>2 and __import__("urllib.request").request or __import__("urllib2");d=u.urlopen(sys.argv[1],timeout=30).read();open(sys.argv[2],"wb").write(d)'

# fetch <package> -> $WORK/<package>_all.ipk, only a real package ("!<arch>" header; not an error page or empty file).
# Network time limits so a stuck download cannot hang the receiver.
fetch() {
	FILE="$WORK/$1_all.ipk"
	for URL in "$RELEASE/$1_all.ipk" "$REPO/$1_all.ipk"; do
		rm -f "$FILE"
		# wget first; curl when wget is missing or fails (e.g. an old BusyBox wget without HTTPS)
		{ command -v wget >/dev/null 2>&1 && wget -T 30 -t 1 -q -O "$FILE" "$URL"; } ||
			{ command -v curl >/dev/null 2>&1 && curl -fsSL --connect-timeout 15 --max-time 120 -o "$FILE" "$URL"; } ||
			python3 -c "$PY_FETCH" "$URL" "$FILE" 2>/dev/null || python -c "$PY_FETCH" "$URL" "$FILE" 2>/dev/null
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
# 1.6.3: the Customise previews of the style packs moved into the packs. opkg removes them from an
# opkg install; a skin copied by hand keeps them, so delete the old names (about 1 MB).
for F in preview_chlist_edge preview_chlist_nova preview_infobar_novao preview_chlist_k7 preview_infobar_k7 \
	preview_menu_synthwave preview_chlist_synthwave preview_infobar_synthwave \
	preview_menu_matchday preview_chlist_matchday preview_infobar_matchday; do
	rm -f "/usr/share/enigma2/Obsidian-FHD/apps/$F.jpg"
done
# Obsidian apps that are already installed (Posters, Mawaqit, Cast, Dock...): update them to the version of the
# same release, so the apps always match the skin. An app that is not installed is never added. Each app is checked
# against the checksum in apps.json and installed on its own: if one fails, it stays as it was and the rest goes on.
update_apps() {
	PY=$(command -v python3 || command -v python) || return 0
	CAT="$WORK/apps.json"
	for URL in "$RELEASE/apps.json" "$REPO/apps.json"; do
		rm -f "$CAT"
		{ command -v wget >/dev/null 2>&1 && wget -T 30 -t 1 -q -O "$CAT" "$URL"; } ||
			{ command -v curl >/dev/null 2>&1 && curl -fsSL --connect-timeout 15 --max-time 60 -o "$CAT" "$URL"; } ||
			"$PY" -c "$PY_FETCH" "$URL" "$CAT" 2>/dev/null
		[ -s "$CAT" ] && "$PY" -c 'import json,sys;json.load(open(sys.argv[1]))' "$CAT" 2>/dev/null && break
		rm -f "$CAT"
	done
	[ -s "$CAT" ] || { echo "Obsidian apps: the app list could not be downloaded; update them from Obsidian Apps."; return 0; }
	# installed apps as "package=version" (opkg), then the ones the release has newer: "package file sha256 version"
	ARGS=""
	for P in $("$PY" -c 'import json,sys;print(" ".join(a["package"] for a in json.load(open(sys.argv[1])).get("apps",[]) if a.get("package")))' "$CAT"); do
		V=$(opkg status "$P" 2>/dev/null | grep -q "^Status:.* installed" && opkg status "$P" | sed -n 's/^Version: *//p' | head -n 1)
		[ -n "$V" ] && ARGS="$ARGS $P=$V"
	done
	[ -n "$ARGS" ] || return 0
	TODO=$("$PY" - "$CAT" $ARGS <<'PYEOF'
import json, re, sys
def key(v):
	return [int(x) for x in re.findall(r"\d+", v or "")]
have = dict(a.split("=", 1) for a in sys.argv[2:])
for a in json.load(open(sys.argv[1])).get("apps", []):
	p = a.get("package")
	if p in have and key(a.get("version")) > key(have[p]) and a.get("file") and a.get("sha256"):
		print("%s %s %s %s" % (p, a["file"], a["sha256"], a["version"]))
PYEOF
)
	[ -n "$TODO" ] || { echo "Obsidian apps: up to date."; return 0; }
	echo "$TODO" | while read -r P F SUM VER; do
		[ -n "$P" ] || continue
		FILE="$WORK/app_$F"
		OK=""
		for URL in "$RELEASE/$F" "$REPO/$F"; do
			rm -f "$FILE"
			{ command -v wget >/dev/null 2>&1 && wget -T 30 -t 1 -q -O "$FILE" "$URL"; } ||
				{ command -v curl >/dev/null 2>&1 && curl -fsSL --connect-timeout 15 --max-time 120 -o "$FILE" "$URL"; } ||
				"$PY" -c "$PY_FETCH" "$URL" "$FILE" 2>/dev/null
			if [ -s "$FILE" ] && [ "$(dd if="$FILE" bs=7 count=1 2>/dev/null)" = "!<arch>" ]; then
				GOT=$( { sha256sum "$FILE" 2>/dev/null || "$PY" -c 'import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$FILE"; } | cut -d' ' -f1)
				[ "$GOT" = "$SUM" ] && OK=1 && break
			fi
		done
		if [ -z "$OK" ]; then
			echo "Obsidian apps: $P $VER could not be downloaded or failed the check; it stays as it was."
		elif opkg install --force-reinstall "$FILE"; then
			echo "Obsidian apps: $P updated to $VER."
		else
			echo "Obsidian apps: $P $VER failed to install; it stays as it was."
		fi
		rm -f "$FILE"
	done
}
update_apps

echo ""
echo "Done. Select Obsidian-FHD in the skin settings (or restart the GUI if it is already active)."
