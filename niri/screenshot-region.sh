#!/usr/bin/env bash
# Interactive region capture for niri, with Swappy for annotation and saving.
set -euo pipefail

region="$(slurp -d)" || exit 0 # Escape cancels without launching the editor.
[[ -n "$region" ]] || exit 0

grim -g "$region" - | swappy -f -
