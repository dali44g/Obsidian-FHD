# -*- coding: utf-8 -*-
# Obsidian FHD Apps: one entry in the main menu ("Obsidian Apps"). A grid of "apps" (weather, bitrate, Floating menu,
# Floating channel list, Halo infobar, About & update); each opens its own page with a preview, details and a Turn on / off button.
# Apps only write flag files in /etc/enigma2 that the skin reads at start-up (a GUI restart applies them). While the
# panel is open it also checks GitHub for a newer release (see ObsidianSysInfo.UpdateCheck) and can install it.
# Nothing here runs in the background and no image file is changed.
from os import remove
from os.path import exists

from Plugins.Plugin import PluginDescriptor

INSTALL_CMD = "wget -qO- https://raw.githubusercontent.com/dali44g/Obsidian-FHD/main/install.sh | sh"
NO_WEATHER = "/etc/enigma2/obsidian_noweather"
MENU_FLOATING = "/etc/enigma2/obsidian_menu_floating"
NO_BITRATE = "/etc/enigma2/obsidian_nobitrate"
CHLIST_FLOATING = "/etc/enigma2/obsidian_chlist_floating"
INFOBAR_GLASS = "/etc/enigma2/obsidian_infobar_glass"
INFOBAR_NOVA = "/etc/enigma2/obsidian_infobar_nova"
CONVERTERS = "/usr/lib/enigma2/python/Components/Converter/"


