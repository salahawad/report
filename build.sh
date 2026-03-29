#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEAMS_DIR="$SCRIPT_DIR/teams"
DIST_DIR="$SCRIPT_DIR/dist"
CONFIG="$SCRIPT_DIR/teams.json"
STATICRYPT="$SCRIPT_DIR/node_modules/.bin/staticrypt"

# Clean dist
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Copy landing page
if [ -f "$SCRIPT_DIR/index.html" ]; then
  cp "$SCRIPT_DIR/index.html" "$DIST_DIR/index.html"
fi

# Read each team from config and encrypt their pages
for team in $(jq -r 'keys[]' "$CONFIG"); do
  # Use env var TEAM_<UPPER_SLUG>_PASSWORD if set, otherwise fall back to config file
  env_key="TEAM_$(echo "$team" | tr '[:lower:]-' '[:upper:]_')_PASSWORD"
  password="${!env_key:-$(jq -r --arg t "$team" '.[$t].password' "$CONFIG")}"
  title=$(jq -r --arg t "$team" '.[$t].title // $t' "$CONFIG")
  team_src="$TEAMS_DIR/$team"

  if [ ! -d "$team_src" ]; then
    echo "WARNING: teams/$team/ not found, skipping"
    continue
  fi

  mkdir -p "$DIST_DIR/$team"

  # Encrypt every HTML file in the team folder
  for html_file in "$team_src"/*.html; do
    [ -f "$html_file" ] || continue
    filename=$(basename "$html_file")

    echo "Encrypting $team/$filename ..."
    "$STATICRYPT" "$html_file" \
      -p "$password" \
      -d "$DIST_DIR/$team" \
      --short \
      --template-title "$title" \
      --template-color-primary "#f0a030" \
      --template-color-secondary "#0a0b0e" \
      --template-instructions "Enter your team credentials to access this report." \
      --remember 30
  done

  # Copy non-HTML assets (images, css, js) if any
  find "$team_src" -type f ! -name '*.html' -exec cp --parents -t "$DIST_DIR" {} + 2>/dev/null || true
done

echo ""
echo "Build complete! Output in dist/"
echo "Teams encrypted:"
for team in $(jq -r 'keys[]' "$CONFIG"); do
  echo "  - $team/"
done
