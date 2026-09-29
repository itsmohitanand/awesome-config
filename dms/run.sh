#!/usr/bin/env bash
set -euo pipefail
DMS_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/awesome-config/dms-1.6.2"
export PATH="$DMS_ROOT/bin:$PATH"
exec "$DMS_ROOT/bin/dms" "$@"