# French / Arabic texts of the Apps panel, keyed by the English text ("key|page" = page variant). ASCII escapes only.
TRANSLATIONS = {
	'Open app': (u'Ouvrir', u'\u0641\u062a\u062d'),
	'Close': (u'Fermer', u'\u0625\u063a\u0644\u0627\u0642'),
	'Turn on / off': (u'Activer / d\xe9sactiver', u'\u062a\u0641\u0639\u064a\u0644 / \u062a\u0639\u0637\u064a\u0644'),
	'Back to apps': (u'Retour aux applications', u'\u0631\u062c\u0648\u0639 \u0625\u0644\u0649 \u0627\u0644\u062a\u0637\u0628\u064a\u0642\u0627\u062a'),
	'Scroll': (u'D\xe9filer', u'\u062a\u0645\u0631\u064a\u0631'),
	'Back': (u'Retour', u'\u0631\u062c\u0648\u0639'),
	'Obsidian Apps': (u'Obsidian Apps', u'\u062a\u0637\u0628\u064a\u0642\u0627\u062a Obsidian'),
	'PREVIEW': (u'APER\u00c7U', u'\u0645\u0639\u0627\u064a\u0646\u0629'),
	'DETAILS': (u'D\u00c9TAILS', u'\u0627\u0644\u062a\u0641\u0627\u0635\u064a\u0644'),
	'Apps': (u'Applications', u'\u0627\u0644\u062a\u0637\u0628\u064a\u0642\u0627\u062a'),
	'APPS': (u'APPLICATIONS', u'\u0627\u0644\u062a\u0637\u0628\u064a\u0642\u0627\u062a'),
	'%d on  -  %d off': (u'%d actives  -  %d inactives', u'%d \u0645\u0641\u0639\u0651\u0644  -  %d \u0645\u0639\u0637\u0651\u0644'),
	'ON': (u'ACTIF', u'\u0645\u0641\u0639\u0651\u0644'),
	'OFF': (u'INACTIF', u'\u0645\u0639\u0637\u0651\u0644'),
	'NEEDS PLUGIN': (u'PLUGIN REQUIS', u'\u064a\u062a\u0637\u0644\u0628 \u0625\u0636\u0627\u0641\u0629'),
	'UPDATE v%s': (u'MISE \xc0 JOUR v%s', u'\u062a\u062d\u062f\u064a\u062b v%s'),
	'Turn on': (u'Activer', u'\u062a\u0641\u0639\u064a\u0644'),
	'Turn off': (u'D\xe9sactiver', u'\u062a\u0639\u0637\u064a\u0644'),
	'On': (u'Actif', u'\u0645\u0641\u0639\u0651\u0644'),
	'Off': (u'Inactif', u'\u0645\u0639\u0637\u0651\u0644'),
	'On - waiting for the plugin': (u'Actif - plugin manquant', u'\u0645\u0641\u0639\u0651\u0644 - \u0628\u0627\u0646\u062a\u0638\u0627\u0631 \u0627\u0644\u0625\u0636\u0627\u0641\u0629'),
	'Status': (u'\xc9tat', u'\u0627\u0644\u062d\u0627\u0644\u0629'),
	'Needs': (u'Requiert', u'\u064a\u062a\u0637\u0644\u0628'),
	'Uses': (u'Utilise', u'\u064a\u0633\u062a\u062e\u062f\u0645'),
	'Applies': (u'Effet', u'\u0627\u0644\u062a\u0637\u0628\u064a\u0642'),
	'After a GUI restart': (u"Apr\xe8s red\xe9marrage de l'interface", u'\u0628\u0639\u062f \u0625\u0639\u0627\u062f\u0629 \u062a\u0634\u063a\u064a\u0644 \u0627\u0644\u0648\u0627\u062c\u0647\u0629'),
	'not installed': (u'non install\xe9', u'\u063a\u064a\u0631 \u0645\u062b\u0628\u062a'),
	'Nothing': (u'Rien', u'\u0644\u0627 \u0634\u064a\u0621'),
	'Version': (u'Version', u'\u0627\u0644\u0625\u0635\u062f\u0627\u0631'),
	'Receiver': (u'R\xe9cepteur', u'\u0627\u0644\u062c\u0647\u0627\u0632'),
	'Update': (u'Mise \xe0 jour', u'\u0627\u0644\u062a\u062d\u062f\u064a\u062b'),
	'Licence': (u'Licence', u'\u0627\u0644\u062a\u0631\u062e\u064a\u0635'),
	'Up to date': (u'\xc0 jour', u'\u0645\u062d\u062f\u0651\u062b'),
	'Update now': (u'Mettre \xe0 jour', u'\u062a\u062d\u062f\u064a\u062b \u0627\u0644\u0622\u0646'),
	'v%s available': (u'v%s disponible', u'v%s \u0645\u062a\u0627\u062d'),
	'A new version is available': (u'Une nouvelle version est disponible', u'\u064a\u062a\u0648\u0641\u0631 \u0625\u0635\u062f\u0627\u0631 \u062c\u062f\u064a\u062f'),
	'Version, update, licence': (u'Version, mise \xe0 jour, licence', u'\u0627\u0644\u0625\u0635\u062f\u0627\u0631\u060c \u0627\u0644\u062a\u062d\u062f\u064a\u062b\u060c \u0627\u0644\u062a\u0631\u062e\u064a\u0635'),
	'Install Obsidian FHD v%s now?': (u'Installer Obsidian FHD v%s maintenant ?', u'\u062a\u062b\u0628\u064a\u062a Obsidian FHD v%s \u0627\u0644\u0622\u0646\u061f'),
	'Updating Obsidian FHD': (u"Mise \xe0 jour d'Obsidian FHD", u'\u062a\u062d\u062f\u064a\u062b Obsidian FHD'),
	'Restart the GUI now to apply the changes?': (u"Red\xe9marrer l'interface maintenant pour appliquer les changements ?", u'\u0625\u0639\u0627\u062f\u0629 \u062a\u0634\u063a\u064a\u0644 \u0627\u0644\u0648\u0627\u062c\u0647\u0629 \u0627\u0644\u0622\u0646 \u0644\u062a\u0637\u0628\u064a\u0642 \u0627\u0644\u062a\u063a\u064a\u064a\u0631\u0627\u062a\u061f'),
	"What's new": (u'Nouveaut\xe9s', u'\u0627\u0644\u062c\u062f\u064a\u062f'),
	'Loading...': (u'Chargement...', u'\u062c\u0627\u0631\u064d \u0627\u0644\u062a\u062d\u0645\u064a\u0644...'),
	'The list of changes could not be loaded. Check the internet connection and try again later.': (u"La liste des nouveaut\xe9s n'a pas pu \xeatre charg\xe9e. V\xe9rifiez la connexion internet et r\xe9essayez plus tard.", u'\u062a\u0639\u0630\u0651\u0631 \u062a\u062d\u0645\u064a\u0644 \u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062a\u063a\u064a\u064a\u0631\u0627\u062a. \u062a\u062d\u0642\u0642 \u0645\u0646 \u0627\u0644\u0627\u062a\u0635\u0627\u0644 \u0628\u0627\u0644\u0625\u0646\u062a\u0631\u0646\u062a \u0648\u062d\u0627\u0648\u0644 \u0644\u0627\u062d\u0642\u0627\u064b.'),
	'Obsidian Apps could not open.': (u"Obsidian Apps n'a pas pu s'ouvrir.", u'\u062a\u0639\u0630\u0651\u0631 \u0641\u062a\u062d \u062a\u0637\u0628\u064a\u0642\u0627\u062a Obsidian.'),
	'Restart the GUI and try again. If it persists, send the log (search for ObsidianFHD).': (u"Red\xe9marrez l'interface et r\xe9essayez. Si le probl\xe8me persiste, envoyez le journal (cherchez ObsidianFHD).", u'\u0623\u0639\u062f \u062a\u0634\u063a\u064a\u0644 \u0627\u0644\u0648\u0627\u062c\u0647\u0629 \u0648\u062d\u0627\u0648\u0644 \u0645\u062c\u062f\u062f\u0627\u064b. \u0625\u0630\u0627 \u0627\u0633\u062a\u0645\u0631\u062a \u0627\u0644\u0645\u0634\u0643\u0644\u0629\u060c \u0623\u0631\u0633\u0644 \u0627\u0644\u0633\u062c\u0644 (\u0627\u0628\u062d\u062b \u0639\u0646 ObsidianFHD).'),
	'Weather': (u'M\xe9t\xe9o', u'\u0627\u0644\u0637\u0642\u0633'),
	'Forecast in the infobar': (u"Pr\xe9visions dans l'infobar", u'\u0627\u0644\u062a\u0648\u0642\u0639\u0627\u062a \u0641\u064a \u0634\u0631\u064a\u0637 \u0627\u0644\u0645\u0639\u0644\u0648\u0645\u0627\u062a'),
	"Today's weather and the 5-day forecast at the top of the infobar.": (u"La m\xe9t\xe9o du jour et les pr\xe9visions sur 5 jours en haut de l'infobar.", u'\u0637\u0642\u0633 \u0627\u0644\u064a\u0648\u0645 \u0648\u062a\u0648\u0642\u0639\u0627\u062a 5 \u0623\u064a\u0627\u0645 \u0623\u0639\u0644\u0649 \u0634\u0631\u064a\u0637 \u0627\u0644\u0645\u0639\u0644\u0648\u0645\u0627\u062a.'),
	'OAWeather plugin': (u'Plugin OAWeather', u'\u0625\u0636\u0627\u0641\u0629 OAWeather'),
	'Internet, through OAWeather': (u'Internet, via OAWeather', u'\u0627\u0644\u0625\u0646\u062a\u0631\u0646\u062a \u0639\u0628\u0631 OAWeather'),
	'City and units are set in the OAWeather plugin. Turning this off hides only the weather bar; OAWeather keeps working.': (u'La ville et les unit\xe9s se r\xe8glent dans le plugin OAWeather. D\xe9sactiver masque seulement la barre m\xe9t\xe9o ; OAWeather continue de fonctionner.', u'\u062a\u064f\u0636\u0628\u0637 \u0627\u0644\u0645\u062f\u064a\u0646\u0629 \u0648\u0627\u0644\u0648\u062d\u062f\u0627\u062a \u0641\u064a \u0625\u0636\u0627\u0641\u0629 OAWeather. \u0627\u0644\u062a\u0639\u0637\u064a\u0644 \u064a\u062e\u0641\u064a \u0634\u0631\u064a\u0637 \u0627\u0644\u0637\u0642\u0633 \u0641\u0642\u0637 \u0648\u062a\u0628\u0642\u0649 OAWeather \u062a\u0639\u0645\u0644.'),
	'Bitrate': (u'D\xe9bit', u'\u0645\u0639\u062f\u0644 \u0627\u0644\u0628\u062a'),
	'Bitrate|page': (u'D\xe9bit (Bitrate)', u'\u0645\u0639\u062f\u0644 \u0627\u0644\u0628\u062a (Bitrate)'),
	'Video and audio bitrate': (u'D\xe9bit vid\xe9o et audio', u'\u0645\u0639\u062f\u0644 \u0628\u062a \u0627\u0644\u0635\u0648\u0631\u0629 \u0648\u0627\u0644\u0635\u0648\u062a'),
	'Video and audio bitrate under the clock and in the second infobar.': (u"D\xe9bit vid\xe9o et audio sous l'horloge et dans la seconde infobar.", u'\u0645\u0639\u062f\u0644 \u0628\u062a \u0627\u0644\u0635\u0648\u0631\u0629 \u0648\u0627\u0644\u0635\u0648\u062a \u062a\u062d\u062a \u0627\u0644\u0633\u0627\u0639\u0629 \u0648\u0641\u064a \u0634\u0631\u064a\u0637 \u0627\u0644\u0645\u0639\u0644\u0648\u0645\u0627\u062a \u0627\u0644\u062b\u0627\u0646\u064a.'),
	'BitrateViewer plugin': (u'Plugin BitrateViewer', u'\u0625\u0636\u0627\u0641\u0629 BitrateViewer'),
	'Measured only while the infobar is shown': (u"Mesur\xe9 seulement quand l'infobar est affich\xe9e", u'\u064a\u064f\u0642\u0627\u0633 \u0641\u0642\u0637 \u0623\u062b\u0646\u0627\u0621 \u0638\u0647\u0648\u0631 \u0634\u0631\u064a\u0637 \u0627\u0644\u0645\u0639\u0644\u0648\u0645\u0627\u062a'),
	'Shown on satellite, cable and terrestrial channels. IPTV streams have no tuner data, so nothing is shown there.': (u"Affich\xe9 sur les cha\xeenes satellite, c\xe2ble et TNT. Les flux IPTV n'ont pas de donn\xe9es tuner, rien n'y est affich\xe9.", u'\u064a\u0638\u0647\u0631 \u0639\u0644\u0649 \u0642\u0646\u0648\u0627\u062a \u0627\u0644\u0633\u062a\u0627\u0644\u0627\u064a\u062a \u0648\u0627\u0644\u0643\u0627\u0628\u0644 \u0648\u0627\u0644\u0623\u0631\u0636\u064a. \u0628\u062b IPTV \u0644\u0627 \u064a\u062d\u062a\u0648\u064a \u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u0645\u0648\u0627\u0644\u0641 \u0641\u0644\u0627 \u064a\u0638\u0647\u0631 \u0634\u064a\u0621.'),
	'Floating menu': (u'Menu flottant', u'\u0642\u0627\u0626\u0645\u0629 \u0639\u0627\u0626\u0645\u0629'),
	'Menu over live TV': (u'Menu sur la TV en direct', u'\u0627\u0644\u0642\u0627\u0626\u0645\u0629 \u0641\u0648\u0642 \u0627\u0644\u0628\u062b \u0627\u0644\u0645\u0628\u0627\u0634\u0631'),
	'Menu cards floating over live TV, with a live dashboard beside the main menu.': (u'Cartes de menu flottant sur la TV en direct, avec un tableau de bord \xe0 c\xf4t\xe9 du menu principal.', u'\u0628\u0637\u0627\u0642\u0627\u062a \u0642\u0627\u0626\u0645\u0629 \u0639\u0627\u0626\u0645\u0629 \u0641\u0648\u0642 \u0627\u0644\u0628\u062b \u0627\u0644\u0645\u0628\u0627\u0634\u0631\u060c \u0645\u0639 \u0644\u0648\u062d\u0629 \u0645\u0639\u0644\u0648\u0645\u0627\u062a \u0628\u062c\u0627\u0646\u0628 \u0627\u0644\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629.'),
	'Dashboard values while the menu is open': (u'Valeurs du tableau de bord quand le menu est ouvert', u'\u0642\u064a\u0645 \u0644\u0648\u062d\u0629 \u0627\u0644\u0645\u0639\u0644\u0648\u0645\u0627\u062a \u0623\u062b\u0646\u0627\u0621 \u0641\u062a\u062d \u0627\u0644\u0642\u0627\u0626\u0645\u0629'),
	'The dashboard shows temperature, CPU, RAM, disks and network. Off: the classic full-screen menus.': (u'Le tableau de bord affiche temp\xe9rature, CPU, RAM, disques et r\xe9seau. Inactif : les menus classiques plein \xe9cran.', u'\u062a\u0639\u0631\u0636 \u0627\u0644\u0644\u0648\u062d\u0629 \u0627\u0644\u062d\u0631\u0627\u0631\u0629 \u0648\u0627\u0644\u0645\u0639\u0627\u0644\u062c \u0648\u0627\u0644\u0630\u0627\u0643\u0631\u0629 \u0648\u0627\u0644\u0623\u0642\u0631\u0627\u0635 \u0648\u0627\u0644\u0634\u0628\u0643\u0629. \u0639\u0646\u062f \u0627\u0644\u062a\u0639\u0637\u064a\u0644: \u0627\u0644\u0642\u0648\u0627\u0626\u0645 \u0627\u0644\u0643\u0644\u0627\u0633\u064a\u0643\u064a\u0629 \u0628\u0645\u0644\u0621 \u0627\u0644\u0634\u0627\u0634\u0629.'),
	'Floating channel list': (u'Liste des cha\xeenes flottante', u'\u0642\u0627\u0626\u0645\u0629 \u0642\u0646\u0648\u0627\u062a \u0639\u0627\u0626\u0645\u0629'),
	'Channel list over live TV': (u'Cha\xeenes sur la TV en direct', u'\u0627\u0644\u0642\u0646\u0648\u0627\u062a \u0641\u0648\u0642 \u0627\u0644\u0628\u062b \u0627\u0644\u0645\u0628\u0627\u0634\u0631'),
	'Channel list and programme card floating over live TV.': (u'Liste des cha\xeenes et fiche du programme flottant sur la TV en direct.', u'\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0642\u0646\u0648\u0627\u062a \u0648\u0628\u0637\u0627\u0642\u0629 \u0627\u0644\u0628\u0631\u0646\u0627\u0645\u062c \u0639\u0627\u0626\u0645\u0629 \u0641\u0648\u0642 \u0627\u0644\u0628\u062b \u0627\u0644\u0645\u0628\u0627\u0634\u0631.'),
	'Nothing extra': (u'Rien de plus', u'\u0644\u0627 \u0634\u064a\u0621 \u0625\u0636\u0627\u0641\u064a'),
	'Tip: for roomy rows set Channel Selection Settings > Number of rows to 10 (visible with the Advanced setup level).': (u'Astuce : pour des lignes a\xe9r\xe9es, r\xe9glez Param\xe8tres de la liste des cha\xeenes > Nombre de lignes sur 10 (visible en niveau Avanc\xe9).', u'\u0646\u0635\u064a\u062d\u0629: \u0644\u0635\u0641\u0648\u0641 \u0623\u0648\u0633\u0639 \u0627\u0636\u0628\u0637 \u0625\u0639\u062f\u0627\u062f\u0627\u062a \u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0642\u0646\u0648\u0627\u062a > \u0639\u062f\u062f \u0627\u0644\u0635\u0641\u0648\u0641 \u0639\u0644\u0649 10 (\u064a\u0638\u0647\u0631 \u0641\u064a \u0627\u0644\u0645\u0633\u062a\u0648\u0649 \u0627\u0644\u0645\u062a\u0642\u062f\u0645).'),
	'Install plugin': (u'Installer le plugin', u'\u062a\u062b\u0628\u064a\u062a \u0627\u0644\u0625\u0636\u0627\u0641\u0629'),
	'Install %s now?': (u'Installer %s maintenant ?', u'\u062a\u062b\u0628\u064a\u062a %s \u0627\u0644\u0622\u0646\u061f'),
	'Installing...': (u'Installation...', u'\u062c\u0627\u0631\u064d \u0627\u0644\u062a\u062b\u0628\u064a\u062a...'),
	'Installed - restart the GUI to apply': (u'Install\u00e9 - red\u00e9marrez l\'interface', u'\u062a\u0645 \u0627\u0644\u062a\u062b\u0628\u064a\u062a - \u0623\u0639\u062f \u062a\u0634\u063a\u064a\u0644 \u0627\u0644\u0648\u0627\u062c\u0647\u0629'),
	'Installation failed. Check the internet connection and try again.': (u'\u00c9chec de l\'installation. V\u00e9rifiez la connexion internet et r\u00e9essayez.', u'\u0641\u0634\u0644 \u0627\u0644\u062a\u062b\u0628\u064a\u062a. \u062a\u062d\u0642\u0642 \u0645\u0646 \u0627\u0644\u0627\u062a\u0635\u0627\u0644 \u0628\u0627\u0644\u0625\u0646\u062a\u0631\u0646\u062a \u0648\u062d\u0627\u0648\u0644 \u0645\u062c\u062f\u062f\u0627\u064b.'),
	'Not enough free space on the receiver to install the plugin.': (u'Pas assez d\'espace libre sur le r\u00e9cepteur pour installer le plugin.', u'\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u0633\u0627\u062d\u0629 \u0643\u0627\u0641\u064a\u0629 \u0639\u0644\u0649 \u0627\u0644\u062c\u0647\u0627\u0632 \u0644\u062a\u062b\u0628\u064a\u062a \u0627\u0644\u0625\u0636\u0627\u0641\u0629.'),
	'Halo infobar': (u'Infobar Halo', u'\u0634\u0631\u064a\u0637 \u0645\u0639\u0644\u0648\u0645\u0627\u062a Halo'),
	'Infobar with a soft light': (u'Infobar avec une lumi\u00e8re douce', u'\u0634\u0631\u064a\u0637 \u0645\u0639\u0644\u0648\u0645\u0627\u062a \u0628\u0625\u0636\u0627\u0621\u0629 \u0646\u0627\u0639\u0645\u0629'),
	'Solid dark infobar with a soft teal light along its top edge.': (u'Infobar sombre et opaque avec une lumi\u00e8re turquoise douce sur le bord sup\u00e9rieur.', u'\u0634\u0631\u064a\u0637 \u0645\u0639\u0644\u0648\u0645\u0627\u062a \u062f\u0627\u0643\u0646 \u0645\u0639 \u0625\u0636\u0627\u0621\u0629 \u0641\u064a\u0631\u0648\u0632\u064a\u0629 \u0646\u0627\u0639\u0645\u0629 \u0639\u0644\u0649 \u062d\u0627\u0641\u062a\u0647 \u0627\u0644\u0639\u0644\u0648\u064a\u0629.'),
	'Off: the Glass infobar of earlier versions (slightly see-through).': (u'Inactif : l\'infobar Glass des versions pr\u00e9c\u00e9dentes (l\u00e9g\u00e8rement transparente).', u'\u0639\u0646\u062f \u0627\u0644\u062a\u0639\u0637\u064a\u0644: \u0634\u0631\u064a\u0637 Glass \u0645\u0646 \u0627\u0644\u0625\u0635\u062f\u0627\u0631\u0627\u062a \u0627\u0644\u0633\u0627\u0628\u0642\u0629 (\u0634\u0628\u0647 \u0634\u0641\u0627\u0641).'),
	'Infobar style': (u'Style de l\'infobar', u'\u0646\u0645\u0637 \u0634\u0631\u064a\u0637 \u0627\u0644\u0645\u0639\u0644\u0648\u0645\u0627\u062a'),
	'Choose the look of the infobar': (u'Choisir l\'apparence de l\'infobar', u'\u0627\u062e\u062a\u0631 \u0645\u0638\u0647\u0631 \u0634\u0631\u064a\u0637 \u0627\u0644\u0645\u0639\u0644\u0648\u0645\u0627\u062a'),
	'Halo: soft teal light. Glass: see-through bars. Nova: floating indigo capsule.': (u'Halo : lumi\u00e8re turquoise douce. Glass : barres transparentes. Nova : capsule indigo flottante.', u'Halo: \u0625\u0636\u0627\u0621\u0629 \u0641\u064a\u0631\u0648\u0632\u064a\u0629 \u0646\u0627\u0639\u0645\u0629. Glass: \u0623\u0634\u0631\u0637\u0629 \u0634\u0641\u0627\u0641\u0629. Nova: \u0643\u0628\u0633\u0648\u0644\u0629 \u0646\u064a\u0644\u064a\u0629 \u0639\u0627\u0626\u0645\u0629.'),
	'Style': (u'Style', u'\u0627\u0644\u0646\u0645\u0637'),
	'Styles': (u'Styles', u'\u0627\u0644\u0623\u0646\u0645\u0627\u0637'),
	'Next style': (u'Style suivant', u'\u0627\u0644\u0646\u0645\u0637 \u0627\u0644\u062a\u0627\u0644\u064a'),
	'Change style': (u'Changer de style', u'\u062a\u063a\u064a\u064a\u0631 \u0627\u0644\u0646\u0645\u0637'),
	'LEFT / RIGHT or GREEN changes the style; it applies after the GUI restart.': (u'GAUCHE / DROITE ou VERT change le style ; il s\'applique apr\u00e8s le red\u00e9marrage de l\'interface.', u'\u064a\u063a\u064a\u0651\u0631 \u064a\u0633\u0627\u0631 / \u064a\u0645\u064a\u0646 \u0623\u0648 \u0627\u0644\u0623\u062e\u0636\u0631 \u0627\u0644\u0646\u0645\u0637\u060c \u0648\u064a\u064f\u0637\u0628\u0651\u0642 \u0628\u0639\u062f \u0625\u0639\u0627\u062f\u0629 \u062a\u0634\u063a\u064a\u0644 \u0627\u0644\u0648\u0627\u062c\u0647\u0629.'),
	'About & update': (u'\xc0 propos et mise \xe0 jour', u'\u062d\u0648\u0644 \u0648\u062a\u062d\u062f\u064a\u062b'),
	'Dark 1080p skin for OpenATV and OpenPLi.': (u'Skin sombre 1080p pour OpenATV et OpenPLi.', u'\u0633\u0643\u064a\u0646 \u062f\u0627\u0643\u0646 1080p \u0644\u0640 OpenATV \u0648 OpenPLi.'),
}


