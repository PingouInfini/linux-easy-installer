#!/bin/bash

# use sudo command to force user to set his password at the beginning of the script
sudo ls >/dev/null 2>&1

check_if_package_installed () {
    PKG_INSTALLED=$(dpkg-query -W --showformat='${Status}\n' "$1")
    if [ "$PKG_INSTALLED" != "install ok installed" ]; then
        sudo apt -y install "$1"
    fi
}

get_version_of_package() {
  aptitude versions "$1" |head -2 |tail -1 | awk '{print $2}'
}

# Isntallation de docker, avec version en parametre $1
install_docker() {
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  #add Docker's offical GPG key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  #set stable repository
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  #install docker-ce
  sudo apt-get update && sudo apt-get install -y docker-ce

  #set daemon to expose interface on 2375 and enable ipv6 routing to containers
  echo '{
  "debug": true,
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64",
  "hosts": ["unix:///var/run/docker.sock", "tcp://127.0.0.1:2375"]
  }' | sudo tee -a /etc/docker/daemon.json

  sudo mkdir -p /etc/systemd/system/docker.service.d

  echo '[Service]
  ExecStart=
  ExecStart=/usr/bin/dockerd' | sudo tee -a /etc/systemd/system/docker.service.d/docker.conf


  sudo systemctl daemon-reload
  sudo systemctl restart docker

  #install docker-compose
  sudo curl -L "https://github.com/docker/compose/releases/download/""$1""/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

  #add current user to docker group
  sudo usermod -aG docker "$USER"
}

install_python3() {
  sudo apt install -y python3
  sudo apt install -y python3-pip
}

install_openjdk8() {
  sudo add-apt-repository ppa:openjdk-r/ppa
  sudo apt-get update
  sudo apt-get install -y openjdk-8-jdk
}

install_openjdk8() {
  sudo add-apt-repository ppa:openjdk-r/ppa
  sudo apt-get update
  sudo apt-get install -y openjdk-8-jdk
}

install_nodejs() {
  sudo apt install -y nodejs
}

install_jhipster() {
  if which node > /dev/null
    then
        : #"node is installed, skipping..."
    else
        install_nodejs
    fi
  npm install -g generator-jhipster
}

launch_easy_install() {
  HEIGHT=15
  WIDTH=40
  CHOICE_HEIGHT=6

  TITLE="Easy install"
  MENU="Choix des composants à installer:"

  CHOIX=$(whiptail --title "$TITLE" --checklist \
  "$MENU" "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
  "01" "Python3" OFF \
  "02" "Docker" OFF \
  "03" "OpenJdk 8" OFF \
  "04" "OpenJdk 11" OFF \
  "05" "Node.js" OFF \
  "06" "Jhipster" OFF \
  3>&1 1>&2 2>&3)

  case $CHOIX in
          *01*)
              PYTHON3_VERSION=$(get_version_of_package python3)
              PIP_VERSION=$(get_version_of_package python3-pip)
              echo "### Installation de Python v""$PYTHON3_VERSION"" + pip v""$PIP_VERSION"
              install_python3
              ;;&
          *02*)
              DOCKER_VERSION=1.28.2
              echo "### Installation de Docker v"$DOCKER_VERSION
              install_docker $DOCKER_VERSION
              ;;&
          *03*)
              OPENJDK8_VERSION=$(get_version_of_package openjdk-8-jdk)
              echo "### Installation d'OpenJDK v"OPENJDK8_VERSION
              install_openjdk8
              ;;&
          *04*)
              OPENJDK11_VERSION=$(get_version_of_package openjdk-11-jdk)
              echo "### Installation d'OpenJDK v"OPENJDK11_VERSION
              install_openjdk11
              ;;&
          *05*)
              NODEJS_VERSION=$(get_version_of_package nodejs)
              echo "### Installation de nodejs v""$NODEJS_VERSION"
              install_nodejs
              ;;&
          *06*)
              echo "### Installation de Jhipster"
              install_jhipster
              ;;&
  esac
}

check_if_package_installed whiptail
check_if_package_installed aptitude
launch_easy_install