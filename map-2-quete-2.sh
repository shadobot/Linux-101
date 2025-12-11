#!/bin/bash

errors=0
base="$HOME/mission1/docs"

echo "=== Vérification Quête 2 (Séance 2) : Déménagement de dossiers ==="

if [ -d "$base/clients_archives" ]; then
    echo "OK - Dossier clients_archives présent"
else
    echo "A corriger - Dossier clients_archives manquant"
    errors=$((errors+1))
fi

if [ -d "$base/clients_archives/clients" ]; then
    echo "OK - Dossier clients dans clients_archives"
else
    echo "A corriger - Dossier clients manquant dans clients_archives"
    errors=$((errors+1))
fi

if [ -d "$base/clients_archives/clients/ClientA" ]; then
    echo "OK - ClientA présent"
else
    echo "A corriger - ClientA manquant"
    errors=$((errors+1))
fi

if [ -d "$base/clients_archives/clients/Client_B_2025" ]; then
    echo "OK - Client_B_2025 présent"
else
    echo "A corriger - Client_B_2025 manquant (renommage ?)"
    errors=$((errors+1))
fi

if [ "$errors" -eq 0 ]; then
    echo "=== Quête 2 (Séance 2) réussie. ==="
    exit 0
else
    echo "=== Il reste $errors point(s) à corriger pour la Quête 2 (Séance 2). ==="
    exit 1
fi