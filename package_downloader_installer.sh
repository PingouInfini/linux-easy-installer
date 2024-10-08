#!/bin/bash

# Sauvegarde du répertoire courant pour y revenir plus tard
START_DIR=$(pwd)

# Vérification du système d'exploitation
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  echo "ERREUR : Impossible de détecter le système d'exploitation."
  exit 1
fi

# Vérifier si Node.js est installé
if ! command -v node &> /dev/null; then
  if [[ "$OS" == "ubuntu" ]]; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - > /dev/null 2>&1
    sudo apt-get install -y nodejs > /dev/null 2>&1
  elif [[ "$OS" == "almalinux" || "$OS" == "rhel" ]]; then
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash - > /dev/null 2>&1
    sudo dnf install -y nodejs > /dev/null 2>&1
  else
    echo "ERREUR : Système d'exploitation non pris en charge."
    exit 1
  fi
fi

# Assurer la présence de npm
if ! command -v npm &> /dev/null; then
  if [[ "$OS" == "ubuntu" ]]; then
    sudo apt-get install -y npm > /dev/null 2>&1
  elif [[ "$OS" == "almalinux" || "$OS" == "rhel" ]]; then
    sudo dnf install -y npm > /dev/null 2>&1
  fi
fi

# Vérification de la présence de la bibliothèque inquirer
cd lib || { echo "ERREUR : Répertoire lib introuvable."; exit 1; }
if ! npm list inquirer --silent >/dev/null 2>&1; then
  npm install inquirer --silent
fi

# Revenir au répertoire initial
cd "$START_DIR" || exit 1

# Lancer inquirer.js
node lib/inquirer.js

