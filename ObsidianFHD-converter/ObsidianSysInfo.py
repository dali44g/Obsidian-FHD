# -*- coding: utf-8 -*-
# Obsidian FHD system information for the menu dashboard (skin_sysinfo.xml).
# Reads /proc and statvfs (no shell); network use only for the online badge and the update check, see their classes.
# Every value falls back to "" / 0, so a missing sensor or file can never raise into enigma2. Refreshes every 10 s while a screen using it is shown.
#
#   <convert type="ObsidianSysInfo">Temp</convert>        text  "31 degrees C"
#   CpuLoad, Fan, Uptime, Ip                              text
#   RamText, FlashText, SsdText, UsbText                          text  "355 / 560 MB", "22 MB free"
#   RamPercent "27%", RamStep "0".."20" (ring image index)
#   RamUsed, FlashUsed, SsdUsed, UsbUsed                         value 0..100 for render="Progress"
#   NetDown, NetUp                                        text  "5.2 Mbit/s" (average since the previous sample)
#   NetIface                                              text  "Ethernet - eth0"
#   Disk1..3 (boolean, row present), DiskName1..3 "SSD" / "USB 2" / "+2 more", DiskText1..3 "54 GB free",
#   DiskModel1..3 "Kingston DataTraveler 3.0", DiskUsed1..3 (value 0..100): local disks under /media, internal first
#   SkinVersion"v1.4", ImageInfo "OpenATV 8.0.1 - Vu+ Solo2"  text
#   Online, Offline                                      boolean (internet reachable / not; both False until checked)
#   Update (boolean, newer release on GitHub), UpdateText "Update v1.4.1 available"
#   FlashLow                                              boolean (free flash < 15 MB) for ConditionalShowHide
from os import statvfs
from os.path import exists, ismount

from Components.Converter.Converter import Converter
from Components.Converter.Poll import Poll
from Components.Element import cached

SSD = "/media/hdd"

# Non-ASCII text built from escapes so the file stays plain ASCII; Python 2 images (OpenATV 6, OpenPLi 7) need UTF-8 str.
try:
	unicode
	DOT = u"\u00b7".encode("utf-8")
	DEG = u"\u00b0".encode("utf-8")
except NameError:
	DOT = "\u00b7"
	DEG = "\u00b0"

USB = "/media/usb"


def readFirst(paths):
	for path in paths:
		try:
			with open(path) as f:
				value = f.read().strip()
			if value:
				return value
		except Exception:
			pass
	return ""


def memInfo():
	data = {}
	try:
		with open("/proc/meminfo") as f:
			for line in f:
				parts = line.split()
				if len(parts) >= 2:
					data[parts[0].rstrip(":")] = int(parts[1])
	except Exception:
		pass
	total = data.get("MemTotal", 0)
	avail = data.get("MemAvailable", data.get("MemFree", 0) + data.get("Cached", 0))
	return total // 1024, max(0, total - avail) // 1024


def diskInfo(path):
	try:
		st = statvfs(path)
		total = st.f_blocks * st.f_frsize
		free = st.f_bavail * st.f_frsize
		return total, free
	except Exception:
		return 0, 0


def sizeText(size):
	mb = size / 1048576.0
	return "%.1f GB" % (mb / 1024) if mb >= 1024 else "%d MB" % mb


class NetSampler(object):
	# Byte counters of the busiest real interface from /proc/net/dev. One shared sample per poll interval,
	# so every widget shows the same, exact average rate (bytes difference / elapsed time).
	last = None  # (time, iface, rx, tx)
	rate = (0.0, 0.0)  # bit/s down, up
	iface = ""

	@classmethod
	def counters(cls):
		best = None
		try:
			with open("/proc/net/dev") as f:
				for line in f.readlines()[2:]:
					name, data = line.split(":", 1)
					name = name.strip()
					if name == "lo" or name.startswith(("sit", "tun", "docker")):
						continue
					values = data.split()
					rx, tx = int(values[0]), int(values[8])
					if best is None or rx + tx > best[1] + best[2]:
						best = (name, rx, tx)
		except Exception:
			pass
		return best

	@classmethod
	def sample(cls):
		from time import time
		now = time()
		if cls.last and now - cls.last[0] < 5:
			return cls.rate
		cur = cls.counters()
		if cur:
			name, rx, tx = cur
			if cls.last and cls.last[1] == name and rx >= cls.last[2] and tx >= cls.last[3]:
				dt = now - cls.last[0]
				cls.rate = ((rx - cls.last[2]) * 8 / dt, (tx - cls.last[3]) * 8 / dt)
			else:
				cls.rate = (0.0, 0.0)  # first sample, interface change or counter reset
			cls.last = (now, name, rx, tx)
			cls.iface = name
		return cls.rate


