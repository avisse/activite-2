#!/bin/bash

echo "=== Étape 1 : Installer les dépendances ==="
npm ci || exit 1

echo "=== Étape 2 : Build de l'application Angular ==="
npm run build || exit 1

echo "=== Étape 3 : (Facultatif) Tests ==="
echo "Tests non configurés pour le moment"

echo "✅ Build terminé avec succès."
