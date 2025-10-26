# VST Installer GUI for Native Instruments

This repository contains a simple GUI wrapper script for installing Native Instruments on Debian-based systems.
The GUI script is vst_installer.sh

If you are here I'm guessing you are already familiar with wine staging and yabridge skip to line 34. If not, I hope this helps.

Requirements

- Debian-based system (Debian, Ubuntu, etc.)
- Wine Staging version 9.21 installed
- yabridge installed and configured
- Native Access 1.14.1 installed and activated under Wine

Prerequisite steps

Install Wine Staging https://gitlab.winehq.org/wine/wine/-/wikis/Debian-Ubuntu 

Downgrade to version 9.21:

version=9.21
variant=staging
codename=$(shopt -s nullglob; awk '/^deb https:\/\/dl\.winehq\.org/ { print $3; exit 0 } END { exit 1 }' /etc/apt/sources.list /etc/apt/sources.list.d/*.list || awk '/^Suites:/ { print $2; exit }' /etc/apt/sources.list /etc/apt/sources.list.d/wine*.sources)
suffix=$(dpkg --compare-versions "$version" ge 6.1 && ((dpkg --compare-versions "$version" eq 6.17 && echo "-2") || echo "-1"))
sudo apt install --install-recommends {"winehq-$variant","wine-$variant","wine-$variant-amd64","wine-$variant-i386"}="$version~$codename$suffix"

Install required system packages (Debian/Ubuntu)
Update package lists and install runtime tools:
sudo apt update
sudo apt install -y zenity winetricks

Install yabridge https://github.com/robbert-vdh/yabridge

Install Native Access 1.14.1 Setup PC.exe with "Wine Windows Program Loader", activate it and click install all or only what you wish to use. Kontact 7 will install successfully here but everything else will most likely say fail. Never fear wine has downloaded them to your Downloads folder.

Native Access V2.exe does not yet work. You can find the old version here https://support.native-instruments.com/hc/en-us/articles/4748946468497-How-to-Downgrade-Native-Access-2-to-Native-Access-1 

Download the zip file for windows and extract it.  

Warnings and notes

This installer will not work if you've previously tried installing Native Access V2. If that's the case, completely remove any existing "Native Access V2.exe" file or folders and start again.

How to run

Make sure prerequisites are installed and Native Access 1.14.1 is installed and activated using Wine, click install all once logged in wait for downloads to finsih then close Native Access

Clone the repository

git clone https://github.com/rations/gui-for-native-instruments.git

cd vst_installer

chmod +x vst_installer.sh 

Run the GUI from the cloned repository:

./vst_installer.sh

When prompted, select the plugin ISO file. The script will mount it at /mnt/cdrom0, search for a Windows installer (.exe), run it with Wine, unmount the ISO, and attempt to sync yabridge.

Example full workflow

git clone https://github.com/rations/vst_installer.git

cd vst_installer

Make the installer executable and run it:

chmod +x vst_installer.sh && ./vst_installer.sh

Select the plugin ISO when prompted and follow the installer prompts shown by Wine.

You need to run vst_installer.sh for each individual native instruments you own

Native Access V2 conflicts:
This installer will not work if Native Access V2 remnants exist. Remove any Native Access V2 files/folders before attempting installs with Native Access 1.14.1
