# LinuxEasyInstaller

easy_installer.sh
===========

Affiche une fenetre permettant de sélectionner des composants à installer parmi:
- Python3
- Docker
- PgAdmin4
- Smartgit
- OpenJdk 8
- OpenJdk 11
- Node.js
- Jhipster
- Maven

Usage
=====
```
# Téléchargement du script dans le répertoire courant
wget https://raw.githubusercontent.com/PingouInfini/LinuxEasyInstaller/main/easy_installer.sh
chmod +x easy_installer.sh

# Lancement de l'installer
./easy_installer.sh
```

---
package_downloader.sh
===========
Renseigné dans la variable "LIB_LIST" la liste des package à télécharger
 
Ceux-ci et leurs dpendances seront téléchargés et stockés dans des répertoires nommés selon les packages 
