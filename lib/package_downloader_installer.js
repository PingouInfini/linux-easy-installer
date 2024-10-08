const inquirer = require('inquirer').default;
const { execSync } = require('child_process');
const fs = require('fs');

// Fonction pour déterminer l'OS depuis /etc/os-release
function detectOS() {
  if (fs.existsSync('/etc/os-release')) {
    const osRelease = fs.readFileSync('/etc/os-release', 'utf8');
    const osInfo = {};

    // Lire chaque ligne du fichier et extraire les informations
    osRelease.split('\n').forEach(line => {
      const [key, value] = line.split('=');
      if (key && value) {
        osInfo[key] = value.replace(/"/g, '');  // Retirer les guillemets des valeurs
      }
    });

    return osInfo.ID;  // Retourne l'ID du système, par exemple 'almalinux', 'ubuntu', etc.
  } else {
    return 'unknown';  // Si /etc/os-release n'existe pas
  }
}

function telechargerPackagesAction() {
  inquirer.prompt([
    {
      type: 'input',
      name: 'packages',
      message: 'Entrez les noms des packages à télécharger (séparés par ";") :',
    }
  ]).then(pkgAnswers => {
    telechargerPackages(pkgAnswers.packages);
  });
}


// Fonction pour télécharger des packages
function telechargerPackages(packages) {
  const packageList = packages.split(';');
  packageList.forEach(lib => {
    lib = lib.trim();
    console.log(`#### Téléchargement de ${lib} ####`);

    try {
      execSync(`mkdir -p ${lib}/required`);

      // Détection de l'OS
      const OS = detectOS();
      if (OS === 'ubuntu' || OS === 'pop') {
        execSync(`apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-pre-depends ${lib} | grep "^\\w" | sort -u)`, { stdio: 'pipe' });
        execSync(`mv *.deb '${lib}/required'`, { stdio: 'pipe' });
      } else if (OS === 'almalinux' || OS === 'rhel') {
        execSync(`dnf download $(dnf repoquery --requires --resolve ${lib} | grep -vE '^(installonly|local)')`, { stdio: 'pipe' });
        execSync(`mv *.rpm '${lib}/required'`, { stdio: 'pipe' });
      }

      // Téléchargement du package principal
      if (OS === 'ubuntu' || OS === 'pop') {
        execSync(`apt-get download ${lib}`, { stdio: 'pipe' });
        execSync(`mv *.deb '${lib}'`, { stdio: 'pipe' });
      } else if (OS === 'almalinux' || OS === 'rhel') {
        execSync(`dnf download ${lib}`, { stdio: 'pipe' });
        execSync(`mv *.rpm '${lib}'`, { stdio: 'pipe' });
      }
    } catch (error) {
      console.error(`Erreur lors du téléchargement de ${lib}`);
      execSync(`rm -rf ${lib}`);
    }
  });
}

// Fonction pour installer les packages
function installerPackagesAction() {
  try {
    // Récupérer les répertoires et exclure "lib"
    const dirs = execSync('ls -d */ | cut -f1 -d"/"', { encoding: 'utf-8' })
      .split('\n')
      .filter(dir => dir && dir !== 'lib'); // Exclure le répertoire "lib"

    if (dirs.length === 0) {
      console.log("Aucun répertoire disponible pour l'installation.");
      return;
    }

    inquirer.prompt([{
      type: 'checkbox',
      name: 'selectedDirs',
      message: 'Choisissez les répertoires pour installer les paquets :',
      choices: dirs
    }]).then(answers => {
      const { selectedDirs } = answers;
      const OS = detectOS();

      selectedDirs.forEach(dir => {
        console.log(`Installation dans le répertoire ${dir}`);

        // Vérifier la présence du répertoire "required"
        const requiredDir = `${dir}/required`;
        let hasRequiredDir = false;

        try {
          execSync(`ls ${requiredDir}`, { stdio: 'ignore' });
          hasRequiredDir = true; // Si la commande réussit, le répertoire "required" existe
        } catch {
          // Si execSync échoue, on ne fait rien (le répertoire "required" n'existe pas)
        }

        // Vérifier l'OS et installer les paquets en conséquence
        if (OS === 'ubuntu' || OS === 'pop') {
          // Vérifier si le répertoire contient uniquement des fichiers .deb ou des répertoires
          const files = execSync(`find ${dir} -maxdepth 1 -type f`).toString().trim().split('\n').filter(file => file);
          const hasOnlyDebOrDirs = files.every(file => file.endsWith('.deb') || file.endsWith('.'));

          if (hasOnlyDebOrDirs) {
            // Installer les paquets du répertoire "required" s'il existe
            if (hasRequiredDir) {
              execSync(`sudo dpkg -i ${requiredDir}/*.deb`);
              console.log(` -> Installation des dépendances terminée.`);
            }

            // Installer les paquets .deb du répertoire actuel
            execSync(`sudo dpkg -i ${dir}/*.deb`);
            console.log(` -> Installation des paquets .deb dans ${dir} terminée.`);
          } else {
            console.log(`Le répertoire ${dir} contient des fichiers non .deb.`);
          }
        } else if (OS === 'almalinux' || OS === 'rhel') {
          // Vérifier si le répertoire contient uniquement des fichiers .rpm ou des répertoires
          const files = execSync(`find ${dir} -maxdepth 1 -type f`).toString().trim().split('\n').filter(file => file);
          const hasOnlyRpmOrDirs = files.every(file => file.endsWith('.rpm') || file.endsWith('.'));

          if (hasOnlyRpmOrDirs) {
            // Installer les paquets du répertoire "required" s'il existe
            if (hasRequiredDir) {
              execSync(`sudo dnf install -y ${requiredDir}/*.rpm`);
              console.log(` -> Installation des dépendances terminée.`);
            }

            // Installer les paquets .rpm du répertoire actuel
            execSync(`sudo dnf install -y ${dir}/*.rpm`);
            console.log(` -> Installation des paquets .rpm dans ${dir} terminée.`);
          } else {
            console.log(`Le répertoire ${dir} contient des fichiers non .rpm.`);
          }
        }
      });
    });
  } catch (error) {
    console.error("Erreur lors de l'installation des paquets :", error.message);
  }
}


// Fonction pour vérifier si un répertoire contient uniquement des fichiers avec l'extension donnée
function hasOnlyPackages(dir, fileExtension) {
  const items = execSync(`ls -A ${dir}`).toString().trim().split('\n');

  // Vérifier chaque élément dans le répertoire
  for (const item of items) {
    // Ignorer les éléments vides ou nuls
    if (!item) {
      continue;
    }

    const itemPath = `${dir}/${item}`;
    const stats = fs.lstatSync(itemPath); // Utilisation de lstatSync pour vérifier les répertoires

    // Si c'est un répertoire, vérifier récursivement
    if (stats.isDirectory()) {
      if (!hasOnlyPackages(itemPath, fileExtension)) {
        return false; // Si un sous-répertoire ne contient pas uniquement des packages
      }
    } else if (!item.endsWith(`.${fileExtension}`)) {
      return false; // Si un fichier ne correspond pas à l'extension
    }
  }
  return true; // Tous les éléments sont des fichiers ou des répertoires avec des fichiers d'extension correcte
}

// Fonction pour nettoyer les packages
function cleanPackagesAction() {
  inquirer.prompt([{
    type: 'confirm',
    name: 'confirm',
    message: 'Êtes-vous sûr de vouloir nettoyer les packages existants ?',
    default: false
  }]).then(answers => {
    if (!answers.confirm) {
      console.log("Nettoyage annulé.");
      return;
    }

    const OS = detectOS();
    if (!OS) {
      console.log("Système d'exploitation non supporté.");
      return;
    }

    const dirs = execSync('ls -d */', { encoding: 'utf-8' })
      .split('\n')
      .filter(dir => dir && dir !== 'lib/'); // Exclure le répertoire "lib"

    dirs.forEach(dir => {
      dir = dir.trim();

      try {
        let fileExtension;
        if (OS === 'ubuntu' || OS === 'pop') {
          fileExtension = 'deb';
        } else if (OS === 'almalinux' || OS === 'rhel') {
          fileExtension = 'rpm';
        }

        // Vérification si le répertoire contient uniquement des fichiers d'extension donnée ou des répertoires valides
        const isOnlyPackages = hasOnlyPackages(dir, fileExtension);

        // Si tous les fichiers dans le répertoire sont des *.deb ou *.rpm, on supprime le répertoire
        if (isOnlyPackages) {
          execSync(`rm -rf ${dir}`);
        }
      } catch (error) {
        console.error(`Erreur lors du nettoyage du répertoire ${dir}:`, error.message);
      }
    });
  });
}

// Action pour quitter le programme
function quitterProgrammeAction() {
  console.log("Fermeture du programme.");
  process.exit(0);
}


const menuOptions = {
  'Télécharger des packages': telechargerPackagesAction,
  'Installation de packages téléchargés': installerPackagesAction,
  'Clean les packages existants': cleanPackagesAction,
  'Quitter': quitterProgrammeAction
};

// Fonction principale pour le menu
function mainMenu() {
  inquirer.prompt([
    {
      type: 'list',
      name: 'action',
      message: 'Que souhaitez-vous faire ?',
      choices: Object.keys(menuOptions)
    }
  ]).then(answers => {
    const { action } = answers;

    // Exécute l'action correspondante en appelant la fonction associée
    const selectedAction = menuOptions[action];
    if (selectedAction) {
      selectedAction();  // Appelle la fonction associée à l'action choisie
    } else {
      console.log("Action inconnue, fermeture du programme.");
      process.exit(1);
    }
  }).catch(error => {
    if (error.isTtyError) {
      console.log("Erreur : L'environnement TTY n'est pas pris en charge.");
    } else {
      console.log("Fermeture du programme.");
      process.exit(0);
    }
  });
}

// Lancer le menu principal
mainMenu();

