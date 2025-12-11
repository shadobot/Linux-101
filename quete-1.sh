#!/bin/bash

errors=0

echo "=== Vérification Quête 1 : Trouver ton bureau ==="

# Vérifier mission1
if [ -d "$HOME/mission1" ]; then
    echo "OK - Dossier mission1 trouvé dans \$HOME"
else
    echo "A corriger - Dossier mission1 manquant dans \$HOME"
    errors=$((errors+1))
fi

# Vérifier docs
if [ -d "$HOME/mission1/docs" ]; then
    echo "OK - Dossier docs trouvé dans mission1"
else
    echo "A corriger - Dossier docs manquant dans mission1"
    errors=$((errors+1))
fi

# Vérifier logs
if [ -d "$HOME/mission1/logs" ]; then
    echo "OK - Dossier logs trouvé dans mission1"
else
    echo "A corriger - Dossier logs manquant dans mission1"
    errors=$((errors+1))
fi

# Vérifier propriétaire
owner_m1=$(stat -c "%U" "$HOME/mission1" 2>/dev/null)
if [ "$owner_m1" = "$USER" ]; then
    echo "OK - mission1 appartient à l'utilisateur $USER"
else
    echo "A corriger - mission1 n'appartient pas à l'utilisateur $USER"
    errors=$((errors+1))
fi

if [ "$errors" -eq 0 ]; then
    echo "=== Tout est correct pour la Quête 1. Bravo ! ==="
    exit 0
else
    echo "=== Il reste $errors point(s) à corriger pour la Quête 1. ==="
    exit 1
fi