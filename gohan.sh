#!/bin/sh
# My Arch Linux installation script 
# by David T. Sadler <davidtsadler@googlemail.com>
# License: GNU GPLv3

### FUNCTIONS ###

installpkg(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}

error() { clear; printf "ERROR:\\n%s\\n" "$1"; exit;}

### THE ACTUAL SCRIPT ###

### This is how everything happens in an intuitive format and order.

# Check if user is root on Arch distro. Install dialog.
installpkg dialog || error "Are you sure you're running this as the root user and have an internet connection?"
