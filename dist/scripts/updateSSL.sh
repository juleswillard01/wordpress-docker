#!/bin/bash

set -o allexport
source ../dist.env
set +o allexport

CERTS_DIR="/home/$USER/$PROJECT_DIR/certs"

# Renouvelle tous les certificats SSL de manière silencieuse (sans message sauf en cas d'erreur)
sudo certbot renew

# Essayer de copier les certificats réels depuis le répertoire archive ; sinon, afficher une
if sudo cp -L /etc/letsencrypt/archive/$CERTBOT_DOMAIN/fullchain1.pem $CERTS_DIR/fullchain.pem && \
   sudo cp -L /etc/letsencrypt/archive/$CERTBOT_DOMAIN/privkey1.pem $CERTS_DIR/privkey.pem; then
   echo "Les certificats ont été copiés avec succès."
else
   echo "Erreur lors de la copie des certificats."
fi


# Vérifier si le conteneur nginx_proxy est en cours d'exécution
echo "Vérification du statut du conteneur nginx_proxy..."
NGINX_CONTAINER_STATUS=$(docker-compose -f ../docker-compose-wp.yml ps -q nginx_proxy)

if [ -n "$NGINX_CONTAINER_STATUS" ]; then
    echo "Le conteneur nginx_proxy est en cours d'exécution. Rechargement de Nginx..."
    docker-compose -f ../docker-compose-wp.yml exec nginx_proxy nginx -s reload
else
    echo "Le conteneur nginx_proxy n'est pas démarré"
fi

echo "Mise à jour des certificats SSL terminée avec succès."