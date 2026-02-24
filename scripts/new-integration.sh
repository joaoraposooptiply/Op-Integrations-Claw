#!/bin/bash
# Usage: ./scripts/new-integration.sh "Shopify" "E-commerce" "OAuth2" "https://shopify.dev/docs/api"
# Creates: vault page, tap scaffold, target scaffold, ETL scaffold, docs scaffold

set -e

NAME="$1"
TYPE="${2:-E-commerce}"   # E-commerce / ERP / WMS / Marketplace / Data
AUTH="${3:-API Key}"       # OAuth2 / API Key / Basic / Other
API_DOCS="${4:-}"

if [ -z "$NAME" ]; then
  echo "Usage: $0 <IntegrationName> [Type] [AuthMethod] [APIDocsURL]"
  exit 1
fi

SLUG=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
VAULT="/Volumes/Speedy/Obsidian/Op MindWave"
REPO="$HOME/optiply-workspace/Op-Integrations-Claw"
DATE=$(date +%Y-%m-%d)

echo "🔌 Creating integration: $NAME ($SLUG)"

# 1. Vault — Integration project page
mkdir -p "$VAULT/Projects/Integrations"
cat > "$VAULT/Projects/Integrations/$NAME.md" << EOF
---
tags: [integration, project]
integration: $NAME
type: $TYPE
auth: $AUTH
status: 🔵 Research
updated: $DATE
---

# $NAME Integration

## Overview
| Field | Value |
|-------|-------|
| Platform | $NAME |
| Type | $TYPE |
| Auth | $AUTH |
| API Docs | $API_DOCS |
| Base URL | |
| Rate Limits | |
| Pagination | |

## API Endpoints Used
| Endpoint | Method | Purpose | Replication |
|----------|--------|---------|-------------|
| | | | INCREMENTAL / FULL_TABLE |

## Tap Status
- [ ] Tap code complete
- [ ] \`pip install -e .\` succeeds
- [ ] \`--discover\` produces valid catalog
- [ ] Incremental sync works
- [ ] Error handling (401, 429, 5xx)
- [ ] Committed to repo

## Target Status
- [ ] Target code complete
- [ ] Import test passes
- [ ] Write operations verified
- [ ] Committed to repo

## ETL Status
- [ ] ETL notebook complete
- [ ] Entity mappings verified
- [ ] Snapshot diff logic working
- [ ] Summary cell present

## Docs Status
- [ ] Setup guide written
- [ ] Troubleshooting guide written
- [ ] KB chunks ingested

## Known Issues
- None yet

## Notes
EOF

# 2. Repo — Tap scaffold
TAP_DIR="$REPO/taps/tap-$SLUG/tap_${SLUG//-/_}"
mkdir -p "$TAP_DIR"
touch "$TAP_DIR/__init__.py"
cat > "$TAP_DIR/tap.py" << EOF
"""$NAME tap."""
# TODO: Implement tap
EOF
cat > "$TAP_DIR/streams.py" << EOF
"""$NAME streams."""
# TODO: Implement streams
EOF

# 3. Repo — Target scaffold
TARGET_DIR="$REPO/targets/target-$SLUG/target_${SLUG//-/_}"
mkdir -p "$TARGET_DIR"
touch "$TARGET_DIR/__init__.py"
cat > "$TARGET_DIR/target.py" << EOF
"""$NAME target."""
# TODO: Implement target
EOF

# 4. Repo — ETL scaffold
mkdir -p "$REPO/etl/$SLUG"
cat > "$REPO/etl/$SLUG/etl_$SLUG.py" << EOF
"""$NAME ETL notebook."""
# TODO: Implement ETL transform
EOF

# 5. Repo — Docs scaffold
mkdir -p "$REPO/docs/$SLUG"
cat > "$REPO/docs/$SLUG/setup.md" << EOF
# $NAME — Setup Guide

## Prerequisites
-

## Configuration
-

## First Sync
-
EOF
cat > "$REPO/docs/$SLUG/troubleshooting.md" << EOF
# $NAME — Troubleshooting

## Common Issues

### Issue:
**Symptoms:**
**Cause:**
**Fix:**
EOF

echo "✅ Created:"
echo "   Vault:  $VAULT/Projects/Integrations/$NAME.md"
echo "   Tap:    $REPO/taps/tap-$SLUG/"
echo "   Target: $REPO/targets/target-$SLUG/"
echo "   ETL:    $REPO/etl/$SLUG/"
echo "   Docs:   $REPO/docs/$SLUG/"
echo ""
echo "Next: research API → fill vault page → build tap → build target → build ETL → ingest docs"
