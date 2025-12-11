#!/bin/bash

errors=0

echo "=== Vérification Quête 2 : Aménager ton espace de travail ==="

base="$HOME/mission1"

# Dossiers de base
for d in docs scripts sauvegardes; do
    if [ -d "$base/$d" ]; then
        echo "OK - Dossier $d trouvé dans mission1"
    else
        echo "A corriger - Dossier $d manquant dans mission1"
        errors=$((errors+1))
    fi
done

# Sous-dossiers de docs
for d in procedures notes; do
    if [ -d "$base/docs/$d" ]; then
        echo "OK - Sous-dossier $d trouvé dans mission1/docs"
    else
        echo "A corriger - Sous-dossier $d manquant dans mission1/docs"
        errors=$((errors+1))
    fi
done

if [ "$errors" -eq 0 ]; then
    echo "=== Tout est correct pour la Quête 2. Bien joué ! ==="
    exit 0
else
    echo "=== Il reste $errors point(s) à corriger pour la Quête 2. ==="
    exit 1
fi