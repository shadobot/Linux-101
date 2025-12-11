#!/bin/bash

errors=0
base="$HOME/mission1/docs/clients"

echo "=== Vérification Quête 1 (Séance 2) : Dossier client ==="

for c in ClientA ClientB; do
    if [ -d "$base/$c" ]; then
        echo "OK - Dossier $c présent dans clients"
    else
        echo "A corriger - Dossier $c manquant dans clients"
        errors=$((errors+1))
    fi
done

if [ "$errors" -eq 0 ]; then
    echo "=== Quête 1 (Séance 2) réussie. ==="
    exit 0
else
    echo "=== Il reste $errors point(s) à corriger pour la Quête 1 (Séance 2). ==="
    exit 1
fi