class InternetCheck(object):
	# Internet reachability for the network badge: a TCP connection attempt to public DNS servers (no data is
	# sent) at most once a minute, in a background thread so the screen never waits. None until the first result.
	state = None
	checked = 0.0
	running = False

	@classmethod
	def get(cls):
		from time import time
		if not cls.running and time() - cls.checked > 60:
			cls.running = True
			try:
				from threading import Thread
				t = Thread(target=cls.run)
				t.daemon = True
				t.start()
			except Exception:
				cls.running = False
		return cls.state

	@classmethod
	def run(cls):
		import socket
		from time import time
		result = False
		for host in ("1.1.1.1", "8.8.8.8"):
			try:
				s = socket.create_connection((host, 53), timeout=3)
				s.close()
				result = True
				break
			except Exception:
				pass
		cls.state = result
		cls.checked = time()
		cls.running = False


class UpdateCheck(object):
	# Latest released version, read from a one-line file in the public repository (only that small file is fetched,
	# nothing is sent). Background thread, 5 s timeout; at most every 6 hours, 30 minutes after a failure. Runs only
	# while the Floating main menu or Obsidian FHD Settings is open. latest is "" until a result exists.
	URL = "https://raw.githubusercontent.com/dali44g/Obsidian-FHD/main/release/version.txt"
	latest = ""
	checked = 0.0
	wait = 0
	running = False

	@classmethod
	def get(cls):
		from time import time
		if not cls.running and time() - cls.checked > cls.wait:
			cls.running = True
			try:
				from threading import Thread
				t = Thread(target=cls.run)
				t.daemon = True
				t.start()
			except Exception:
				cls.running = False
		return cls.latest

	@classmethod
	def run(cls):
		import re
		from time import time
		ok = False
		try:
			try:
				from urllib.request import urlopen
			except ImportError:
				from urllib2 import urlopen
			# Verified HTTPS only; on an image without CA certificates the check simply stays silent.
			data = urlopen(cls.URL, timeout=5).read(64)
			m = re.match(r"\s*([0-9]+(\.[0-9]+){0,3})\s*$", data.decode("ascii", "ignore") if isinstance(data, bytes) else data)
			if m:
				cls.latest = m.group(1)
				ok = True
		except Exception:
			pass
		cls.checked = time()
		cls.wait = 21600 if ok else 1800
		cls.running = False


def versionTuple(text):
	try:
		parts = [int(x) for x in text.lstrip("v").split(".")]
		return tuple(parts + [0] * (4 - len(parts)))
	except Exception:
		return ()


def updateAvailable():
	# Newer release than the installed skin: its version ("1.4.1"), otherwise "".
	latest = UpdateCheck.get()
	current = versionTuple(skinVersion())
	return latest if latest and current and versionTuple(latest) > current else ""


