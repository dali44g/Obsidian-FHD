# Obsidian FHD settings: one entry in Menu > Setup > Usage & GUI, next to Skin Settings.
# It writes flag files that the skin reads at start-up. While it is open it also checks GitHub for a newer release
# (one small version file, see ObsidianSysInfo.UpdateCheck) and offers to install it with the README command.
from os import remove
from os.path import exists

from Plugins.Plugin import PluginDescriptor

INSTALL_CMD = "wget -qO- https://raw.githubusercontent.com/dali44g/Obsidian-FHD/main/install.sh | sh"
NO_WEATHER = "/etc/enigma2/obsidian_noweather"
MENU_FLOATING = "/etc/enigma2/obsidian_menu_floating"


def _(text):
	try:
		from gettext import gettext
		return gettext(text)
	except Exception:
		return text


def setFlag(path, on):
	# on=True -> the flag file exists.
	try:
		if on and not exists(path):
			open(path, "w").close()
		elif not on and exists(path):
			remove(path)
	except Exception as e:
		print("[ObsidianFHD] flag %s: %s" % (path, e))


def openSettings(session, **kwargs):
	try:
		from Components.ActionMap import ActionMap
		from Components.config import ConfigSelection, ConfigYesNo, getConfigListEntry
		from Components.ConfigList import ConfigListScreen
		from Components.Label import Label
		from Components.Sources.Boolean import Boolean
		from Components.Sources.StaticText import StaticText
		from Screens.MessageBox import MessageBox
		from Screens.Screen import Screen

		class ObsidianFHDSettings(ConfigListScreen, Screen):
			def __init__(self, session):
				Screen.__init__(self, session)
				self.skinName = ["ObsidianFHDSettings", "Setup"]
				self.setTitle(_("Obsidian FHD Settings"))
				self.weather = ConfigYesNo(default=not exists(NO_WEATHER))
				self.menuStyle = ConfigSelection(default="floating" if exists(MENU_FLOATING) else "classic", choices=[("classic", _("Classic")), ("floating", _("Floating"))])
				# (entry, flag file, flag file wanted when..., help text)
				self.options = [
					(getConfigListEntry(_("Show weather in infobar") + "*", self.weather), NO_WEATHER, lambda: not self.weather.value,
						_("Show today's weather and the forecast at the top of the infobar (needs the OAWeather plugin). Hiding it keeps OAWeather itself working.")),
					(getConfigListEntry(_("Menu style") + "*", self.menuStyle), MENU_FLOATING, lambda: self.menuStyle.value == "floating",
						_("Classic: full-screen menus with live preview and programme cards. Floating: menu cards floating over live TV.")),
				]
				self["key_red"] = StaticText(_("Cancel"))
				self["key_green"] = StaticText(_("Save"))
				self["description"] = Label("")
				self["footnote"] = Label(_("* = Restart Required"))
				self["VKeyIcon"] = Boolean(False)
				version, image = "", ""
				try:
					from Components.Converter.ObsidianSysInfo import imageInfo, skinVersion
					version, image = skinVersion(), imageInfo()
				except Exception:
					pass
				self["about_title"] = StaticText(("Obsidian FHD  " + version).strip())
				self["about_text"] = StaticText(_("Dark 1080p skin for OpenATV and OpenPLi"))
				self["about_image"] = StaticText(image)
				self["about_link"] = StaticText("github.com/dali44g/Obsidian-FHD")
				self["about_licence"] = StaticText(_("Licence") + " CC BY-NC-SA 4.0")
				self["about_update"] = StaticText("")
				self["key_yellow"] = StaticText("")
				self.latest = ""
				self.polls = 0
				try:
					from enigma import eTimer
					self.updateTimer = eTimer()
					self.updateTimer.callback.append(self.pollUpdate)
					self.onLayoutFinish.append(self.pollUpdate)
				except Exception:
					self.updateTimer = None
				ConfigListScreen.__init__(self, [o[0] for o in self.options], session=session)
				self["actions"] = ActionMap(["SetupActions", "ColorActions"], {
					"cancel": self.close, "red": self.close, "save": self.save, "green": self.save, "ok": self.save,
					"yellow": self.update,
				}, -2)
				self["config"].onSelectionChanged.append(self.showHelp)
				self.onLayoutFinish.append(self.showHelp)

			def pollUpdate(self):
				# The check runs in a background thread: look for its result once a second, for up to 10 s.
				try:
					from Components.Converter.ObsidianSysInfo import updateAvailable
					self.latest = updateAvailable()
				except Exception:
					self.latest = ""
				if self.latest:
					self["about_update"].setText(_("Update available") + ": v" + self.latest)
					self["key_yellow"].setText(_("Update now"))
				elif self.updateTimer and self.polls < 10:
					self.polls += 1
					self.updateTimer.start(1000, True)

			def update(self):
				if self.latest:
					self.session.openWithCallback(self.confirmUpdate, MessageBox, _("Install Obsidian FHD v%s now?") % self.latest, MessageBox.TYPE_YESNO)

			def confirmUpdate(self, answer):
				if answer:
					try:
						from Screens.Console import Console
						self.session.openWithCallback(self.updated, Console, title=_("Updating Obsidian FHD"), cmdlist=[INSTALL_CMD])
					except Exception as e:
						print("[ObsidianFHD] update: %s" % e)

			def updated(self, *args):
				self.session.openWithCallback(self.restart, MessageBox, _("Restart the GUI now to use the new version?"), MessageBox.TYPE_YESNO)

			def showHelp(self):
				try:
					self["description"].setText(self.options[self["config"].getCurrentIndex()][3])
				except Exception:
					pass

			def save(self):
				changed = False
				for entry, path, wanted, text in self.options:
					if wanted() != exists(path):
						setFlag(path, wanted())
						changed = True
				if changed:
					self.session.openWithCallback(self.restart, MessageBox, _("Restart the GUI now to apply the change?"), MessageBox.TYPE_YESNO)
				else:
					self.close()

			def restart(self, answer):
				if answer:
					try:
						from Screens.Standby import TryQuitMainloop
						self.session.open(TryQuitMainloop, 3)
						return
					except Exception as e:
						print("[ObsidianFHD] restart: %s" % e)
				self.close()

		session.open(ObsidianFHDSettings)
	except Exception as e:
		print("[ObsidianFHD] open: %s" % e)


def obsidianActive():
	try:
		from Components.config import config
		return config.skin.primary_skin.value.startswith("Obsidian-FHD/")
	except Exception:
		return False


def menuEntry(menuid, **kwargs):
	# "system" is the Usage & GUI menu on OpenATV and the System menu on OpenPLi.
	if menuid == "system" and obsidianActive():
		return [(_("Obsidian FHD Settings"), openSettings, "obsidian_fhd_setup", 26)]
	return []


def Plugins(**kwargs):
	return [PluginDescriptor(name="Obsidian FHD Settings", description="Obsidian FHD skin options", where=PluginDescriptor.WHERE_MENU, fnc=menuEntry)]
