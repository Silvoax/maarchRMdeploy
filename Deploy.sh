#! /bin/bash

initDir=`pwd`

source script.conf
source install.conf
source globalFunctions.sh

Titre1 "Vérification de l'installation des pré-requis :";
./checkPackage.sh
Pause

if ${interactiveMode}; then
  Titre1 "Selectionnez le type de l'instance maarch RM à déployer - Socle ou AP (défaut = ${type})";
  optionsTypes=('Socle' 'AP');
  opt=`selectWithDefault "${optionsTypes[@]}"`
  case $opt in
    '')      type=${type}; ;;
    'Socle') type="Socle"; ;;
    'AP')    type="AP"; ;;
  esac
fi

Titre1 "Récupération des sources sur le serveur gitLab.";

dirApplication=${installDir}/${dirName}
dirConf=${dirApplication}/data/maarchRM/conf

cd $installDir;
git clone https://labs.maarch.org/maarch/maarchRM.git $dirName

if [ $? -ne 0 ]; then
  Titre2 "Application socle de maarch RM déjà installée dans ${dirApplication}";
else
  Titre2 "Application socle de maarch RM installée dans ${dirApplication}";
  cd ${dirApplication}
  sed -i -e "s/filemode = true/filemode = false/g" .git/config
  git checkout ${branch}
fi
Pause

if [ $type = "AP" ]; then
    Titre2 "Installation de l'extension Archives Publiques";
    cd ${dirApplication}/src/ext
    git clone https://labs.maarch.org/maarch/archivesPubliques.git
    if [ $? -ne 0 ]; then
      Titre2 "L'extension Archives Publiques est déjà installée.";
    else
      cd ${dirApplication}/src/ext/archivesPubliques
      sed -i -e "s/filemode = true/filemode = false/g" .git/config
      git checkout ${branch}
    fi
    dirConf=${dirApplication}/src/ext/archivesPubliques/data/conf
fi

touch ${stockrep1}/test.txt >/dev/null 2>&1
if [ $? -ne 0 ]; then
  Titre2 "Création du répertoire de stockage ${stockrep1}";
  Pause
  mkdir -p ${stockrep1}
else
  rm ${stockrep1}/test.txt
fi

touch ${stockrep2}/test.txt >/dev/null 2>&1
if [ $? -ne 0 ]; then
  Titre2 "Création du répertoire de stockage ${stockrep2}";
  Pause
  mkdir -p ${stockrep2}
else
  rm ${stockrep2}/test.txt
fi

Titre2 "Paramètrage de l'application Maarch RM ${type}";

cd ${dirConf}
cp configuration.ini.default configuration.ini
cp confvars.ini.default confvars.ini
cp vhost.conf.default vhost.conf

Titre2 "Attribution du ServerName ${hostname} dans le fichier vhost.conf : "
Pause

toFind=`grep ServerName vhost.conf`
new="    ServerName ${hostname}"
sed -i -e "s|${toFind}|${new}|g" vhost.conf

toFind=`grep DocumentRoot vhost.conf`
new="    DocumentRoot ${dirApplication}/web"
sed -i -e "s|${toFind}|${new}|g" vhost.conf

Titre2 "Creation du fichier de configuration de connexion BDD"
Pause

toFind=`grep @var.dsn confvars.ini`
new="@var.dsn = 'pgsql:host=${bddHost};dbname=${bddName};port=${bddPort}'"
sed -i -e "s/${toFind}/${new}/g" confvars.ini

toFind=`grep @var.username confvars.ini`
new="@var.username = ${bddUser}"
sed -i -e "s/${toFind}/${new}/g" confvars.ini

toFind=`grep @var.password confvars.ini`
new="@var.password = ${bddPassword}"
sed -i -e "s/${toFind}/${new}/g" confvars.ini

create=${createBDDUser}
if $interactiveMode; then
  Titre1 "Faut-il créer l'utilisateur ${bddUser} dans la base de données localisée à ${bddHost} ? (Défaut = Oui)"
  optionsTypes=('Oui' 'Non');
  opt=`selectWithDefault "${optionsTypes[@]}"`
  case $opt in
    'Oui'|'') createBDDUser=true; ;;
    'Non')    createBDDUser=false; ;;
  esac
fi

if $createBDDUser; then
    Titre2 "Création de l'utilisateur ${bddUser} sur PostGreSQL";
    Pause
    su postgres -c "psql --command \"CREATE USER ${bddUser};\""
    su postgres -c "psql --command \"ALTER ROLE ${bddUser} WITH CREATEDB;\""
    su postgres -c "psql --command \"ALTER ROLE ${bddUser} WITH SUPERUSER;\""
    su postgres -c "psql --command \"ALTER USER ${bddUser} WITH ENCRYPTED PASSWORD '${bddPassword}';\""
    su postgres -c "export PGPASSWORD=${bddPassword}"
