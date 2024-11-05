#!/bin/bash

# Mise à jour du système et installation des dépendances de base
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Détecte le répertoire courant pour définir le chemin absolu des scripts
BASE_DIR=$(pwd)

# Vérification de la présence d'OpenSSL pour le déchiffrement de dist.env.enc
if ! command -v openssl &> /dev/null; then
  echo "OpenSSL n'est pas installé. Installation d'OpenSSL..."
  sudo apt-get install -y openssl
fi

# Déchiffrement de dist.env.enc dans ../dist.env
read -sp "Enter password to decrypt dist.env: " password
openssl enc -aes-256-cbc  -d -in ../dist.env.enc -out ../dist.env -pass pass:"$password" -pbkdf2

# Vérification du succès du déchiffrement
if [ $? -ne 0 ]; then
  echo "Échec du déchiffrement de dist.env.enc."
  exit 1
fi

# Charger les variables d'environnement depuis dist.env
set -o allexport
source ../dist.env
set +o allexport

# Libération du port 80 si un autre processus l'occupe
echo "Vérification et libération du port 80..."
sudo fuser -k 80/tcp || echo "Le port 80 est déjà libre."

# Vérification si Docker est déjà installé, sinon procéder à son installation
if ! command -v docker &> /dev/null; then
  echo "Docker non détecté. Installation de Docker..."

  # Ajout de la clé GPG de Docker pour un téléchargement sécurisé
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  # Ajout du dépôt Docker à la liste des sources APT
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Installation de Docker
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


else
  echo "Docker est déjà installé."
fi

sudo usermod -aG docker $USER

echo "Relancer terminan si erreur avec Daemen permission denied"

# Vérification de la présence de Docker Compose
if ! command -v docker-compose &> /dev/null; then
  echo "Installation de Docker Compose..."

  # Récupération de la dernière version de Docker Compose
  DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)

  # Téléchargement de Docker Compose dans /usr/local/bin
  sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

  # Donner les permissions d'exécution pour Docker Compose
  sudo chmod +x /usr/local/bin/docker-compose

  # Vérification de l'installation
  if command -v docker-compose &> /dev/null; then
    echo "Docker Compose installé avec succès."
    docker-compose --version
  else
    echo "Erreur : Docker Compose n'a pas pu être installé."
  fi
else
  echo "Docker Compose est déjà installé."
fi


# Installation de Certbot et du plugin Nginx pour gérer automatiquement les certificats SSL
if ! command -v certbot &> /dev/null; then
  echo "Installation de Certbot et du plugin Nginx..."
  sudo apt-get install -y certbot python3-certbot-nginx
else
  echo "Certbot est déjà installé."
fi


# Définition du répertoire cible des certificats
CERTS_DIR="/home/$USER/$PROJECT_DIR/certs"
sudo mkdir -p "$CERTS_DIR"
sudo chown -R $USER:$USER "$CERTS_DIR"

# On fait tourner certbot pour generer les certificats SSL ou les mettre à jour
sudo certbot certonly --nginx -d $CERTBOT_DOMAIN --email $CERTBOT_EMAIL --agree-tos --non-interactive

# Essayer de copier les certificats réels depuis le répertoire archive ; sinon, afficher une
if sudo cp -L /etc/letsencrypt/archive/$CERTBOT_DOMAIN/fullchain1.pem $CERTS_DIR/fullchain.pem && \
   sudo cp -L /etc/letsencrypt/archive/$CERTBOT_DOMAIN/privkey1.pem $CERTS_DIR/privkey.pem; then
   echo "Les certificats ont été copiés avec succès."
else
   echo "Erreur lors de la copie des certificats."
fi

# Génération dynamique de cron-tabs.txt avec des chemins absolus
echo "Génération du fichier cron-tabs.txt avec des chemins absolus..."

cat <<EOL > cron-jobs/cron-tabs.txt
# Tâches planifiées pour les scripts cron avec chemins absolus

# Cron job journalier pour générer les logs Docker
0 0 * * * $BASE_DIR/cron-jobs/cron_daily.sh

# Cron job hebdomadaire pour la sauvegarde et la rotation des logs Docker
0 3 * * 0 $BASE_DIR/cron-jobs/cron_weekly.sh

# Cron job mensuel pour le renouvellement des certificats SSL
0 5 1 * * $BASE_DIR/cron-jobs/cron_monthly.sh
EOL

# Charger cron-tabs.txt dans crontab
crontab cron-jobs/cron-tabs.txt
echo "Les cron jobs ont été ajoutés avec succès."

echo -e "\nInstallation terminée avec succès. Docker, Docker Compose, Certbot sont installés, dist.env est déchiffré dans xenv, les certificats SSL sont générés pour $CERTBOT_DOMAIN, et les cron jobs sont configurés."
