#!/bin/bash

# Supprime les fichiers de log dans ../../logs plus anciens que 7 jours
find ../../logs/*.log -type f -mtime +7 -delete

echo "Rotation des logs terminées."