class Disks(object):
	# Local disks mounted under /media (USB sticks, internal HDD/SSD, SD cards), one entry per device, the internal
	# /media/hdd first. Network shares, RAM disks and autofs are skipped: statvfs on them can block or is meaningless.
	cache = (0.0, [])
	PREFIXES = ("/dev/sd", "/dev/mmcblk", "/dev/nvme", "/dev/hd")

	@classmethod
	def kind(cls, device):
		try:
			from os.path import realpath
			name = device.split("/")[-1]
			disk = name.rstrip("0123456789")
			if disk.startswith(("mmcblk", "nvme")) and "p" in name:
				disk = name.rsplit("p", 1)[0]
			if disk.startswith("mmcblk"):
				return "SD"
			path = realpath("/sys/block/%s/device" % disk)  # works whether /sys/block/sdX is a link or a directory
			if "/usb" in path:
				return "USB"
			return "SSD" if readFirst(("/sys/block/%s/queue/rotational" % disk,)) == "0" else "HDD"
		except Exception:
			return "DISK"

	@classmethod
	def model(cls, device):
		# "Kingston DataTraveler 3.0" from /sys/block/<disk>/device/{vendor,model}. The vendor "ATA" (internal SATA)
		# and generic placeholders are dropped; all-caps brand words are tidied ("KINGSTON" -> "Kingston").
		try:
			name = device.split("/")[-1]
			disk = name.rstrip("0123456789")
			if disk.startswith(("mmcblk", "nvme")) and "p" in name:
				disk = name.rsplit("p", 1)[0]
			vendor = readFirst(("/sys/block/%s/device/vendor" % disk,))
			model = readFirst(("/sys/block/%s/device/model" % disk, "/sys/block/%s/device/name" % disk))
			words = []
			for part in (vendor, model):
				for w in part.split():
					if w.upper() in ("ATA", "GENERIC", "USB", "MASS", "STORAGE", "DEVICE", "DISK", "FLASH"):
						continue
					if w.isalpha() and w.isupper() and len(w) > 3:
						w = w.capitalize()
					if w.lower() not in [x.lower() for x in words]:
						words.append(w)
			return " ".join(words)
		except Exception:
			return ""

	@classmethod
	def get(cls):
		from time import time
		now = time()
		if now - cls.cache[0] < 5:
			return cls.cache[1]
		found, seen = [], set()
		try:
			with open("/proc/mounts") as f:
				for line in f:
					parts = line.split()
					if len(parts) < 3:
						continue
					device, mount = parts[0], parts[1]
					if not device.startswith(cls.PREFIXES) or not mount.startswith("/media/") or mount.startswith(("/media/net", "/media/autofs")):
						continue
					if device in seen:
						continue
					seen.add(device)
					found.append((device, mount))
		except Exception:
			pass
		found.sort(key=lambda d: (d[1] != "/media/hdd", d[1]))
		disks, counts = [], {}
		for device, mount in found:
			kind = cls.kind(device)
			counts[kind] = counts.get(kind, 0) + 1
			total, free = diskInfo(mount)
			if total:
				disks.append([kind, counts[kind], total, free, cls.model(device)])
		for d in disks:  # number only kinds that appear more than once: USB 1, USB 2
			d[0] = "%s %d" % (d[0], d[1]) if counts[d[0]] > 1 else d[0]
		cls.cache = (now, disks)
		return disks

	@classmethod
	def row(cls, index):
		disks = cls.get()
		return disks[index] if index < len(disks) else None



# Dashboard labels in French and Arabic (English is the key). Escaped so the source stays ASCII.
TRANSLATIONS = {
	"MAIN MENU": (u"MENU PRINCIPAL", u"\u0627\u0644\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629"),
	"TEMP": (u"TEMP", u"\u0627\u0644\u062d\u0631\u0627\u0631\u0629"),
	"Board sensor": (u"Capteur carte", u"\u0645\u0633\u062a\u0634\u0639\u0631 \u0627\u0644\u0644\u0648\u062d\u0629"),
	"Load, 1 min": (u"Charge, 1 min", u"\u0627\u0644\u062d\u0645\u0644\u060c \u062f\u0642\u064a\u0642\u0629"),
	"FAN": (u"VENTILO", u"\u0627\u0644\u0645\u0631\u0648\u062d\u0629"),
	"UPTIME": (u"EN MARCHE", u"\u0645\u062f\u0629 \u0627\u0644\u062a\u0634\u063a\u064a\u0644"),
	"Since boot": (u"Depuis d\u00e9marrage", u"\u0645\u0646\u0630 \u0627\u0644\u0625\u0642\u0644\u0627\u0639"),
	"SYSTEM": (u"SYST\u00c8ME", u"\u0627\u0644\u0646\u0638\u0627\u0645"),
	"NETWORK": (u"R\u00c9SEAU", u"\u0627\u0644\u0634\u0628\u0643\u0629"),
	"DOWNLOAD": (u"DESCENDANT", u"\u062a\u0646\u0632\u064a\u0644"),
	"UPLOAD": (u"MONTANT", u"\u0631\u0641\u0639"),
	"Average, 10 s": (u"Moyenne, 10 s", u"\u0645\u062a\u0648\u0633\u0637 10 \u062b"),
	"ONLINE": (u"EN LIGNE", u"\u0645\u062a\u0635\u0644"),
	"OFFLINE": (u"HORS LIGNE", u"\u063a\u064a\u0631 \u0645\u062a\u0635\u0644"),
	"LOW": (u"BAS", u"\u0645\u0646\u062e\u0641\u0636"),
	"free": (u"libre", u"\u0645\u062a\u0627\u062d"),
	"not mounted": (u"non mont\u00e9", u"\u063a\u064a\u0631 \u0645\u0648\u0635\u0648\u0644"),
	"more": (u"autres", u"\u0623\u062e\u0631\u0649"),
	"Update %s available": (u"Mise \u00e0 jour %s disponible", u"\u062a\u062d\u062f\u064a\u062b %s \u0645\u062a\u0627\u062d"),
	"d": (u"j", u"\u064a"),
	"h": (u"h", u"\u0633"),
	"m": (u"min", u"\u062f"),
	"HINTS_OK": (u"Ouvrir", u"\u0641\u062a\u062d"),
	"HINTS_EXIT": (u"Retour", u"\u0631\u062c\u0648\u0639"),
	"HINTS_MENU": (u"Fermer", u"\u0625\u063a\u0644\u0627\u0642"),
}


