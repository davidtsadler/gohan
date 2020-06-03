#!/bin/sh
# My Arch Linux installation script 
# by David T. Sadler <davidtsadler@googlemail.com>
# License: GNU GPLv3

### OPTIONS AND VARIABLES ###

while getopts ":b:p:h" o; do case "${o}" in
	h) printf "Optional arguments for custom use:\\n  -p: Dependencies and programs csv (local file or url)\\n  -h: Show this message\\n" && exit ;;
	b) repobranch=${OPTARG} ;;
	p) progsfile=${OPTARG} ;;
	*) printf "Invalid option: -%s\\n" "$OPTARG" && exit ;;
esac done

[ -z "$progsfile" ] && progsfile="https://raw.githubusercontent.com/davidtsadler/gohan/master/progs.csv"
[ -z "$repobranch" ] && repobranch="master"

### FUNCTIONS ###

installpkg(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}

error() { clear; printf "ERROR:\\n%s\\n" "$1"; exit;}

welcomemsg() { \
  dialog --title "Welcome!" --msgbox "Welcome to my Arch Linux installation script!\\n\\nThis script will automatically install a fully-featured Linux desktop, which I use as my main machine.\\n\\n-David" 10 60

	dialog --colors --title "Important Note!" --yes-label "All ready!" --no-label "Return..." --yesno "Be sure the computer you are using has current pacman updates and refreshed Arch keyrings.\\n\\nIf it does not, the installation of some programs might fail." 8 70
	}

preinstallmsg() { \
	dialog --title "Let's get this party started!" --yes-label "Let's go!" --no-label "No, nevermind!" --yesno "The rest of the installation will now be totally automated, so you can sit back and relax.\\n\\nIt will take some time, but when done, you can relax even more with your complete system.\\n\\nNow just press <Let's go!> and the system will begin installation!" 13 60 || { clear; exit; }
	}

### THE ACTUAL SCRIPT ###

### This is how everything happens in an intuitive format and order.

# Check if user is root on Arch distro. Install dialog.
installpkg dialog || error "Are you sure you're running this as the root user and have an internet connection?"

# Welcome user.
welcomemsg || error "User exited."

# Last chance for user to back out before install.
preinstallmsg || error "User exited."

### The rest of the script requires no user input.

dialog --title "Gohan Installation" --infobox "Installing \`basedevel\` and \`git\` for installing other software required for the installation of other programs." 5 70
installpkg curl
installpkg base-devel
installpkg git