def boxLanguage():
	try:
		from Components.Language import language
		return (language.getLanguage() or "")[:2]
	except Exception:
		return ""


def _(text):
	# French / Arabic from TRANSLATIONS, otherwise enigma2's own translation, otherwise English. UTF-8 str on Python 2.
	lang = boxLanguage()
	if lang in ("fr", "ar") and text in TRANSLATIONS:
		out = TRANSLATIONS[text][0 if lang == "fr" else 1]
		try:
			unicode
			return out.encode("utf-8")
		except NameError:
			return out
	text = text.split("|")[0]
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


def anyExists(paths):
	for p in paths:
		if exists(p):
			return True
	return False


# icon / preview index matches the order of the "pixmaps" lists in skin_apps.xml
APPS = [
	{"key": "weather", "image": 0, "name": "Weather", "short": "Forecast in the infobar",
		"desc": "Today's weather and the 5-day forecast at the top of the infobar.",
		"flag": NO_WEATHER, "flagMeansOn": False,
		"needs": [CONVERTERS + "OAWeather.pyc", CONVERTERS + "OAWeather.py"], "needsText": "OAWeather plugin",
		"package": "enigma2-plugin-extensions-oaweather",
		"usesText": "Internet, through OAWeather",
		"note": "City and units are set in the OAWeather plugin. Turning this off hides only the weather bar; OAWeather keeps working."},
	{"key": "bitrate", "image": 1, "name": "Bitrate", "page": "Bitrate|page", "short": "Video and audio bitrate",
		"desc": "Video and audio bitrate under the clock and in the second infobar.",
		"flag": NO_BITRATE, "flagMeansOn": False,
		"needs": ["/usr/lib/enigma2/python/Plugins/Extensions/BitrateViewer/bitratecalc.so"], "needsText": "BitrateViewer plugin",
		"package": "enigma2-plugin-extensions-bitrateviewer",
		"usesText": "Measured only while the infobar is shown",
		"note": "Shown on satellite, cable and terrestrial channels. IPTV streams have no tuner data, so nothing is shown there."},
	{"key": "menu", "image": 2, "name": "Floating menu", "short": "Menu over live TV",
		"desc": "Menu cards floating over live TV, with a live dashboard beside the main menu.",
		"flag": MENU_FLOATING, "flagMeansOn": True, "needs": [], "needsText": "Nothing",
		"usesText": "Dashboard values while the menu is open",
		"note": "The dashboard shows temperature, CPU, RAM, disks and network. Off: the classic full-screen menus."},
	{"key": "chlist", "image": 3, "name": "Floating channel list", "short": "Channel list over live TV",
		"desc": "Channel list and programme card floating over live TV.",
		"flag": CHLIST_FLOATING, "flagMeansOn": True, "needs": [], "needsText": "Nothing",
		"usesText": "Nothing extra",
		"note": "Tip: for roomy rows set Channel Selection Settings > Number of rows to 10 (visible with the Advanced setup level)."},
	{"key": "infobar", "image": 5, "name": "Infobar style", "short": "Choose the look of the infobar",
		"desc": "Halo: soft teal light. Glass: see-through bars. Nova: floating indigo capsule.",
		"styles": [("halo", None, "Halo", 5), ("glass", INFOBAR_GLASS, "Glass", 6), ("nova", INFOBAR_NOVA, "Nova", 7)],
		"note": "LEFT / RIGHT or GREEN changes the style; it applies after the GUI restart."},
	{"key": "about", "image": 4, "name": "About & update", "short": "", "desc": "Dark 1080p skin for OpenATV and OpenPLi.",
		"flag": None},
]


