#!/bin/bash

# Nom du répertoire pour l'environnement virtuel
VENV_DIR="venv"

# Vérifier si le répertoire de l'environnement virtuel existe déjà
if [ -d "$VENV_DIR" ]; then
    echo "L'environnement virtuel existe déjà. Activation..."
else
    # Créer un environnement virtuel
    echo "Création de l'environnement virtuel..."
    python3 -m venv $VENV_DIR
fi

# Activer l'environnement virtuel
source $VENV_DIR/bin/activate

# Installer les dépendances
echo "Installation des dépendances..."
pip install -r requirements.txt

echo "L'environnement est prêt. Pour l'activer, exécutez :"
echo "source $VENV_DIR/bin/activate"
