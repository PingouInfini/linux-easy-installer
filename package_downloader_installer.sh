#!/bin/bash

# Vérifier et installer whiptail si nécessaire
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  echo "Impossible de détecter le système d'exploitation."
  exit 1
fi

# Installer whiptail si absent
if [[ "$OS" == "ubuntu" || "$OS" == "pop" ]]; then
  sudo apt-get install -y whiptail
elif [[ "$OS" == "almalinux" || "$OS" == "rhel" ]]; then
  sudo dnf install -y newt
else
  echo "Système d'exploitation non pris en charge."
  exit 1
fi

# Affichage du menu principal avec whiptail
OPTION=$(whiptail --title "Gestion des paquets" --radiolist \
"Choisissez une action:" 15 50 4 \
"01" "Download packages" OFF \
"02" "Install packages" OFF \
"03" "Clean Package" OFF \
"04" "Exit" OFF 3>&1 1>&2 2>&3)

exitstatus=$?

# Si l'utilisateur annule ou choisit "Exit"
if [ $exitstatus != 0 ] || [ "$OPTION" == "04" ]; then
  echo "Sortie du programme."
  exit 0
fi

# Si l'option "Download packages" est choisie
if [ "$OPTION" == "01" ]; then
  # Demander à l'utilisateur de spécifier les packages à télécharger, séparés par des ";"
  PACKAGE_INPUT=$(whiptail --inputbox "Entrez les noms des packages à télécharger (séparés par ';'):" 10 60 3>&1 1>&2 2>&3)
  
  exitstatus=$?
  if [ $exitstatus != 0 ] || [ -z "$PACKAGE_INPUT" ]; then
    echo "Aucun package spécifié, sortie du programme."
    exit 0
  fi

  # Convertir la liste de packages en un tableau
  IFS=';' read -r -a PACKAGE_LIST <<< "$PACKAGE_INPUT"

  # Boucler sur chaque package et le télécharger
  for lib in "${PACKAGE_LIST[@]}"; do
    echo "#### Téléchargement de "+$lib+" ####"

    mkdir -p $lib && cd $lib

    if [[ "$OS" == "ubuntu" || "$OS" == "pop" ]]; then
      apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-pre-depends $lib | grep "^\w" | sort -u)
    elif [[ "$OS" == "almalinux" || "$OS" == "rhel" ]]; then
      dnf download $(dnf repoquery --requires --resolve $lib | grep -vE '^(installonly|local)')
    fi

    echo ""
    cd ..
  done

# Si l'option "Install packages" est choisie
elif [ "$OPTION" == "02" ]; then
  # Lister les répertoires disponibles dans le dossier courant
  DIR_LIST=$(ls -d */ | cut -f1 -d'/')

  # Afficher la liste des répertoires avec whiptail pour en sélectionner un ou plusieurs
  SELECTED_DIRS=$(whiptail --title "Sélection des répertoires" --checklist \
  "Choisissez les répertoires pour installer les paquets:" 15 50 6 \
  $(for dir in $DIR_LIST; do echo "$dir" OFF; done) 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [ $exitstatus != 0 ]; then
    echo "Aucun répertoire sélectionné, sortie du programme."
    exit 0
  fi

  # Parcourir les répertoires sélectionnés et vérifier le contenu avant installation
  for dir in $SELECTED_DIRS; do
    dir=$(echo $dir | tr -d '"')  # Retirer les guillemets ajoutés par whiptail
    cd "$dir"

    # Vérifier que le répertoire contient uniquement des fichiers .deb ou .rpm selon l'OS
    if [[ "$OS" == "ubuntu" || "$OS" == "pop" ]]; then
      if [ "$(ls | grep -v '.deb')" == "" ]; then
        sudo dpkg -i *.deb
        echo "Installation des paquets .deb dans le répertoire $dir terminée."
      else
        echo "Le répertoire $dir contient des fichiers non .deb, installation ignorée."
      fi
    elif [[ "$OS" == "almalinux" || "$OS" == "rhel" ]]; then
      if [ "$(ls | grep -v '.rpm')" == "" ]; then
        sudo dnf install -y *.rpm
        echo "Installation des paquets .rpm dans le répertoire $dir terminée."
      else
        echo "Le répertoire $dir contient des fichiers non .rpm, installation ignorée."
      fi
    fi

    cd ..
  done

# Si l'option "Clean Package" est choisie
elif [ "$OPTION" == "03" ]; then
  # Demander confirmation pour supprimer les répertoires
  if (whiptail --title "Nettoyage des packages" --yesno "Voulez-vous vraiment supprimer les répertoires contenant uniquement des fichiers .deb ou .rpm ?" 10 60); then
    # Lister les répertoires disponibles dans le dossier courant
    for dir in */; do
      dir=${dir%/}  # Supprimer le slash à la fin du nom de répertoire

      # Vérifier que tous les fichiers sont soit des .deb, soit des .rpm, selon l'OS
      cd "$dir"
      if [[ "$OS" == "ubuntu" || "$OS" == "pop" ]]; then
        # Vérifier si seuls des .deb sont présents
        if [ "$(ls | grep -v '.deb')" == "" ]; then
          cd ..
          rm -rf "$dir"
          echo "Répertoire $dir supprimé."
        else
          cd ..
        fi
      elif [[ "$OS" == "almalinux" || "$OS" == "rhel" ]]; then
        # Vérifier si seuls des .rpm sont présents
        if [ "$(ls | grep -v '.rpm')" == "" ]; then
          cd ..
          rm -rf "$dir"
          echo "Répertoire $dir supprimé."
        else
          cd ..
        fi
      fi
    done
  else
    echo "Nettoyage annulé."
  fi
fi

