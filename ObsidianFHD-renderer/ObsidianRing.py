# -*- coding: utf-8 -*-
# ObsidianRing: shows one of 24 ring images (Obsidian-FHD/nova/ring_00..23.png) for a 0..1000 progress value, used by
# the Nova infobar with <convert type="EventTime">Progress</convert>. Hidden when there is no value (no programme).
# Nothing else is read or changed; Python 2 / 3.
from enigma import ePixmap
from Components.Renderer.Renderer import Renderer
from Tools.LoadPixmap import LoadPixmap
from Tools.Directories import resolveFilename, SCOPE_GUISKIN

STEPS = 24


class ObsidianRing(Renderer):
	GUI_WIDGET = ePixmap

	def __init__(self):
		Renderer.__init__(self)
		self.pngs = None

	def loadPixmaps(self):
		if self.pngs is None:
			self.pngs = []
			for k in range(STEPS):
				try:
					self.pngs.append(LoadPixmap(resolveFilename(SCOPE_GUISKIN, "nova/ring_%02d.png" % k)))
				except Exception:
					self.pngs.append(None)

	def changed(self, what):
		if not self.instance:
			return
		try:
			value = self.source.value
		except Exception:
			value = None
		if value is None:
			self.instance.hide()
			return
		self.loadPixmaps()
		try:
			step = min(STEPS - 1, max(0, int(value) * STEPS // 1000))
		except (TypeError, ValueError):
			self.instance.hide()
			return
		png = self.pngs[step]
		if png:
			self.instance.setPixmap(png)
			self.instance.show()
		else:
			self.instance.hide()

	def onShow(self):
		self.changed(None)
