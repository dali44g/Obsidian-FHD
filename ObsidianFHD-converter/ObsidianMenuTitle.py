# Obsidian FHD: last part of a menu title such as "Main Menu > Setup > Usage & GUI" -> "Usage & GUI".
# Used for the submenu card header of the Floating menu style (skin_sysinfo.xml).
from Components.Converter.Converter import Converter
from Components.Element import cached


class ObsidianMenuTitle(Converter):
	def __init__(self, type):
		Converter.__init__(self, type)

	@cached
	def getText(self):
		try:
			text = self.source.text or ""
			for sep in (" > ", " / ", " - "):
				if sep in text:
					return text.split(sep)[-1].strip()
			return text.strip()
		except Exception:
			return ""

	text = property(getText)
