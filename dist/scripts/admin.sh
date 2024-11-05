#!/bin/bash

# Fonction pour gérer les services Docker
manage_docker() {
  case $1 in
    start)
      # Démarre tous les services en mode détaché
      docker-compose -f ../docker-compose-wp.yml up -d
      ;;
    stop)
      # Arrête tous les services
      docker-compose -f ../docker-compose-wp.yml down
      ;;
    restart)
      # Redémarre tous les services (arrêt puis démarrage)
      docker-compose -f ../docker-compose-wp.yml down && docker-compose -f ../docker-compose-wp.yml up -d
      ;;
    *)
      echo "Usage: $0 docker {start|stop|restart}"
      ;;
  esac
}

# Fonction pour gérer les cron jobs
manage_cron() {
  case $1 in
    enable)
      # Ajoute les cron jobs dans le crontab
      (crontab -l 2>/dev/null; echo "0 0 * * * /bin/bash $(pwd)/cron-jobs/cron_daily.sh >/dev/null 2>&1") | crontab -
      (crontab -l 2>/dev/null; echo "0 0 * * 0 /bin/bash $(pwd)/cron-jobs/cron_weekly.sh >/dev/null 2>&1") | crontab -
      (crontab -l 2>/dev/null; echo "0 0 1 * * /bin/bash $(pwd)/cron-jobs/cron_monthly.sh >/dev/null 2>&1") | crontab -
      echo "Cron jobs activés."
      ;;
    disable)
      # Supprime toutes les tâches cron liées aux scripts
      crontab -l | grep -v "$(pwd)/cron-jobs" | crontab -
      echo "Cron jobs désactivés."
      ;;
    status)
      # Affiche les cron jobs en cours
      echo "Tâches cron actuelles :"
      crontab -l | grep "$(pwd)/cron-jobs"
      ;;
    *)
      echo "Usage: $0 cron {enable|disable|status}"
      ;;
  esac
}

# Choix de l'action (docker ou cron) selon l'argument
case $1 in
  docker)
    manage_docker $2
    ;;
  cron)
    manage_cron $2
    ;;
  *)
    echo "Usage: $0 {docker|cron} {start|stop|restart|enable|disable|status}"
    ;;
esac
