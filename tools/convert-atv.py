# Converts OpenATV's embedded (Python) screen skins into Obsidian screens.
# Usage: python convert-atv.py <atv lib/python dir> <ScreenName> [...]
# Output replaces the AUTO block in Obsidian-FHD/skin_openatv.xml.
# Widget names are kept exactly, so mandatoryWidgets stay satisfied; layout is scaled to 1920x1080,
# placed inside the Obsidian card and the coloured key labels are replaced by the Obsidian footer.
import os, re, sys
import xml.etree.ElementTree as ET

SRC, NAMES = sys.argv[1], sys.argv[2:]
OUT = os.path.join(os.path.dirname(__file__), "..", "Obsidian-FHD", "skin_openatv.xml")
CX, CY, CW, CH = 46, 118, 1828, 872          # content area inside the card (30,104 1860x900)
KEYS = {"key_red", "key_green", "key_yellow", "key_blue", "key_menu", "key_info", "key_help",
        "key_text", "key_epg", "key_exit", "key_ok", "key_back"}
LISTATTR = dict(transparent="1", foregroundColorSelected="aWhite", selectionPixmap="window/sel_channel.png",
                scrollbarMode="showOnDemand", scrollbarWidth="4", scrollbarSliderBorderWidth="0",
                scrollbarSliderForegroundColor="aAccent")

def find_screens():
	found = {}
	for root, _, files in os.walk(SRC):
		for f in files:
			if not f.endswith(".py"):
				continue
			txt = open(os.path.join(root, f), encoding="utf-8", errors="ignore").read()
			for m in re.finditer(r'<screen name="([^"]+)".*?</screen>', txt, re.S):
				found.setdefault(m.group(1), m.group(0))
	return found

def num(v, ref, s):
	v = v.strip()
	m = re.fullmatch(r"e(-\d+)?", v)
	if m:
		return ref + int(m.group(1) or 0), True
	if v.startswith("center"):
		return None, False
	return int(float(v)), False

def font(v, s):
	m = re.fullmatch(r"([^;]+);(\d+)", v.strip())
	return "%s;%d" % (m.group(1), round(int(m.group(2)) * s)) if m else v

def convert(name, xml):
	scr = ET.fromstring(xml)
	sw, sh = [int(x) for x in scr.get("size", "1280,720").split(",")]
	s = 1.5 if scr.get("resolution", "1280,720").startswith("1280") else 1.0
	# content height = everything above the key row
	body = []
	for w in scr:
		if w.get("source") in KEYS or w.get("name") in KEYS or w.tag == "eRectangle" and False:
			continue
		body.append(w)
	items = []
	for w in body:
		if not w.get("position") or not w.get("size"):
			continue
		px, py = w.get("position").split(",")
		qx, qy = w.get("size").split(",")
		x, _ = num(px, sw, s); y, _ = num(py, sh, s)
		if x is None or y is None:
			continue
		ww, fullw = num(qx, sw - x, s); hh, _ = num(qy, sh - y, s)
		items.append([w, x, y, ww, hh])
	if not items:
		return None
	maxy = max(y + h for _, _, y, _, h in items if y < sh - 45) if any(y < sh - 45 for _, _, y, _, h in items) else sh
	ow, oh = sw * s, maxy * s
	# the tallest list stretches to use the spare height; things below it move down
	lists = [i for i in items if i[0].get("render") == "Listbox" or i[0].tag == "widget" and i[0].get("name") in ("list", "config", "menu", "filelist", "feedlist", "log", "text")]
	grow = max(0, CH - oh)
	big = max(lists, key=lambda i: i[4]) if lists else None
	out = ET.Element("screen", {"name": name, "title": scr.get("title", ""), "position": "fill", "flags": "wfNoBorder"})
	for p in ("BasicTemplate", "KeyMenuAutoTemplate", "KeyInfoAutoTemplate"):
		ET.SubElement(out, "panel", {"name": p})
	help_ = ET.fromstring('<widget source="key_help" conditional="key_help" render="Pixmap" pixmap="buttons/key_help.png" alphatest="blend" position="30,1031" size="52,38"><convert type="ConditionalShowHide" /></widget>')
	out.append(help_)
	ET.SubElement(out, "eLabel", {"position": "30,104", "size": "1860,900", "backgroundColor": "aCard", "borderWidth": "1",
	                              "borderColor": "aLine", "cornerRadius": "14", "zPosition": "-1"})
	for w, x, y, ww, hh in items:
		if y >= maxy:
			continue
		nx, ny, nw, nh = x * s, y * s, ww * s, hh * s
		sx = CW / ow
		nx, nw = nx * sx, nw * sx                                    # widths fill the card
		if big is not None and w is not big[0] and y >= big[2] + big[4]:
			ny += grow
		if big is not None and w is big[0]:
			nh += grow
		ny = min(ny, CH - 10)
		w.set("position", "%d,%d" % (CX + nx, CY + ny))
		w.set("size", "%d,%d" % (max(nw, 1), max(min(nh, CH - ny), 1)))
		for a in ("font", "fonts"):
			if w.get(a):
				w.set(a, ",".join(font(f, s) for f in w.get(a).split(",")))
		for a in ("foregroundColor", "backgroundColor", "foregroundColorSelected", "backgroundColorSelected", "borderColor", "borderWidth"):
			w.attrib.pop(a, None)
		if w.tag == "eRectangle":
			w.tag = "eLabel"; w.set("backgroundColor", "aLine"); w.set("size", "%d,1" % nw)
			continue
		if w.tag == "ePixmap" or w.get("render") in ("Pixmap", "Picon") or "pixmaps" in w.attrib or "pixmap" in w.attrib:
			continue
		if w.get("render") == "Listbox" or w in [i[0] for i in lists]:
			for k, v in LISTATTR.items():
				w.set(k, v)
			w.set("foregroundColor", "aText"); w.set("backgroundColor", "aCard")
			for t in w.iter("template"):
				for a in ("itemHeight", "itemWidth"):
					if t.get(a):
						t.set(a, str(round(int(t.get(a)) * s)))
				if t.get("fonts"):
					t.set("fonts", ",".join(font(f, s) for f in t.get("fonts").split(",")))
				for e in t.iter():
					if e.get("position") and e.get("size"):
						ex, ey = [int(v) for v in e.get("position").split(",")]
						ew, eh = [int(v) for v in e.get("size").split(",")]
						ex, ew = ex * s * sx, ew * (s * sx if e.tag == "text" else s)
						e.set("position", "%d,%d" % (ex, ey * s)); e.set("size", "%d,%d" % (ew, eh * s))
		else:
			w.set("foregroundColor", "aVariant" if w.get("name") == "description" or w.get("source") == "description" else "aText")
			w.set("backgroundColor", "aCard"); w.set("transparent", "1")
		out.append(w)
	return out

found = find_screens()
mine = open(OUT, encoding="utf-8").read()
mine = re.sub(r"\t<!-- AUTO:BEGIN.*?AUTO:END -->\n", "", mine, flags=re.S)
blocks = []
for n in NAMES:
	if n not in found:
		print("missing", n); continue
	scr = convert(n, found[n])
	if scr is None:
		print("skip", n); continue
	ET.indent(scr, "\t", 1)
	blocks.append("\t" + ET.tostring(scr, encoding="unicode"))
	print("ok", n)
auto = "\t<!-- AUTO:BEGIN generated by tools/convert-atv.py, do not edit by hand -->\n" + "\n".join(blocks) + "\n\t<!-- AUTO:END -->\n"
mine = mine.replace("</skin>", auto + "</skin>")
open(OUT, "w", encoding="utf-8", newline="\n").write(mine)
