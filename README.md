# LinuxEasyInstaller

easy_installer.sh
===========

Affiche une fenetre permettant de sélectionner des composants à installer parmi:
- `Python3`
- `Docker`
- `PgAdmin4`
- `IntelliJ Community`
- `Smartgit`
- `OpenJdk 8`
- `OpenJdk 11`
- `Node.js`
- `Jhipster`
- `Maven`

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
Affiche une fenêtre avec différents choix permettant de:
- télécharger des packages spécifiés, séparés par un `;`
- installer des packages présents dans les répertoires présents à côté du script (uniquement les répertoires ne contenant que des `.deb` ou `.rpm`)
- supprimer les répertoires ne contenant que des `.deb` ou `.rpm` présents à côté du script
- quitter