def currentStyle(app):
	# style chooser apps: the style whose flag file exists, otherwise the first (default) one
	for style in app["styles"]:
		if style[1] and exists(style[1]):
			return style
	return app["styles"][0]


def setStyle(app, key):
	# exactly one style flag (none for the default style)
	for style in app["styles"]:
		if style[1]:
			setFlag(style[1], style[0] == key)


def isOn(app):
	return exists(app["flag"]) == app["flagMeansOn"]


def setOn(app, on):
	setFlag(app["flag"], on == app["flagMeansOn"])


def isAvailable(app):
	return not app.get("needs") or anyExists(app["needs"])


def freeSpaceMB(path="/"):
	try:
		from os import statvfs
		st = statvfs(path)
		return st.f_bavail * st.f_frsize // (1024 * 1024)
	except Exception:
		return -1


def skinInfo():
	version, image = "", ""
	try:
		from Components.Converter.ObsidianSysInfo import imageInfo, skinVersion
		version, image = skinVersion(), imageInfo()
	except Exception:
		pass
	return version, image


def latestVersion():
	try:
		from Components.Converter.ObsidianSysInfo import updateAvailable
		return updateAvailable()
	except Exception:
		return ""


# Colours are fixed in the skin: every coloured text has one label per colour (suffix g green, a amber, c accent,
# m muted, "" normal text) and only the wanted one gets the text. Changing colours at run time is not redrawn on
# every image.
def colourText(screen, name, text, kind, kinds=("", "g", "a", "c", "m"), pills=False):
	# pills=True: the labels are pills with their own background, so the unused ones are hidden, not just emptied.
	for k in kinds:
		if (name + k) in screen:
			screen[name + k].setText(text if k == kind else "")
			if pills:
				if k == kind:
					screen[name + k].show()
				else:
					screen[name + k].hide()


