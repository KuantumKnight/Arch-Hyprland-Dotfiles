#!/usr/bin/env bash
set -euo pipefail
exec /usr/bin/python "${1:?Selector directory}/cache.py" "$1/config.json"
