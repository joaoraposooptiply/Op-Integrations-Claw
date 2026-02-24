#!/bin/bash
# Usage: ./scripts/ingest-docs.sh <integration-name> <source-file>
# Ingests documentation into the RAG knowledge base

set -e

INTEGRATION="$1"
SOURCE="$2"

if [ -z "$INTEGRATION" ] || [ -z "$SOURCE" ]; then
  echo "Usage: $0 <integration-name> <source-file>"
  exit 1
fi

echo "📥 Ingesting docs for: $INTEGRATION"
echo "   Source: $SOURCE"

cd ~/optiply
python3.11 ingest.py --source "$SOURCE" --integration "$INTEGRATION"

echo "✅ Ingested. Verify:"
echo "   curl -s -X POST http://127.0.0.1:8000/retrieve -H 'Content-Type: application/json' -d '{\"query\":\"$INTEGRATION\",\"tenant_id\":\"00000000-0000-0000-0000-000000000001\"}' | python3 -m json.tool | head -20"
