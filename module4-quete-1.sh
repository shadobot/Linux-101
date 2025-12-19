#!/bin/bash

errors=0
base="$HOME/mission1/projets/droits_test"

echo "=== Vérification Quête 1 (Séance 4) : droits_test ==="

if [ -d "$base" ]; then
    echo "OK - Dossier droits_test présent"
else
    echo "A corriger - Dossier droits_test manquant"
    errors=$((errors+1))
fi

for f in f1.txt f2.txt; do
    if [ -f "$base/$f" ]; then
        echo "OK - Fichier $f présent"
    else
        echo "A corriger - Fichier $f manquant"
        errors=$((errors+1))
    fi
done

if [ "$errors" -eq 0 ]; then
    echo "=== Quête 1 (Séance 4) réussie. ==="
    exit 0
else
    echo "=== Il reste $errors point(s) à corriger pour la Quête 1 (Séance 4). ==="
    exit 1
fi