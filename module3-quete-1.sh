#!/bin/bash

errors=0
base="$HOME/mission1/logs_tests"

echo "=== Vérification Quête 1 (Séance 3) : logs_tests ==="

if [ -d "$base" ]; then
    echo "OK - Dossier logs_tests présent"
else
    echo "A corriger - Dossier logs_tests manquant"
    errors=$((errors+1))
fi

for f in app.log image_fake.bin config.txt; do
    if [ -f "$base/$f" ]; then
        echo "OK - Fichier $f présent"
    else
        echo "A corriger - Fichier $f manquant"
        errors=$((errors+1))
    fi
done

if [ "$errors" -eq 0 ]; then
    echo "=== Quête 1 (Séance 3) réussie. ==="
    exit 0
else
    echo "=== Il reste $errors point(s) à corriger pour la Quête 1 (Séance 3). ==="
    exit 1
fi