CHANGELOG_URL = "https://raw.githubusercontent.com/dali44g/Obsidian-FHD/main/CHANGELOG.md"


class ChangelogFetch(object):
	# CHANGELOG.md from the public repository, read in a background thread (verified HTTPS, 8 s timeout, 64 KB max).
	# text is None while loading, "" after a failure.
	text = None
	running = False

	@classmethod
	def start(cls):
		if cls.running or cls.text:
			return
		cls.running = True
		cls.text = None
		try:
			from threading import Thread
			t = Thread(target=cls.run)
			t.daemon = True
			t.start()
		except Exception:
			cls.running = False
			cls.text = ""

	@classmethod
	def run(cls):
		result = ""
		try:
			try:
				from urllib.request import urlopen
			except ImportError:
				from urllib2 import urlopen
			data = urlopen(CHANGELOG_URL, timeout=8).read(65536)
			result = plainChangelog(data.decode("utf-8", "replace") if isinstance(data, bytes) else data)
		except Exception as e:
			print("[ObsidianFHD] changelog: %s" % e)
		cls.text = result
		cls.running = False


def plainChangelog(md):
	# Markdown to plain TV text: "## 1.4.1" -> "VERSION 1.4.1", file title and bold markers removed, bullets as dots.
	import re
	bullet = u"\u00b7 "
	lines = []
	for line in md.replace(u"\r", u"").split(u"\n"):
		if line.startswith(u"# "):
			continue
		if not lines and not line.startswith(u"## "):
			continue  # intro text before the first version
		if line.startswith(u"## "):
			if lines:
				lines.append(u"")
			lines.append(u"VERSION " + line[3:].strip())
			continue
		line = re.sub(r"\*\*([^*]+)\*\*", r"\1", line).replace(u"`", u"")
		if line.lstrip().startswith(u"- "):
			indent = len(line) - len(line.lstrip())
			line = u"    " * (indent // 2) + bullet + line.lstrip()[2:]
		lines.append(line)
	text = u"\n".join(lines).strip()
	try:
		unicode
		return text.encode("utf-8")
	except NameError:
		return text


_screens = None


def appScreens():
	# Screens are defined on first use so that the enigma2 imports happen only when the panel is opened.
	global _screens
	if _screens:
		return _screens
	from Components.ActionMap import ActionMap
	from Components.Label import Label
	from Components.Pixmap import MultiPixmap
	from Components.ScrollLabel import ScrollLabel
	from Components.Sources.StaticText import StaticText
	from Screens.MessageBox import MessageBox
	from Screens.Screen import Screen

	# Footer hints: up to three slots, each a key chip or colour marker (index into the "pixmaps" list of markN in
	# skin_apps.xml) followed by its text.
	KEY_OK, KEY_EXIT, KEY_UPDOWN, MARK_GREEN, MARK_YELLOW = 0, 1, 2, 3, 4

	def addHintSlots(screen):
		for n in range(3):
			screen["mark%d" % n] = MultiPixmap()
			screen["hint%d" % n] = StaticText("")

	def setHints(screen, hints):
		for n in range(3):
			if n < len(hints):
				screen["mark%d" % n].setPixmapNum(hints[n][0])
				screen["mark%d" % n].show()
				screen["hint%d" % n].setText(hints[n][1])
			else:
				screen["mark%d" % n].hide()
				screen["hint%d" % n].setText("")

	def restartPrompt(screen):
		screen.session.openWithCallback(lambda answer: restart(screen, answer), MessageBox, _("Restart the GUI now to apply the changes?"), MessageBox.TYPE_YESNO)

	def restart(screen, answer):
		if answer:
			try:
				from Screens.Standby import TryQuitMainloop
				screen.session.open(TryQuitMainloop, 3)
				return
			except Exception as e:
				print("[ObsidianFHD] restart: %s" % e)
		screen.close()

	class ObsidianFHDApps(Screen):
		COLUMNS = 4

		def __init__(self, session):
			Screen.__init__(self, session)
			self.skinName = ["ObsidianFHDApps"]
			self.setTitle(_("Obsidian FHD"))
			self.index = 0
			self.initial = self.states()
			self.latest = ""
			self.polls = 0
			self["heading"] = StaticText(_("Apps"))
			self["summary"] = StaticText("")
			addHintSlots(self)
			for i, app in enumerate(APPS):
				self["tile%d" % i] = MultiPixmap()
				self["icon%d" % i] = MultiPixmap()
				self["switch%d" % i] = MultiPixmap()
				for k in "gacm":
					self["status%d%s" % (i, k)] = Label("")
				self["name%d" % i] = StaticText(_(app["name"]))
				self["desc%d" % i] = StaticText(_(app["short"]))
			self["actions"] = ActionMap(["OkCancelActions", "DirectionActions"], {
				"ok": self.openApp, "cancel": self.exit,
				"left": lambda: self.move(-1), "right": lambda: self.move(1),
				"up": lambda: self.move(-self.COLUMNS), "down": lambda: self.move(self.COLUMNS),
			}, -2)
			try:
				from enigma import eTimer
				self.updateTimer = eTimer()
				self.updateTimer.callback.append(self.pollUpdate)
			except Exception:
				self.updateTimer = None
			self.onLayoutFinish.append(self.layoutFinished)

		def layoutFinished(self):
			for i, app in enumerate(APPS):
				self["icon%d" % i].setPixmapNum(app["image"])
			setHints(self, [(KEY_OK, _("Open app")), (KEY_EXIT, _("Close"))])
			self.refresh()
			self.pollUpdate()

		def pollUpdate(self):
			# The update check runs in a background thread: look for its result once a second, for up to 10 s.
			self.latest = latestVersion()
			if self.latest:
				self.refresh()
			elif self.updateTimer and self.polls < 10:
				self.polls += 1
				self.updateTimer.start(1000, True)

		def refresh(self):
			on = off = 0
			for i, app in enumerate(APPS):
				if app["key"] == "about":
					version = skinInfo()[0]
					if self.latest:
						text, col = _("UPDATE v%s") % self.latest, "a"
						self["desc%d" % i].setText(_("A new version is available"))
					else:
						text, col = version, "c"
						self["desc%d" % i].setText(_("Version, update, licence"))
				elif app.get("styles"):
					text, col = currentStyle(app)[2].upper(), "c"
				elif isOn(app):
					on += 1
					text, col = "", None
					state = 1 if isAvailable(app) else 2  # switch on, or on with the plugin missing (amber)
				else:
					off += 1
					text, col, state = "", None, 0
				# apps show a toggle switch, About shows its version / update pill
				if app["key"] == "about" or app.get("styles"):
					self["switch%d" % i].hide()
				else:
					self["switch%d" % i].setPixmapNum(state)
					self["switch%d" % i].show()
				colourText(self, "status%d" % i, text, col, "gacm", True)
				self["tile%d" % i].setPixmapNum(1 if i == self.index else 0)
			self["summary"].setText(_("%d on  -  %d off") % (on, off))

		def move(self, step):
			target = self.index + step
			if 0 <= target < len(APPS):
				self.index = target
			elif step == 1 or step == -1:
				return
			else:
				self.index = len(APPS) - 1 if step > 0 else self.index
			self.refresh()

		def openApp(self):
			self.session.openWithCallback(self.appClosed, ObsidianFHDApp, APPS[self.index], self.latest)

		def states(self):
			return [currentStyle(app)[0] if app.get("styles") else isOn(app) for app in APPS if app.get("flag") or app.get("styles")]

		def appClosed(self, changed=False):
			if changed == "installed":
				self.installed = True
			self.refresh()

		def exit(self):
			# Ask for a restart only if a setting really differs from when the panel was opened.
			if self.states() != self.initial or getattr(self, "installed", False):
				restartPrompt(self)
			else:
				self.close()

	class ObsidianFHDApp(Screen):
		def __init__(self, session, app, latest=""):
			Screen.__init__(self, session)
			self.skinName = ["ObsidianFHDApp"]
			self.setTitle(_("Obsidian FHD"))
			self.app = app
			self.latest = latest
			self.changed = False
			self.about = app["key"] == "about"
			self.installing = False
			self.installed = False
			self.container = None
			self["crumb"] = StaticText((_("APPS") + "  >  " + _(app["name"])).upper())
			self["icon"] = MultiPixmap()
			self["preview"] = MultiPixmap()
			self["button"] = MultiPixmap()
			self["buttonTextDark"] = Label("")
			self["buttonTextLight"] = Label("")
			self["name"] = StaticText(_(app.get("page", app["name"])))
			self["desc"] = StaticText(_(app["desc"]))
			self["note"] = StaticText("")
			addHintSlots(self)
			self["previewLabel"] = StaticText(_("PREVIEW"))
			self["detailsLabel"] = StaticText(_("DETAILS"))
			for j in range(4):
				self["label%d" % j] = StaticText("")
				for k in ("", "g", "a", "c", "m"):
					self["value%d%s" % (j, k)] = Label("")
			self["actions"] = ActionMap(["OkCancelActions", "ColorActions", "DirectionActions"], {
				"ok": self.press, "green": self.press, "cancel": self.exit, "red": self.exit,
				"yellow": self.yellow, "left": lambda: self.cycle(-1), "right": lambda: self.cycle(1),
			}, -2)
			self.onLayoutFinish.append(self.layoutFinished)

		def layoutFinished(self):
			self["icon"].setPixmapNum(self.app["image"])
			self["preview"].setPixmapNum(self.app["image"])
			self.refresh()

		def setRow(self, j, label, value, col=""):
			self["label%d" % j].setText(label)
			colourText(self, "value%d" % j, value, col)

		def setButton(self, text, primary):
			self["button"].setPixmapNum(0 if primary else 1)
			colourText(self, "buttonText", text, "Dark" if primary else "Light", ("Dark", "Light"))

		def refresh(self):
			if self.app.get("styles"):
				style = currentStyle(self.app)
				self["preview"].setPixmapNum(style[3])
				self.setRow(0, _("Style"), style[2], "c")
				self.setRow(1, _("Styles"), "  /  ".join(st[2] for st in self.app["styles"]))
				self.setRow(2, _("Uses"), _("Nothing extra"))
				self.setRow(3, _("Applies"), _("After a GUI restart"))
				self["note"].setText(_(self.app["note"]))
				self.setButton(_("Next style"), True)
				setHints(self, [(MARK_GREEN, _("Change style")), (KEY_EXIT, _("Back to apps"))])
				return
			if self.about:
				version, image = skinInfo()
				self.setRow(0, _("Version"), version or "-", "c")
				self.setRow(1, _("Receiver"), image or "-")
				if self.latest:
					self.setRow(2, _("Update"), _("v%s available") % self.latest, "a")
					self.setButton(_("Update now"), True)
					setHints(self, [(MARK_GREEN, _("Update now")), (MARK_YELLOW, _("What's new")), (KEY_EXIT, _("Back to apps"))])
				else:
					self.setRow(2, _("Update"), _("Up to date"), "g")
					self.setButton(_("Up to date"), False)
					setHints(self, [(MARK_YELLOW, _("What's new")), (KEY_EXIT, _("Back to apps"))])
				self.setRow(3, _("Licence"), "CC BY-NC-SA 4.0")
				self["note"].setText("github.com/dali44g/Obsidian-FHD")
				return
			on = isOn(self.app)
			available = isAvailable(self.app)
			if self.installing:
				self.setRow(0, _("Status"), _("Installing..."), "a")
				self.setRow(1, _("Needs"), _(self.app["needsText"]), "a")
				setHints(self, [])  # no keys while opkg runs (EXIT waits for it)
				return
			if on and available:
				status, col = _("On"), "g"
			elif on:
				status, col = _("On - waiting for the plugin"), "a"
			else:
				status, col = _("Off"), "m"
			self.setRow(0, _("Status"), status, col)
			needsCol = "" if available else "a"
			needs = _(self.app["needsText"]) if available or not self.app["needs"] else _(self.app["needsText"]) + " - " + _("not installed")
			self.setRow(1, _("Needs"), needs, needsCol)
			self.setRow(2, _("Uses"), _(self.app["usesText"]))
			self.setRow(3, _("Applies"), _("After a GUI restart"))
			self["note"].setText(_("Installed - restart the GUI to apply") if self.installed and available else _(self.app["note"]))
			self.setButton(_("Turn off") if on else _("Turn on"), not on)
			if self.canInstall():
				setHints(self, [(MARK_GREEN, _("Turn on / off")), (MARK_YELLOW, _("Install plugin")), (KEY_EXIT, _("Back to apps"))])
			else:
				setHints(self, [(MARK_GREEN, _("Turn on / off")), (KEY_EXIT, _("Back to apps"))])

		def canInstall(self):
			return bool(self.app.get("package")) and not isAvailable(self.app) and not self.installing

		def yellow(self):
			if self.about:
				self.whatsNew()
			elif self.canInstall():
				if 0 <= freeSpaceMB() < 10:
					self.session.open(MessageBox, _("Not enough free space on the receiver to install the plugin."), MessageBox.TYPE_ERROR)
					return
				self.session.openWithCallback(self.confirmInstall, MessageBox, _("Install %s now?") % _(self.app["needsText"]), MessageBox.TYPE_YESNO)

		def confirmInstall(self, answer):
			# Runs opkg in the background (the page stays usable); the package list is refreshed only when needed.
			if not answer or self.installing:
				return
			pkg = self.app["package"]
			cmd = "opkg install %s || (opkg update && opkg install %s)" % (pkg, pkg)
			try:
				from enigma import eConsoleAppContainer
				self.container = eConsoleAppContainer()
				self.container.appClosed.append(self.installDone)
				self.installing = True
				self.refresh()
				if self.container.execute("/bin/sh", "/bin/sh", "-c", cmd):
					self.installDone(-1)
			except Exception as e:
				print("[ObsidianFHD] install %s: %s" % (pkg, e))
				self.installing = False
				self.refresh()

		def installDone(self, retval):
			self.installing = False
			self.container = None
			if isAvailable(self.app):
				self.installed = True
			else:
				print("[ObsidianFHD] install %s failed (%s)" % (self.app["package"], retval))
				self.session.open(MessageBox, _("Installation failed. Check the internet connection and try again."), MessageBox.TYPE_ERROR)
			self.refresh()

		def cycle(self, step):
			styles = self.app.get("styles")
			if not styles:
				return
			keys = [st[0] for st in styles]
			setStyle(self.app, keys[(keys.index(currentStyle(self.app)[0]) + step) % len(keys)])
			self.changed = True
			self.refresh()

		def press(self):
			if self.app.get("styles"):
				self.cycle(1)
				return
			if self.about:
				if self.latest:
					self.session.openWithCallback(self.confirmUpdate, MessageBox, _("Install Obsidian FHD v%s now?") % self.latest, MessageBox.TYPE_YESNO)
				return
			setOn(self.app, not isOn(self.app))
			self.changed = not self.changed
			self.refresh()

		def whatsNew(self):
			if self.about:
				self.session.open(ObsidianFHDChangelog)

		def confirmUpdate(self, answer):
			if answer:
				try:
					from Screens.Console import Console
					self.session.openWithCallback(self.updated, Console, title=_("Updating Obsidian FHD"), cmdlist=[INSTALL_CMD])
				except Exception as e:
					print("[ObsidianFHD] update: %s" % e)

		def updated(self, *args):
			restartPrompt(self)

		def exit(self):
			if self.installing:
				return  # wait for opkg to finish
			self.close("installed" if self.installed else self.changed)

	class ObsidianFHDChangelog(Screen):
		def __init__(self, session):
			Screen.__init__(self, session)
			self.skinName = ["ObsidianFHDChangelog"]
			self.setTitle(_("Obsidian FHD"))
			self["crumb"] = StaticText((_("APPS") + "  >  " + _("About & update") + "  >  " + _("What's new")).upper())
			self["heading"] = StaticText(_("What's new"))
			self["state"] = StaticText(_("Loading..."))
			addHintSlots(self)
			self["text"] = ScrollLabel("")
			self["actions"] = ActionMap(["OkCancelActions", "DirectionActions"], {
				"cancel": self.close, "ok": self.close,
				"up": self["text"].pageUp, "down": self["text"].pageDown,
				"left": self["text"].pageUp, "right": self["text"].pageDown,
			}, -2)
			self.polls = 0
			try:
				from enigma import eTimer
				self.timer = eTimer()
				self.timer.callback.append(self.poll)
			except Exception:
				self.timer = None
			# onLayoutFinish entries must be bound methods: OpenATV runs anything else through exec().
			self.onLayoutFinish.append(self.layoutFinished)
			ChangelogFetch.start()

		def layoutFinished(self):
			setHints(self, [(KEY_UPDOWN, _("Scroll")), (KEY_EXIT, _("Back"))])
			self.poll()

		def poll(self):
			# The download runs in a background thread: show its result when ready (checked twice a second, up to 15 s).
			text = ChangelogFetch.text
			if text:
				self["text"].setText(text)
				self["state"].setText("github.com/dali44g/Obsidian-FHD")
			elif text == "" or self.polls >= 30 or not self.timer:
				self["state"].setText("")
				self["text"].setText(_("The list of changes could not be loaded. Check the internet connection and try again later."))
			else:
				self.polls += 1
				self.timer.start(500, True)

	_screens = (ObsidianFHDApps, ObsidianFHDApp)
	return _screens


def openSettings(session, **kwargs):
	try:
		session.open(appScreens()[0])
	except Exception as e:
		# Never fail silently: full traceback in the log, short reason on screen.
		print("[ObsidianFHD] open: %s" % e)
		try:
			import traceback
			traceback.print_exc()
		except Exception:
			pass
		try:
			from Screens.MessageBox import MessageBox
			session.open(MessageBox, _("Obsidian Apps could not open.") + "\n\n%s\n\n" % e + _("Restart the GUI and try again. If it persists, send the log (search for ObsidianFHD)."), MessageBox.TYPE_ERROR)
		except Exception as e2:
			print("[ObsidianFHD] message: %s" % e2)


def obsidianActive():
	try:
		from Components.config import config
		return config.skin.primary_skin.value.startswith("Obsidian-FHD/")
	except Exception:
		return False


def menuEntry(menuid, **kwargs):
	# Main menu entry (key obsidian_apps = icon mainmenu/obsidian_apps.png), only while Obsidian is the active skin.
	if menuid == "mainmenu" and obsidianActive():
		return [(_("Obsidian Apps"), openSettings, "obsidian_apps", 45)]
	return []


def Plugins(**kwargs):
	return [PluginDescriptor(name="Obsidian Apps", description="Obsidian FHD apps and options", where=PluginDescriptor.WHERE_MENU, fnc=menuEntry)]
