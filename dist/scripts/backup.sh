#!/bin/bash

# Charger les variables d'environnement depuis dist.env
set -o allexport
source ../dist.env
set +o allexport

# Définition du répertoire de sauvegarde et création d'un horodatage pour identifier les fichiers de sauvegarde
BACKUP_DIR="/home/$USER/$PROJECT_DIR/backup"
timestamp=$(date +"%Y%m%d_%H%M%S")


echo $BACKUP_DIR
# Vérifie si le répertoire de sauvegarde existe, sinon le crée
mkdir -p $BACKUP_DIR

# Sauvegarde des fichiers WordPress (contenu du volume) avec compression
tar -czf $BACKUP_DIR/wordpress_backup_$timestamp.tar.gz -C ../volumes/wp .

# Sauvegarde de la base de données MySQL en fichier SQL, puis stockage dans le répertoire de sauvegarde
docker exec -i $(docker-compose -f ../docker-compose-wp.yml ps -q db) mariadb-dump -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" > $BACKUP_DIR/db_backup_$timestamp.sql

echo "Sauvegarde terminée : fichiers WordPress et base de données sauvegardés dans $BACKUP_DIR."