def language():
	try:
		from Components.Language import language as lang
		return (lang.getLanguage() or "")[:2]
	except Exception:
		return ""


def tr(key):
	# Translated label for the box language (fr / ar), otherwise the English key. UTF-8 str on Python 2.
	lang = language()
	text = key
	if lang in ("fr", "ar") and key in TRANSLATIONS:
		text = TRANSLATIONS[key][0 if lang == "fr" else 1]
	elif key.startswith("HINTS_"):
		text = {"HINTS_OK": "Open", "HINTS_EXIT": "Back", "HINTS_MENU": "Close"}.get(key, key)
	try:
		unicode
		return text.encode("utf-8") if isinstance(text, unicode) else text
	except NameError:
		return text
_skinVersion = None


def skinVersion():
	# Read once from the "OBSIDIAN FHD  vX.Y" header text, the single place the version is written.
	global _skinVersion
	if _skinVersion is None:
		_skinVersion = ""
		try:
			import re
			with open("/usr/share/enigma2/Obsidian-FHD/skin_templates.xml") as f:
				m = re.search(r"OBSIDIAN FHD\s+v([0-9][0-9.]*)", f.read())
			if m:
				_skinVersion = "v" + m.group(1)
		except Exception:
			pass
	return _skinVersion


def imageInfo():
	info = {}
	try:
		with open("/etc/image-version") as f:
			for line in f:
				if "=" in line:
					k, v = line.strip().split("=", 1)
					info[k] = v
	except Exception:
		pass
	distro, version = info.get("distro", ""), info.get("version", "")
	if not distro:
		parts = readFirst(("/etc/issue",)).splitlines()
		words = parts[-1].split() if parts else []
		distro, version = (words[0], words[1]) if len(words) >= 2 else ("", "")
	names = {"openatv": "OpenATV", "openpli": "OpenPLi", "openvix": "OpenViX", "openbh": "OpenBH", "egami": "EGAMI"}
	image = ("%s %s" % (names.get(distro.lower(), distro), version)).strip()
	model = readFirst(("/proc/stb/info/vumodel", "/proc/stb/info/boxtype", "/proc/stb/info/model"))
	model = ("Vu+ " + model.capitalize()) if model and exists("/proc/stb/info/vumodel") else model
	return ("  " + DOT + "  ").join(x for x in (image, model) if x)


def rateText(bits):
	if bits >= 1000000:
		return "%.1f Mbit/s" % (bits / 1000000.0)
	if bits >= 1000:
		return "%d kbit/s" % (bits / 1000)
	return "%d bit/s" % bits


