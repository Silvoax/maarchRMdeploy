# SCRIPT DE TELECHARGEMENT ET DEPLOIEMENT D'UNE INSTANCE MAARCH RM

## Pré-requis 

Avant d’exécuter le script, les pré-requis pour l'installation de l'application Maarch RM doivent-être remplis. 
Voir pré-requis ici : https://docs.maarch.org/gitbook/html/maarchRM/2.6/conf/requirements.html

## Fichier configuration :

### install.conf

Ce fichier contient les directives de configuration de l'instance Maarch RM à déployer (du téléchargement des sources à la création du Virtual Host d'Apache). 

### scirpt.conf 

Ce fichier contient les directives de configuration du script en lui-même. En effet, même si le fichier install.conf à été modifié, il est possible de revenir sur certains paramètres lors de l’exécution du script.

### Deploy.sh

Ce fichier est le script à lancer. Il récupère les informations des 2 fichiers précédents pour adapter l'installation à effectuer.
