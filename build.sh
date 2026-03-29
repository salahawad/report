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

  # Generate a team index page listing all reports (excluding index.html itself)
  report_links=""
  for html_file in "$team_src"/*.html; do
    [ -f "$html_file" ] || continue
    filename=$(basename "$html_file")
    [ "$filename" = "index.html" ] && continue
    # Extract <title> from the file for display name
    page_title=$(grep -oP '(?<=<title>).*?(?=</title>)' "$html_file" | head -1)
    [ -z "$page_title" ] && page_title="$filename"
    report_links="$report_links<a class=\"rpt\" href=\"$filename\"><span class=\"rpt-name\">$page_title</span><span class=\"arrow\">&rarr;</span></a>"
  done

  # Also add the original index.html as "Full Report" if it exists
  if [ -f "$team_src/index.html" ]; then
    page_title=$(grep -oP '(?<=<title>).*?(?=</title>)' "$team_src/index.html" | head -1)
    [ -z "$page_title" ] && page_title="Full Report"
    report_links="$report_links<a class=\"rpt\" href=\"full-report.html\"><span class=\"rpt-name\">$page_title</span><span class=\"arrow\">&rarr;</span></a>"
    # Rename index.html to full-report.html so the generated index takes its place
    cp "$team_src/index.html" "$team_src/_full-report.html"
  fi

  # Write the team index page
  cat > "$team_src/_index.html" <<INDEXEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>$title — Reports</title>
<link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=DM+Mono:wght@300;400;500&display=swap" rel="stylesheet">
<style>
:root{--bg:#0a0b0e;--bg2:#0f1115;--bg3:#151820;--border:#1e2229;--text:#c8d0de;--dim:#5a6578;--white:#eef1f7;--amber:#f0a030}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:'DM Mono',monospace;font-size:13px;line-height:1.6;min-height:100vh;display:flex;align-items:center;justify-content:center}
body::before{content:'';position:fixed;inset:0;background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.04'/%3E%3C/svg%3E");pointer-events:none;z-index:9999;opacity:.5}
.wrap{max-width:600px;width:100%;padding:40px 32px}
.lbl{font-size:11px;letter-spacing:.25em;text-transform:uppercase;color:var(--amber);margin-bottom:14px;display:flex;align-items:center;gap:10px}
.lbl::before{content:'';display:inline-block;width:24px;height:1px;background:var(--amber)}
h1{font-family:'Bebas Neue',sans-serif;font-size:52px;letter-spacing:.04em;color:var(--white);line-height:.9;margin-bottom:8px}
h1 span{color:var(--amber)}
.sub{color:var(--dim);font-size:12px;margin-bottom:40px}
.back{display:inline-block;color:var(--dim);font-size:11px;text-decoration:none;margin-bottom:24px;letter-spacing:.1em;text-transform:uppercase;transition:color .2s}
.back:hover{color:var(--amber)}
.reports{display:flex;flex-direction:column;gap:8px}
a.rpt{display:flex;align-items:center;justify-content:space-between;background:var(--bg2);border:1px solid var(--border);border-radius:4px;padding:18px 22px;text-decoration:none;color:var(--text);transition:border-color .2s,background .2s}
a.rpt:hover{border-color:var(--amber);background:var(--bg3)}
.rpt-name{font-size:14px;font-weight:500;color:var(--white)}
.arrow{color:var(--dim);font-size:18px;transition:color .2s,transform .2s}
a.rpt:hover .arrow{color:var(--amber);transform:translateX(4px)}
</style>
</head>
<body>
<div class="wrap">
  <a class="back" href="../">&larr; All Teams</a>
  <div class="lbl">Reports</div>
  <h1>$title</h1>
  <p class="sub">Select a report to view.</p>
  <div class="reports">$report_links</div>
</div>
</body>
</html>
INDEXEOF

  # Encrypt every HTML file in the team folder
  for html_file in "$team_src"/*.html; do
    [ -f "$html_file" ] || continue
    filename=$(basename "$html_file")

    # Skip the original index.html (we renamed it to _full-report.html)
    [ "$filename" = "index.html" ] && continue

    # Determine output filename
    out_filename="$filename"
    [ "$filename" = "_index.html" ] && out_filename="index.html"
    [ "$filename" = "_full-report.html" ] && out_filename="full-report.html"

    echo "Encrypting $team/$out_filename ..."
    "$STATICRYPT" "$html_file" \
      -p "$password" \
      -d /tmp/staticrypt-out \
      --short \
      -t "$SCRIPT_DIR/custom_template.html" \
      --template-title "Protected Report" \
      --template-color-primary "#f0a030" \
      --template-color-secondary "#0a0b0e" \
      --template-instructions "Enter your team credentials to access this report." \
      --remember 30
    mv "/tmp/staticrypt-out/$filename" "$DIST_DIR/$team/$out_filename"
    rm -rf /tmp/staticrypt-out
  done

  # Clean up generated temp files
  rm -f "$team_src/_index.html" "$team_src/_full-report.html"

  # Copy non-HTML assets (images, css, js) if any
  find "$team_src" -type f ! -name '*.html' -exec cp --parents -t "$DIST_DIR" {} + 2>/dev/null || true
done

echo ""
echo "Build complete! Output in dist/"
echo "Teams encrypted:"
for team in $(jq -r 'keys[]' "$CONFIG"); do
  echo "  - $team/"
done
