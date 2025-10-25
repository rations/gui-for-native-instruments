# VST Installer GUI for Native Instruments

This repository contains a simple GUI wrapper script for installing Native Instruments on Debian-based systems.
The GUI script is vst_installer.sh

If you are here I'm guessing you are already familiar with wine staging and yabridge. If not, I hope this helps.

Requirements

- Debian-based system (Debian, Ubuntu, etc.)
- Wine Staging version 9.21 installed
- yabridge installed and configured
- Native Access 1.14.1 installed and activated under Wine

Prerequisite steps

1. Install Wine Staging https://gitlab.winehq.org/wine/wine/-/wikis/Debian-Ubuntu 

Downgrade to version 9.21:

version=9.21
variant=staging
codename=$(shopt -s nullglob; awk '/^deb https:\/\/dl\.winehq\.org/ { print $3; exit 0 } END { exit 1 }' /etc/apt/sources.list /etc/apt/sources.list.d/*.list || awk '/^Suites:/ { print $2; exit }' /etc/apt/sources.list /etc/apt/sources.list.d/wine*.sources)
suffix=$(dpkg --compare-versions "$version" ge 6.1 && ((dpkg --compare-versions "$version" eq 6.17 && echo "-2") || echo "-1"))
sudo apt install --install-recommends {"winehq-$variant","wine-$variant","wine-$variant-amd64","wine-$variant-i386"}="$version~$codename$suffix"

Install winetricks sudo apt install winetricks

Install yabridge https://github.com/robbert-vdh/yabridge

Install Native Access 1.14.1 Setup PC.exe with "Wine Windows Program Loader", activate it and click install all or only what you wish to use. Kontact 7 will install successfully here but everything else will most likely say fail. Never fear wine has downloaded them to your Downloads folder.

Native Access V2.exe does not yet work. You can find the old version here https://support.native-instruments.com/hc/en-us/articles/4748946468497-How-to-Downgrade-Native-Access-2-to-Native-Access-1 

Download the zip file for windows and extract it.  

Warnings and notes

- This installer will not work if you've previously tried installing Native Access V2. If that's the case, completely remove any existing "Native Access V2.exe" file or folders and start again.
- yabridge works best with Wine Staging 9.21. If you need to downgrade Wine you can set:

version=9.21
variant=staging

- Always back up your Wine prefix before running installers.
- Run the GUI script as your regular user (not root). Use sudo only when requested by the script.

How to run

1. Make sure prerequisites are installed and Native Access 1.14.1 is installed/activated.
2. Run the GUI:

./vst_installer.sh

License

See the project LICENCE file for license information.