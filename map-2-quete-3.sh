#!/bin/bash

errors=0
base="$HOME/mission1/projets/GLPI"

echo "=== Vérification Quête 3 (Séance 2) : Share de projet GLPI ==="

for d in support reseau doc; do
    if [ -d "$base/$d" ]; then
        echo "OK - Dossier $d présent dans GLPI"
    else
        echo "A corriger - Dossier $d manquant dans GLPI"
        errors=$((errors+1))
    fi
done

# Bonus : au moins un fichier dans doc
if [ -d "$base/doc" ]; then
    if ls "$base/doc"/* >/dev/null 2>&1; then
        echo "OK - Au moins un fichier dans GLPI/doc (bonus)"
    else
        echo "Info - Aucun fichier trouvé dans GLPI/doc (bonus non réalisé)"
    fi
fi

if [ "$errors" == 0 ]; then
    echo "=== Quête 3 (Séance 2) réussie. ==="
    exit 0
else
    echo "=== Il reste $errors point(s) à corriger pour la Quête 3 (Séance 2). ==="
    exit 1
fi