fi

createBDD=${createBDD}
if $interactiveMode; then
  Titre1 "Faut-il créer la base de données ${bddName} sur ${bddHost} ? (Défaut = Oui)"
  optionsTypes=('Oui' 'Non');
  opt=`selectWithDefault "${optionsTypes[@]}"`
  case $opt in
    'Oui'|'') createBDD=true; ;;
    'Non')    createBDD=false; ;;
  esac
fi
if $createBDD; then
    Titre2 "Création de la base de donnée ${bddName}";
    Pause
    commande='"CREATE DATABASE ';
    commande+="\\\"${bddName}\\\"";
    commande+=' WITH OWNER ';
    commande+="${bddUser};\"";
    su postgres -c "psql --command ${commande}"
fi

SQLstart=${SQLstart}
  if $interactiveMode; then
  Titre1 "Faut-il insérer le jeu de démo ou les données minimales dans la base de données ? (Défaut = Jeu de démo)"
  optionsTypes=('Demo' 'Minimal' 'Rien');
  opt=`selectWithDefault "${optionsTypes[@]}"`
  case $opt in
    'Demo'|'')      SQLstart="Demo"; ;;
    'Minimal')     SQLstart="Minimal"; ;;
    'Rien')         SQLstart="Rien"; ;;
  esac
fi

cd ${dirConf}/../batch/pgsql
chmod +x *.sh
export PGPASSWORD=${bddPassword}

if [ $SQLstart = "Demo" ]; then
    Titre2 "Création des données de démo dans la base ${bddName}";
    Pause
    ./schema.sh -u="${bddUser}" -d="${bddName}" -h="${bddHost}" -p="${bddPort}"
    ./data.sh -u="${bddUser}" -d="${bddName}" -h="${bddHost}" -p="${bddPort}"
fi
if [ $SQLstart = "Minimale" ]; then
    Titre2 "Création des données de démo dans la base ${bddName}";
    Pause
    ./schema.sh -u="${bddUser}" -d="${bddName}" -h="${bddHost}" -p="${bddPort}"
    ./data.min.sh -u="${bddUser}" -d="${bddName}" -h="${bddHost}" -p="${bddPort}"
fi

vhostActivation=${vhostActivation}
if $interactiveMode; then
  Titre1 "Voulez-vous créer le Virtual Host de Apache ? (Défaut = Oui) "
  optionsTypes=('Oui' 'Non');
  opt=`selectWithDefault "${optionsTypes[@]}"`
  case $opt in
    'Oui'|'') vhostActivation=true; ;;
    'Non')    vhostActivation=false; ;;
  esac
fi
if $vhostActivation; then
  Titre2 "Création du fichier ${hostname}.conf dans sites-available : ";
  Pause
  echo "Include ${dirConf}/vhost.conf" > /etc/apache2/sites-available/${hostname}.conf
  a2ensite ${hostname}
  service apache2 reload
fi

hostsAdding=${hostsAdding}
  if $interactiveMode; then
  Titre1 "Voulez-vous créer l'entrée DNS locale (${hostname} --> 127.0.0.1) ?"
  optionsTypes=('Oui' 'Non');
  opt=`selectWithDefault "${optionsTypes[@]}"`
  case $opt in
    'Oui'|'') hostsAdding=true; ;;
    'Non')    hostsAdding=false; ;;
  esac
fi
if ${hostsAdding}; then
    Titre2 "Création de l'entrée DNS dans /etc/hosts : ";
    if [ `grep -c " ${hostname}" /etc/hosts` -gt 0 ]; then
      echo "L'entrée ${hostname} existe déja.";
    else
      echo "127.0.0.1   ${hostname}" >> /etc/hosts
    fi
fi

Titre1 "Attribution des droits au user et group Apache sur le repertoire ${dirApplication} :"
Pause
chown -R ${apacheRunUser}:${apacheRunGroup} ${dirApplication}
chmod -R 775 ${dirApplication}

Titre1 "Attribution des droits au user et group Apache sur le repertoire ${stockrep1} et ${stockrep2} :"
Pause
chown -R ${apacheRunUser}:${apacheRunGroup} ${stockrep1}
chmod -R 775 ${stockrep1}
chown -R ${apacheRunUser}:${apacheRunGroup} ${stockrep2}
chmod -R 775 ${stockrep2}

Titre1 "L'application est disponible localement en accédant à l'adresse http://${hostname}/ dans votre navigateur."
Pause
