#!/bin/sh
# My Arch Linux installation script 
# by David T. Sadler <davidtsadler@googlemail.com>
# License: GNU GPLv3

### FUNCTIONS ###

installpkg(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}

error() { clear; printf "ERROR:\\n%s\\n" "$1"; exit;}

welcomemsg() { \
  dialog --title "Welcome!" --msgbox "Welcome to my Arch Linux installation script!\\n\\nThis script will automatically install a fully-featured Linux desktop, which I use as my main machine.\\n\\n-David" 10 60

	dialog --colors --title "Important Note!" --yes-label "All ready!" --no-label "Return..." --yesno "Be sure the computer you are using has current pacman updates and refreshed Arch keyrings.\\n\\nIf it does not, the installation of some programs might fail." 8 70
	}

### THE ACTUAL SCRIPT ###

### This is how everything happens in an intuitive format and order.

# Check if user is root on Arch distro. Install dialog.
installpkg dialog || error "Are you sure you're running this as the root user and have an internet connection?"

# Welcome user.
welcomemsg || error "User exited."
