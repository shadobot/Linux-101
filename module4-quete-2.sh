#!/bin/bash

errors=0
base="$HOME/mission1/projets/projet_glpi"

echo "=== Vérification Quête 2 (Séance 4) : projet_glpi ==="

if [ ! -d "$base" ]; then
    echo "A corriger - Dossier projet_glpi manquant"
    exit 1
fi

# Vérifier les fichiers
for f in install.txt config.txt todo.txt; do
    if [ -f "$base/$f" ]; then
        echo "OK - Fichier $f présent"
    else
        echo "A corriger - Fichier $f manquant"
        errors=$((errors+1))
    fi
done

# Vérifier les droits (en octal : 750 attendu)
dir_perms=$(stat -c "%a" "$base")
if [ "$dir_perms" = "750" ]; then
    echo "OK - Droits du dossier projet_glpi = 750"
else
    echo "A corriger - Droits du dossier projet_glpi = $dir_perms"
    errors=$((errors+1))
fi

for f in install.txt config.txt todo.txt; do
    perms=$(stat -c "%a" "$base/$f")
    if [ "$perms" = "750" ]; then
        echo "OK - Droits de $f = 750"
    else
        echo "A corriger - Droits de $f = $perms"
        errors=$((errors+1))
    fi
done

if [ "$errors" -eq 0 ]; then
    echo "=== Quête 2 (Séance 4) réussie. ==="
    exit 0
else
    echo "=== Il reste $errors point(s) à corriger pour la Quête 2 (Séance 4). ==="
    exit 1
fi