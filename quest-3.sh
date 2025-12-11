#!/bin/bash

errors=0
base="$HOME/mission1"

echo "=== Vérification Quête 3 : Mini-boss Mission1 ==="

# Liste attendue
expected_dirs=(
"docs"
"docs/procedures"
"docs/notes"
"scripts"
"scripts/maintenance"
"scripts/monitoring"
"sauvegardes"
"sauvegardes/journaliere"
"sauvegardes/hebdomadaire"
)

for d in "${expected_dirs[@]}"; do
    if [ -d "$base/$d" ]; then
        echo "OK - $d présent"
    else
        echo "A corriger - $d manquant"
        errors=$((errors+1))
    fi
done

# Option : détecter des dossiers "parasites" directement sous mission1
extra=$(find "$base" -maxdepth 1 -mindepth 1 -type d ! -name "docs" ! -name "scripts" ! -name "sauvegardes" -printf "%f\n")
if [ -n "$extra" ]; then
    echo "A corriger - Dossiers non prévus dans mission1 : $extra"
    errors=$((errors+1))
else
    echo "OK - Aucun dossier parasite dans mission1"
fi

if [ "$errors" -eq 0 ]; then
    echo "=== Mini-boss réussi ! Arborescence conforme. ==="
    exit 0
else
    echo "=== Il reste $errors point(s) à corriger pour la Quête 3. ==="
    exit 1
fi