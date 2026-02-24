#!/bin/bash
# Usage: ./scripts/vault-backup.sh [commit message]
# Syncs Obsidian vault to repo and pushes

set -e

VAULT="/Volumes/Speedy/Obsidian/Op MindWave"
REPO="$HOME/optiply-workspace/Op-Integrations-Claw"
MSG="${1:-backup: vault snapshot $(date +%Y-%m-%d-%H%M)}"

if [ ! -d "$VAULT" ]; then
  echo "❌ Vault not accessible at $VAULT — is the drive mounted?"
  exit 1
fi

rsync -av --delete \
  --exclude='Archive/' \
  --exclude='.*' \
  --include='*/' \
  --include='*.md' \
  --exclude='*' \
  "$VAULT/" "$REPO/vault-backup/"

cd "$REPO"
git add -A
if git diff --cached --quiet; then
  echo "✅ No changes to backup"
else
  git commit -m "$MSG"
  git push
  echo "✅ Vault backed up and pushed"
fi
