#!/bin/sh
# My Arch Linux installation script
# by David T. Sadler <davidtsadler@googlemail.com>
# License: GNU GPLv3

### FUNCTIONS ###

install_pkg() {
  pacman --noconfirm --needed -S "$1" >/dev/null 2>&1
}

error() {
  clear
  printf "ERROR:\\n%s\\n" "$1"
  exit
}

welcome_msg() {
  dialog --title "Welcome!" --msgbox "Welcome to my Arch Linux installation script!\\n\\nThis script will automatically install a fully-featured Linux desktop, which I use as my main machine.\\n\\n-David" 10 60
  dialog --colors --title "Important Note!" --yes-label "All ready!" --no-label "Return..." --yesno "Be sure the computer you are using has current pacman updates.\\n\\nIf it does not, the installation of some programs might fail." 8 70
}

get_username_and_password() {
  # Prompts user for new username and password.
  name=$(dialog --inputbox "First, please enter a name for the user account." 10 60 3>&1 1>&2 2>&3 3>&1) || exit
  while ! echo "$name" | grep "^[a-z_][a-z0-9_-]*$" >/dev/null 2>&1; do
    name=$(dialog --no-cancel --inputbox "Username not valid. Give a username beginning with a letter, with only lowercase letters, - or _." 10 60 3>&1 1>&2 2>&3 3>&1)
  done
  pass1=$(dialog --no-cancel --passwordbox "Enter a password for that user." 10 60 3>&1 1>&2 2>&3 3>&1)
  pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
  while ! [ "$pass1" = "$pass2" ]; do
    unset pass2
    pass1=$(dialog --no-cancel --passwordbox "Passwords do not match.\\n\\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
    pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
  done
}

user_check() {
  ! (id -u "$name" >/dev/null) 2>&1 || dialog --colors --title "WARNING!" --yes-label "CONTINUE" --no-label "No wait..." --yesno "The user \`$name\` already exists on this system. GOHAN can install for a user already existing, but it will \\Zboverwrite\\Zn any conflicting settings/dotfiles on the user account.\\n\\nGOHAN will \\Zbnot\\Zn overwrite your user files, documents, videos, etc., so don't worry about that, but only click <CONTINUE> if you don't mind your settings being overwritten.\\n\\nNote also that GOHAN will change $name's password to the one you just gave." 14 70
}

preinstall_msg() {
  dialog --title "Last chance!" --yes-label "Let's go!" --no-label "No, nevermind!" --yesno "Just press <Let's go!> and the system will begin installation!" 13 60 || { clear; exit; }
}

add_user() {
  # Adds user `$name` with password $pass1.
  dialog --infobox "Adding user \"$name\"..." 4 50
  useradd -m -s /bin/bash "$name" >/dev/null 2>&1 || mkdir -p /home/"$name" && chown "$name":"$name" /home/"$name"
  echo "$name:$pass1" | chpasswd
  unset pass1 pass2
}

### THE ACTUAL SCRIPT ###

install_pkg dialog || error "Are you sure you're running this as the root user and have an internet connection?"

welcome_msg || error "User exited."

get_username_and_password || error "User exited."

user_check || error "User exited."

preinstall_msg || error "User exited."

add_user || error "Error adding username and/or password."

clear
