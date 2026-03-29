#!/usr/bin/env node
const { execSync } = require("child_process");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const ROOT = __dirname;
const TEAMS_DIR = path.join(ROOT, "teams");
const DIST_DIR = path.join(ROOT, "dist");
const CONFIG = path.join(ROOT, "teams.json");
const TEMPLATE = path.join(ROOT, "custom_template.html");
const STATICRYPT = path.join(ROOT, "node_modules", ".bin", "staticrypt");

// Clean dist
fs.rmSync(DIST_DIR, { recursive: true, force: true });
fs.mkdirSync(DIST_DIR, { recursive: true });

// Copy landing page and 404
for (const file of ["index.html", "404.html"]) {
  const src = path.join(ROOT, file);
  if (fs.existsSync(src)) fs.copyFileSync(src, path.join(DIST_DIR, file));
}

// Load config
if (!fs.existsSync(CONFIG)) {
  console.error("ERROR: teams.json not found. Copy teams.json.example to teams.json and configure it.");
  process.exit(1);
}
const teams = JSON.parse(fs.readFileSync(CONFIG, "utf8"));

for (const [team, config] of Object.entries(teams)) {
  const teamSrc = path.join(TEAMS_DIR, team);

  // Password: env var override or config file
  const envKey = `TEAM_${team.replace(/-/g, "_").toUpperCase()}_PASSWORD`;
  const password = process.env[envKey] || config.password;
  const title = config.title || team;

  if (!fs.existsSync(teamSrc)) {
    console.log(`WARNING: teams/${team}/ not found, skipping`);
    continue;
  }

  // Unique salt per team (deterministic)
  const teamSalt = crypto.createHash("sha256").update(`report-salt-${team}`).digest("hex").slice(0, 32);

  // Password strength warnings
  if (password.length < 12) {
    console.log(`WARNING: Password for '${team}' is shorter than 12 characters. Consider using a stronger password.`);
  }
  if (/^[a-zA-Z0-9]+$/.test(password)) {
    console.log(`WARNING: Password for '${team}' uses only alphanumeric characters. Consider adding symbols (!@#$%^&*).`);
  }

  const teamDist = path.join(DIST_DIR, team);
  fs.mkdirSync(teamDist, { recursive: true });

  // Collect HTML files
  const htmlFiles = fs.readdirSync(teamSrc).filter((f) => f.endsWith(".html"));

  // Build report links for team index (exclude index.html)
  const reportLinks = [];
  for (const file of htmlFiles) {
    if (file === "index.html") continue;
    const content = fs.readFileSync(path.join(teamSrc, file), "utf8");
    const titleMatch = content.match(/<title>(.*?)<\/title>/);
    const pageTitle = titleMatch ? titleMatch[1] : file;
    reportLinks.push(`<a class="rpt" href="${file}"><span class="rpt-name">${pageTitle}</span><span class="arrow">&rarr;</span></a>`);
  }

  // Add index.html as "Full Report"
  if (fs.existsSync(path.join(teamSrc, "index.html"))) {
    const content = fs.readFileSync(path.join(teamSrc, "index.html"), "utf8");
    const titleMatch = content.match(/<title>(.*?)<\/title>/);
    const pageTitle = titleMatch ? titleMatch[1] : "Full Report";
    reportLinks.push(`<a class="rpt" href="full-report.html"><span class="rpt-name">${pageTitle}</span><span class="arrow">&rarr;</span></a>`);
    fs.copyFileSync(path.join(teamSrc, "index.html"), path.join(teamSrc, "_full-report.html"));
  }

  // Generate team index page
  const indexHtml = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${title} — Reports</title>
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
  <h1>${title}</h1>
  <p class="sub">Select a report to view.</p>
  <div class="reports">${reportLinks.join("")}</div>
</div>
</body>
</html>`;
  fs.writeFileSync(path.join(teamSrc, "_index.html"), indexHtml);

  // Encrypt all HTML files
  const filesToEncrypt = fs.readdirSync(teamSrc).filter((f) => f.endsWith(".html") && f !== "index.html");

  for (const file of filesToEncrypt) {
    let outName = file;
    if (file === "_index.html") outName = "index.html";
    if (file === "_full-report.html") outName = "full-report.html";

    console.log(`Encrypting ${team}/${outName} ...`);

    const tmpDir = path.join(ROOT, ".staticrypt-tmp");
    fs.rmSync(tmpDir, { recursive: true, force: true });

    const cmd = [
      `"${STATICRYPT}"`,
      `"${path.join(teamSrc, file)}"`,
      `-p "${password}"`,
      `-s "${teamSalt}"`,
      `-d "${tmpDir}"`,
      `--short`,
      `-t "${TEMPLATE}"`,
      `--template-title "Protected Report"`,
      `--template-color-primary "#f0a030"`,
      `--template-color-secondary "#0a0b0e"`,
      `--template-instructions "Enter your team credentials to access this report."`,
      `--remember 30`,
    ].join(" ");

    execSync(cmd, { stdio: "pipe" });
    fs.renameSync(path.join(tmpDir, file), path.join(teamDist, outName));
    fs.rmSync(tmpDir, { recursive: true, force: true });
  }

  // Clean up temp files
  for (const tmp of ["_index.html", "_full-report.html"]) {
    const p = path.join(teamSrc, tmp);
    if (fs.existsSync(p)) fs.unlinkSync(p);
  }

  // Copy non-HTML assets
  for (const file of fs.readdirSync(teamSrc)) {
    if (!file.endsWith(".html")) {
      const src = path.join(teamSrc, file);
      if (fs.statSync(src).isFile()) {
        fs.copyFileSync(src, path.join(teamDist, file));
      }
    }
  }
}

console.log("\nBuild complete! Output in dist/");
console.log("Teams encrypted:");
for (const team of Object.keys(teams)) {
  console.log(`  - ${team}/`);
}
