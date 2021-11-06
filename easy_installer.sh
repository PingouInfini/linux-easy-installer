#!/bin/bash

# use sudo command to force user to set his password at the beginning of the script
sudo ls >/dev/null 2>&1

reboot_is_needed=false

apt_install_package(){
  sudo apt install -y "$1" 2>/dev/null | grep packages | cut -d '.' -f 1
}

check_if_package_installed () {
    PKG_INSTALLED=$(dpkg-query -W --showformat='${Status}\n' "$1")
    if [ "$PKG_INSTALLED" != "install ok installed" ]; then
        apt_install_package "$1"
    fi
}

get_version_of_package() {
  aptitude versions "$1" |head -2 |tail -1 | awk '{print $2}'
}

# Isntallation de docker, avec version en parametre $1
install_docker() {
  sudo apt-get update 2>/dev/null | grep packages | cut -d '.' -f 1
  apt_install_package apt-transport-https
  apt_install_package ca-certificates
  apt_install_package curl
  apt_install_package software-properties-common
  #add Docker's offical GPG key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  #set stable repository
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  #install docker-ce
  sudo apt-get update 2>/dev/null | grep packages | cut -d '.' -f 1
  apt_install_package docker-ce

  #set daemon to expose interface on 2375 and enable ipv6 routing to containers
  echo '{
  "debug": true,
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64",
  "hosts": ["unix:///var/run/docker.sock", "tcp://127.0.0.1:2375"]
  }' | sudo tee -a /etc/docker/daemon.json 2>/dev/null

  sudo mkdir -p /etc/systemd/system/docker.service.d

  echo '[Service]
  ExecStart=
  ExecStart=/usr/bin/dockerd' | sudo tee -a /etc/systemd/system/docker.service.d/docker.conf 2>/dev/null


  sudo systemctl daemon-reload
  sudo systemctl restart docker

  #install docker-compose
  sudo curl -L "https://github.com/docker/compose/releases/download/""$1""/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 2>/dev/null
  sudo chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

  #add current user to docker group
  sudo usermod -aG docker "$USER"

  reboot_is_needed=true
}

install_pgadmin4() {
  # Install the public key for the repository (if not done previously):
  sudo curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo apt-key add

  # Create the repository configuration file:
  sudo sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'

  # Install for desktop mode only:
  apt_install_package pgadmin4-desktop

  # Add in /usr/bin & /usr/local/bin
  sudo ln -s /usr/pgadmin4/bin/pgadmin4 /usr/local/bin/pgadmin4
  sudo ln -s /usr/pgadmin4/bin/pgadmin4 /usr/bin/pgadmin4
}

install_smartgit() {
  mkdir ~/Apps
  # Get Smartgit 19
  wget -O ~/Apps/smartgit-linux-19_1_8.tar.gz https://www.syntevo.com/downloads/smartgit/smartgit-linux-19_1_8.tar.gz
  # Unarchive it
  tar xzf ~/Apps/smartgit-linux-19_1_8.tar.gz -C ~/Apps
  # Remove archive
  rm -rf ~/Apps/smartgit-linux-19_1_8.tar.gz

  # Script for licence
  cp ~/.config/smartgit/19.1/preferences.yml ~/.config/smartgit/19.1/preferences.bck
  echo "rm -rf ~/.config/smartgit/19.1/preferences.yml" > ~/Apps/smartgit/remove-licence.sh
  chmod +x ~/Apps/smartgit/remove-licence.sh

  # Add in /usr/bin & /usr/local/bin
  sudo ln -s ~/Apps/smartgit/bin/smartgit.sh /usr/local/bin/smartgit
  sudo ln -s ~/Apps/smartgit/bin/smartgit.sh /usr/bin/smartgit
}

install_python3() {
  apt_install_package python3
  apt_install_package python3-pip
}

install_openjdk8() {
  sudo add-apt-repository ppa:openjdk-r/ppa
  sudo apt-get update 2>/dev/null | grep packages | cut -d '.' -f 1
  apt_install_package openjdk-8-jdk
}

