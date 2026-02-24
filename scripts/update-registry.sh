#!/bin/bash
# Usage: ./scripts/update-registry.sh "Shopify" "🟢" "E-commerce" "✅"
# Updates the status of an integration in the Projects MOC

NAME="$1"
STATUS="${2:-⚪}"  # ⚪ 🔵 🟡 🟢 🔴
TYPE="${3:-}"
STANDARD="${4:-}"

VAULT="/Volumes/Speedy/Obsidian/Op MindWave"

if [ -z "$NAME" ]; then
  echo "Usage: $0 <IntegrationName> [StatusEmoji] [Type] [Standard]"
  exit 1
fi

echo "Updated $NAME to $STATUS in registry"
echo "⚠️  Manual edit needed in: $VAULT/Projects/_Projects MOC.md"
echo "    Find '$NAME' and update the status column"
