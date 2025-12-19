#!/bin/bash

errors=0
file="$HOME/mission1/logs_tests/events.log"

echo "=== Vérification Quête 2 (Séance 3) : events.log ==="

if [ -f "$file" ]; then
    echo "OK - Fichier events.log présent"
else
    echo "A corriger - Fichier events.log manquant"
    errors=$((errors+1))
fi

if [ -s "$file" ]; then
    echo "OK - events.log n'est pas vide"
else
    echo "A corriger - events.log semble vide"
    errors=$((errors+1))
fi

lines=$(wc -l < "$file" 2>/dev/null)
if [ -n "$lines" ] && [ "$lines" -ge 10 ]; then
    echo "OK - events.log contient au moins 10 lignes"
else
    echo "A corriger - events.log contient moins de 10 lignes"
    errors=$((errors+1))
fi

if [ "$errors" -eq 0 ]; then
    echo "=== Quête 2 (Séance 3) réussie. ==="
    exit 0
else
    echo "=== Il reste $errors point(s) à corriger pour la Quête 2 (Séance 3). ==="
    exit 1
fi