# Team Reports

Password-protected HTML reports published via GitHub Pages. Each team gets their own folder with AES-256 encrypted pages — without the correct password, the content is unreadable even though the repo is public.

Built with [StatiCrypt](https://github.com/robinmoisson/staticrypt).

## Live

**https://salahawad.github.io/report/**

## Structure

```
dist/                       ← encrypted output (committed, deployed)
  index.html                ← public landing page (team selector)
  <team-slug>/
    index.html              ← auto-generated report listing (encrypted)
    full-report.html        ← main report (encrypted)
    summary.html            ← additional pages (encrypted)
teams/                      ← raw reports (local only, gitignored)
  <team-slug>/*.html
teams.json                  ← team config + passwords (local only, gitignored)
build.sh                    ← encrypts team pages → dist/
custom_template.html        ← password prompt template
```

## Quick start

```bash
git clone https://github.com/salahawad/report.git
cd report
npm install
```

## Getting started with the template

A **test-team** is included as a reference. It contains a template page with:

- All available UI components (cards, tables, badges)
- CSS theme variables and color reference
- Step-by-step instructions for creating your own report
- Example file structure

To view it locally:

```bash
bash build.sh
npx serve dist
# Open http://localhost:3000/test-team/ → password: test123
```

Use the template as a starting point — copy it to your team folder and replace the placeholder content.

## Adding a new team

1. Create your team folder and add HTML report(s):
   ```
   teams/your-team/
     index.html          ← main report
     summary.html        ← optional additional pages
   ```

2. Add your team to `teams.json` (local only, never committed):
   ```json
   {
     "your-team": {
       "password": "your-password",
       "title": "Your Team Name"
     }
   }
   ```

3. Add your team to the links array in `index.html`:
   ```js
   { slug: 'your-team', name: 'Your Team Name' },
   ```

4. Build, commit, push:
   ```bash
   bash build.sh
   git add dist/ index.html
   git commit -m "Add your-team reports"
   git push
   ```

The build script will automatically:
- Generate an index page listing all reports in your team folder
- Rename your `index.html` to `full-report.html` (so the generated index takes its place)
- Encrypt every HTML file with your team's password

## Multiple pages per team

You can add as many HTML files as you want to a team folder. The build script picks up all `*.html` files and encrypts each one. A team index page is auto-generated listing all reports.

```
teams/your-team/
  index.html            → becomes full-report.html
  summary.html          → stays summary.html
  sprint-review.html    → stays sprint-review.html
```

All pages share the same team password.

## Security

- **Raw reports** (`teams/`) and **passwords** (`teams.json`) are gitignored — they never leave your machine
- Only **encrypted HTML** is committed and deployed
- The encrypted pages contain zero readable content — just an AES-256 encrypted payload
- Even page titles are hidden (shows "Protected Report")
- The "Remember me" checkbox saves a salted hash in localStorage for 30 days

## How encryption works

StatiCrypt encrypts the entire HTML content with AES-256 using the team's password. The deployed page contains only a password prompt and the encrypted payload. Decryption happens entirely client-side in the browser — no server, no backend, no cookies.