class ObsidianSysInfo(Poll, Converter):
	def __init__(self, type):
		Converter.__init__(self, type)
		Poll.__init__(self)
		self.type = type
		self.poll_interval = 10000
		self.poll_enabled = True

	def ssdMounted(self):
		return ismount(SSD)

	@cached
	def getText(self):
		try:
			t = self.type
			if t.startswith("Label:"):
				return tr(t[6:])
			if t == "Hints":
				return "OK  %s     EXIT  %s     MENU  %s" % (tr("HINTS_OK"), tr("HINTS_EXIT"), tr("HINTS_MENU"))
			if t == "Temp":
				raw = readFirst(("/proc/stb/sensors/temp0/value", "/proc/stb/fp/temp_sensor", "/sys/devices/virtual/thermal/thermal_zone0/temp"))
				if not raw:
					return ""
				value = int(raw.split()[0])
				return "%d %sC" % (value // 1000 if value > 1000 else value, DEG)
			if t == "CpuLoad":
				raw = readFirst(("/proc/loadavg",))
				return raw.split()[0] if raw else ""
			if t == "Fan":
				raw = readFirst(("/proc/stb/fp/fan_speed",))
				return raw.split()[0] if raw else ""
			if t == "Uptime":
				raw = readFirst(("/proc/uptime",))
				if not raw:
					return ""
				secs = int(float(raw.split()[0]))
				days, rest = divmod(secs, 86400)
				return "%d%s %d%s" % (days, tr("d"), rest // 3600, tr("h")) if days else "%d%s %d%s" % (rest // 3600, tr("h"), (rest % 3600) // 60, tr("m"))
			if t == "Ip":
				return self.ip()
			if t[:9] == "DiskModel" and t[9:].isdigit():
				index = int(t[9:]) - 1
				if index == 2 and len(Disks.get()) > 3:
					return ""
				row = Disks.row(index)
				return row[4] if row else ""
			if t[:8] in ("DiskName", "DiskText") and t[8:].isdigit():
				index = int(t[8:]) - 1
				disks = Disks.get()
				if index == 2 and len(disks) > 3 and t.startswith("DiskName"):
					return "+%d %s" % (len(disks) - 2, tr("more"))
				if index == 2 and len(disks) > 3:
					return ""
				row = Disks.row(index)
				if not row:
					return ""
				return row[0] if t.startswith("DiskName") else "%s %s" % (sizeText(row[3]), tr("free"))
			if t == "UpdateText":
				latest = updateAvailable()
				return tr("Update %s available") % ("v" + latest) if latest else ""
			if t == "SkinVersion":
				return skinVersion()
			if t == "ImageInfo":
				return imageInfo()
			if t == "NetDown":
				return rateText(NetSampler.sample()[0])
			if t == "NetUp":
				return rateText(NetSampler.sample()[1])
			if t == "NetIface":
				NetSampler.sample()
				name = NetSampler.iface
				return ("Wi-Fi" if name.startswith(("wlan", "wl", "ra")) else "Ethernet") + ("  " + DOT + "  " + name if name else "") if name else ""
			if t == "RamStep":
				total, used = memInfo()
				return str(min(20, int(round(used * 20.0 / total)))) if total else "0"
			if t == "RamPercent":
				total, used = memInfo()
				return "%d%%" % (used * 100 // total) if total else ""
			if t == "RamText":
				total, used = memInfo()
				return "%d / %d MB" % (used, total) if total else ""
			if t == "FlashText":
				total, free = diskInfo("/")
				return "%s %s" % (sizeText(free), tr("free")) if total else ""
			if t == "UsbText":
				if not ismount(USB):
					return tr("not mounted")
				total, free = diskInfo(USB)
				return "%s %s" % (sizeText(free), tr("free")) if total else ""
			if t == "SsdText":
				if not self.ssdMounted():
					return tr("not mounted")
				total, free = diskInfo(SSD)
				return "%s %s" % (sizeText(free), tr("free")) if total else ""
		except Exception:
			pass
		return ""

	text = property(getText)

	@cached
	def getValue(self):
		try:
			t = self.type
			if t == "RamUsed":
				total, used = memInfo()
				return used * 100 // total if total else 0
			if t == "FlashUsed":
				total, free = diskInfo("/")
				return (total - free) * 100 // total if total else 0
			if t.startswith("DiskUsed") and t[8:].isdigit():
				index = int(t[8:]) - 1
				if index == 2 and len(Disks.get()) > 3:
					return 0
				row = Disks.row(index)
				return (row[2] - row[3]) * 100 // row[2] if row and row[2] else 0
			if t == "UsbUsed":
				if not ismount(USB):
					return 0
				total, free = diskInfo(USB)
				return (total - free) * 100 // total if total else 0
			if t == "SsdUsed":
				if not self.ssdMounted():
					return 0
				total, free = diskInfo(SSD)
				return (total - free) * 100 // total if total else 0
		except Exception:
			pass
		return 0

	value = property(getValue)
	range = 100

	def booleanFor(self, t):
		if t.startswith("Disk") and t[4:].isdigit():
			return Disks.row(int(t[4:]) - 1) is not None
		if t == "Online":
			return InternetCheck.get() is True
		if t == "Offline":
			return InternetCheck.get() is False
		if t in ("Update", "UpdateText"):
			return updateAvailable() != ""
		if t == "FlashLow":
			total, free = diskInfo("/")
			return bool(total) and free < 15 * 1048576
		return False

	@cached
	def getBoolean(self):
		try:
			# Translated badge texts ("Label:ONLINE") show only in their state.
			t = {"Label:ONLINE": "Online", "Label:OFFLINE": "Offline", "Label:LOW": "FlashLow"}.get(self.type, self.type)
			return self.booleanFor(t)
		except Exception:
			return False

	boolean = property(getBoolean)

	def ip(self):
		# Address of the first non-loopback IPv4 route (no packets are sent).
		try:
			import socket
			s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
			try:
				s.connect(("10.255.255.255", 1))
				return s.getsockname()[0]
			finally:
				s.close()
		except Exception:
			return ""

	def changed(self, what):
		try:
			Converter.changed(self, what)
		except Exception:
			pass