install_openjdk11() {
  apt_install_package openjdk-11-jdk
}

install_nodejs() {
  curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - 2>/dev/null
  sudo apt-get update 2>/dev/null | grep packages | cut -d '.' -f 1
  apt_install_package nodejs
  if which npm > /dev/null
    then
        : #"npm is installed, skipping..."
    else
        install_npm
    fi
}

install_npm() {
  apt_install_package npm
}

install_jhipster() {
  if which node > /dev/null
    then
        : #"node is installed, skipping..."
    else
        install_nodejs
    fi

  sudo npm install -g generator-jhipster  2> /dev/null
}

install_maven() {
  apt_install_package maven
}

ask_for_reboot(){
  read -r -p "Are you sure? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        echo "rebooting ..."
        sleep 2
        sudo reboot
        ;;
    *)
        :
        ;;
esac
}


launch_easy_install() {
  HEIGHT=15
  WIDTH=40
  CHOICE_HEIGHT=9

  TITLE="Easy install"
  MENU="Choix des composants à installer:"

  CHOIX=$(whiptail --title "$TITLE" --checklist \
  "$MENU" "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
  "01" "Python3" OFF \
  "02" "Docker" OFF \
  "03" "PgAdmin4" OFF \
  "04" "Smartgit" OFF \
  "05" "OpenJdk8" OFF \
  "06" "OpenJdk11" OFF \
  "07" "Node.js" OFF \
  "08" "Jhipster" OFF \
  "09" "Maven" OFF \
  3>&1 1>&2 2>&3)

  case $CHOIX in
          *01*)
              echo "### Installation de Python + pip ..."
              install_python3
              echo "Terminé"
              echo "***************************************"
              echo $(python3 --version)
              echo $(pip3 --version)
              echo "***************************************"
              echo ""
              ;;&
          *02*)
              DOCKER_RELEASE=1.29.2
              echo "### Installation de Docker ..."
              install_docker $DOCKER_RELEASE
              echo "Terminé"
              echo "***************************************"
              echo $(docker --version)
              echo "***************************************"
              echo ""
              ;;&
          *03*)
              echo "### Installation de PgAdmin4 ..."
              install_pgadmin4
              echo "Terminé"
              echo "***************************************"
              echo $(pgadmin4 -version)
              echo "***************************************"
              echo ""
              ;;&
          *04*)
              echo "### Installation de Smartgit ..."
              install_smartgit
              echo "Terminé"
              echo "***************************************"
              echo $(cat ~Apps/smartgit/changelog.txt | head -1)
              echo "***************************************"
              echo ""
              ;;&
          *05*)
              echo "### Installation d'OpenJDK8 ..."
              install_openjdk8
              echo "Terminé"
              echo "***************************************"
              echo $(java --version | head -1)
              echo "***************************************"
              echo ""
              ;;&
          *06*)
              echo "### Installation d'OpenJDK11 ..."
              install_openjdk11
              echo "Terminé"
              echo "***************************************"
              echo $(java --version | head -1)
              echo "***************************************"
              echo ""
              ;;&
          *07*)
              echo "### Installation de nodejs et npm ..."
              install_nodejs
              echo "Terminé"
              echo "***************************************"
              echo "node" $(node --version)
              echo "npm" $(npm --version)
              echo "***************************************"
              echo ""
              ;;&
          *08*)
              echo "### Installation de Jhipster ..."
              install_jhipster
              echo "Terminé"
              echo "***************************************"
              echo $(jhipster --version)
              echo "***************************************"
              echo ""
              ;;&
          *09*)
              echo "### Installation de Maven ..."
              install_maven
              echo "Terminé"
              echo "***************************************"
              echo $(mvn --version)
              echo "***************************************"
              echo ""
              ;;&
  esac
}

check_if_package_installed whiptail
check_if_package_installed aptitude
launch_easy_install

if [ "$reboot_is_needed" = true ] ; then
    echo "Un redémarrage est nécessaire pour finaliser l'installation"
    ask_for_reboot
fi
