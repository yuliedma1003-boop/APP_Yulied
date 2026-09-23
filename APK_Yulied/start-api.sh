#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
export PATH="${HOME}/.local/share/fnm/node-versions/v22.23.2/installation/bin:${PATH}"
cd "$ROOT/api"
if [ ! -d node_modules ]; then
  npm install
fi
echo "Iniciando TitanFit API..."
exec npm start
