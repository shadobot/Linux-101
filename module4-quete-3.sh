#!/bin/bash

errors=0
base="$HOME/mission1/RH"

echo "=== Vérification Quête 3 (Séance 4) : RH ==="

if [ ! -d "$base" ]; then
    echo "A corriger - Dossier RH manquant"
    exit 1
fi

for f in salaires.txt contrats.txt; do
    if [ -f "$base/$f" ]; then
        echo "OK - Fichier $f présent"
    else
        echo "A corriger - Fichier $f manquant"
        errors=$((errors+1))
    fi
done

# Droits dossier
dir_perms=$(stat -c "%a" "$base")
if [ "$dir_perms" = "700" ]; then
    echo "OK - Droits du dossier RH = 700"
else
    echo "A corriger - Droits du dossier RH = $dir_perms (700 attendu)"
    errors=$((errors+1))
fi

# Fichiers : au moins lecture/écriture pour user, rien pour les autres
for f in salaires.txt contrats.txt; do
    perms=$(stat -c "%a" "$base/$f")
    case "$perms" in
        600|700)
            echo "OK - Droits de $f = $perms (accepté)"
            ;;
        *)
            echo "A corriger - Droits de $f = $perms (600 ou 700 attendus)"
            errors=$((errors+1))
            ;;
    esac
done

if [ "$errors" -eq 0 ]; then
    echo "=== Mini-boss (Séance 4) réussi ! ==="
    exit 0
else
    echo "=== Il reste $errors point(s) à corriger pour la Quête 3 (Séance 4). ==="
    exit 1
fi