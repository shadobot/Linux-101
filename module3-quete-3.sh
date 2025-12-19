#!/bin/bash

errors=0
file="$HOME/mission1/logs_tests/app_web.log"

echo "=== Vérification Quête 3 (Séance 3) : app_web.log ==="

if [ -f "$file" ]; then
    echo "OK - Fichier app_web.log présent"
else
    echo "A corriger - Fichier app_web.log manquant"
    errors=$((errors+1))
fi

lines=$(wc -l < "$file" 2>/dev/null)
if [ -n "$lines" ] && [ "$lines" -ge 20 ]; then
    echo "OK - app_web.log contient au moins 20 lignes"
else
    echo "A corriger - app_web.log contient moins de 20 lignes"
    errors=$((errors+1))
fi

if grep -q "ERROR" "$file" 2>/dev/null; then
    echo "OK - Au moins une ligne contient ERROR"
else
    echo "A corriger - Aucune ligne ERROR trouvée dans app_web.log"
    errors=$((errors+1))
fi

if [ "$errors" -eq 0 ]; then
    echo "=== Quête 3 (Séance 3) réussie. Mini-boss validé ! ==="
    exit 0
else
    echo "=== Il reste $errors point(s) à corriger pour la Quête 3 (Séance 3). ==="
    exit 1
fi