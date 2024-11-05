#!/bin/bash

# Charger les variables d'environnement depuis dist.env
set -o allexport
source ../dist.env
set +o allexport

# Répertoire pour les logs
LOG_DIR="/home/$USER/$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR"

# Ajout d'un horodatage au format année-mois-jour_heure-minute-seconde
timestamp=$(date +"%Y%m%d_%H%M%S")

# Génère les logs pour chaque conteneur actif et les enregistre dans des fichiers séparés avec horodatage
for container_id in $(docker ps -q); do
  container_name=$(docker inspect --format='{{.Name}}' "$container_id" | cut -c2-)  # Supprime le premier "/" du nom du conteneur
  docker logs "$container_id" > "$LOG_DIR/${container_name}_${timestamp}.log"
done

echo "Génération des logs Docker pour tous les conteneurs terminée."
