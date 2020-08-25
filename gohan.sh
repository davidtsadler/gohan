#!/bin/sh
# My Arch Linux installation script
# by David T. Sadler <davidtsadler@googlemail.com>
# License: GNU GPLv3

### OPTIONS AND VARIABLES ###

while getopts ":p:h" o; do case "${o}" in
  h) printf "Optional arguments for custom use:\\n  -r: Dotfiles repository\\n  -p: Dependencies and programs csv (local file or url)\\n  -h: Show this message\\n" && exit ;;
  r) dotfilesrepo=${OPTARG} && git ls-remote "$dotfilesrepo" || exit ;;
  p) packages=${OPTARG} ;;
  *) printf "Invalid option: -%s\\n" "$OPTARG" && exit ;;
esac done

[ -z "$dotfilesrepo" ] && dotfilesrepo="https://github.com/davidtsadler/dotfiles.git"
[ -z "$packages" ] && packages="https://raw.githubusercontent.com/davidtsadler/gohan/master/packages.csv"

### FUNCTIONS ###

install_from_pacman() {
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
  usermod -aG wheel "$name"
  [ ! -d "/home/$name/.local/src" ] && mkdir -p "/home/$name/.local/src" && chown -R "$name":"$name" /home/"$name/.local"
  # Remove these files as they will be installed as part of the dotfiles.
  [ -f "/home/$name/.bash_history" ] && rm /home/$name/.bash_history
  [ -f "/home/$name/.bash_logout" ] && rm /home/$name/.bash_logout
  [ -f "/home/$name/.bash_profile" ] && rm /home/$name/.bash_profile
  [ -f "/home/$name/.bashrc" ] && rm /home/$name/.bashrc
  echo "$name:$pass1" | chpasswd
  unset pass1 pass2
}

install_dotfiles() {
  dialog --infobox "Downloading and installing dotfiles..." 4 60
  [ ! -d "$2" ] && mkdir -p "$2" && chown -R "$name":"$name" "$2"
  sudo -u "$name" git clone --bare --depth 1 "$1" "$2" >/dev/null 2>&1
  sudo -u "$name" git --git-dir="$2" --work-tree="/home/$name" checkout
  sudo -u "$name" git --git-dir="$2" --work-tree="/home/$name" config --local status.showUntrackedFiles no
}

install_software() {
  ([ -f "$packages" ] && cp "$packages" /tmp/packages.csv) || curl -Ls "$packages" > /tmp/packages.csv
  total=$(wc -l < /tmp/packages.csv)
  while IFS=, read -r tag program comment; do
    n=$((n+1))
    echo "$comment" | grep "^\".*\"$" >/dev/null 2>&1 && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
    case "$tag" in
      "A") install_from_aur "$program" "$comment" ;;
      "G") install_from_github "$program" "$comment" ;;
      *) install_package "$program" "$comment" ;;
    esac
  done < /tmp/packages.csv
}

install_package() {
  dialog --title "GOHAN Installation" --infobox "Installing \`$1\` ($n of $total). $1 $2" 5 70
  install_from_pacman "$1"
}

install_from_aur() {
  dialog --title "GOHAN Installation" --infobox "Installing \`$1\` ($n of $total) from the AUR. $1 $2" 5 70
  sudo -u "$name" yay -S --noconfirm "$1" >/dev/null 2>&1
}

install_from_github() {
  progname="$(basename "$1" .git)"
  repodir="/home/$name/.local/src"
  dir="$repodir/$progname"
  dialog --title "GOHAN Installation" --infobox "Installing \`$progname\` ($n of $total) via \`git\` and \`make\`. $(basename "$1") $2" 5 70
  sudo -u "$name" git clone --depth 1 "$1" "$dir" >/dev/null 2>&1
  cd "$dir" || exit
  sudo -u "$name" make clean install >/dev/null 2>&1
}

configure_sudo() {
  install_from_pacman sudo
  [ -f /etc/sudoers ] && sed -i "s/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
}

install_yay() {
  [ -f "/usr/bin/yay" ] || (
  dialog --infobox "Installing \"yay\", an AUR helper..." 4 50
  cd /tmp || exit
  rm -rf /tmp/yay*
  # Use all cores for compilation.
  sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf
  curl -sO https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz &&
  sudo -u "$name" tar -xvf yay.tar.gz >/dev/null 2>&1 &&
  cd yay &&
  sudo -u "$name" makepkg --noconfirm -si >/dev/null 2>&1
  cd /tmp || return);
}

install_nvm() {
  [ ! -d "/home/$name/.local/src/nvm" ] && mkdir -p "/home/$name/.local/src/nvm" && chown "$name":"$name" "/home/$name/.local/src/nvm" &&
  sudo -u "$name" curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | NVM_DIR="/home/$name/.local/src/nvm" bash >/dev/null 2>&1 &&
  [ -d "/home/$name/.local/src/nvm" ] && chown -R "$name":"$name" "/home/$name/.local/src/nvm"
}

install_composer() {
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" >/dev/null 2>&1
  php -r "if (hash_file('sha384', 'composer-setup.php') === '572cb359b56ad9ae52f9c23d29d4b19a040af10d6635642e646a7caa7b96de717ce683bd797a92ce99e5929cc51e7d5f') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" >/dev/null 2>&1
  php composer-setup.php --install-dir="/home/$name/.local/bin" --filename=composer >/dev/null 2>&1
  [ -f "/home/$name/.local/bin/composer" ] && chown "$name:$name" "/home/$name/.local/bin/composer"
}

install_auto_cpufreq_service() {
  systemctl start auto-cpufreq
  systemctl enable auto-cpufreq
}

### THE ACTUAL SCRIPT ###

install_from_pacman dialog || error "Are you sure you're running this as the root user and have an internet connection?"

welcome_msg || error "User exited."

get_username_and_password || error "User exited."

user_check || error "User exited."

preinstall_msg || error "User exited."

add_user || error "Error adding username and/or password."

configure_sudo

install_dotfiles $dotfilesrepo "/home/$name/.local/src/dotfiles"

install_yay

install_software

install_nvm

install_composer

install_auto_cpufreq_service

clear
