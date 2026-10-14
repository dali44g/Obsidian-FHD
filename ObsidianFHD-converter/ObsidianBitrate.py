# -*- coding: utf-8 -*-
# Obsidian FHD: video / audio bitrate of the playing DVB service (satellite, cable, terrestrial), measured by the
# BitrateViewer plugin's calculator (Plugins/Extensions/BitrateViewer/bitratecalc.so). Without that plugin, on IPTV
# or on recordings the text is "" and the boolean False, so the widgets stay hidden.
#
#   <convert type="ObsidianBitrate">Video</convert>    text "8.4 Mbit/s" / "192 kbit/s", boolean = has a value
#   <convert type="ObsidianBitrate">Audio</convert>
# The calculator runs only while a screen using the converter is shown (stopped on hide), refreshing once a second.
from Components.Converter.Converter import Converter
from Components.Element import cached


def calculatorClass():
	try:
		from Plugins.Extensions.BitrateViewer.bitratecalc import eBitrateCalculator
		return eBitrateCalculator
	except Exception:
		return None


class ObsidianBitrate(Converter, object):
	def __init__(self, type):
		Converter.__init__(self, type)
		self.audio = type.strip().lower() == "audio"
		self.calc = None
		self.key = None
		self.value = None
		# Screens start hidden (suspended): measure only once doSuspend(False) says the screen is shown.
		# Not named 'suspended': that is Element's property, whose setter calls doSuspend().
		self.paused = True

	def start(self):
		cls = calculatorClass()
		if cls is None or self.paused:
			self.stop()
			return
		try:
			import NavigationInstance
			from enigma import iServiceInformation
			ref = NavigationInstance.instance.getCurrentlyPlayingServiceReference()
			service = self.source.service
			if ref is None or service is None or ref.getPath():
				self.stop()
				return  # nothing playing, IPTV stream or recording: no demux to measure
			info = service.info()
			pid = info and info.getInfo(iServiceInformation.sAudioPID if self.audio else iServiceInformation.sVideoPID)
			if pid is None or pid < 0:
				self.stop()
				return
			key = (ref.toString(), pid)
			if key == self.key and self.calc is not None:
				return  # same channel and PID: keep measuring
			self.stop()
			self.key = key
			self.calc = cls(pid, ref.getData(4), ref.getData(2), ref.getData(3), 1000, 65536 if self.audio else 1048576)
			self.calc.callback.append(self.update)
		except Exception as e:
			print("[ObsidianBitrate] %s" % e)
			self.calc = None

	def stop(self):
		if self.calc is not None:
			try:
				self.calc.callback.remove(self.update)
			except Exception:
				pass
		self.calc = None
		self.key = None
		self.value = None

	def update(self, value, status):
		self.value = value if status else None
		Converter.changed(self, (self.CHANGED_ALL,))

	def changed(self, what):
		# service started / changed / info updated: measure the new PIDs
		self.start()
		Converter.changed(self, what)

	def doSuspend(self, suspended):
		self.paused = bool(suspended)
		if suspended:
			self.stop()
		else:
			self.start()

	def destroy(self):
		self.stop()
		parent = getattr(Converter, "destroy", None)
		if parent:
			parent(self)

	@cached
	def getText(self):
		v = self.value
		if v is None:
			return ""
		return "%.1f Mbit/s" % (v / 1000.0) if v >= 1000 else "%d kbit/s" % v

	text = property(getText)

	@cached
	def getBoolean(self):
		return self.value is not None

	boolean = property(getBoolean)
