# Team Reports

Password-protected HTML reports published via GitHub Pages. Each team gets their own folder with AES-256 encrypted pages — without the correct password, the content is unreadable even though the repo is public.

AI agents are generating rich HTML reports every day — dashboards, analyses, sprint reviews, audits. This repo gives you a simple way to share them securely with your team. No backend, no accounts, no database. Just a password and a link.

Built with [StatiCrypt](https://github.com/robinmoisson/staticrypt).

---

## For Report Viewers

1. Go to the reports site (provided by your admin)
2. Select your team from the list
3. Enter the password you were given and click **Decrypt**
4. "Remember me" is checked by default — your password is saved for 30 days so you won't be prompted again on any page within your team
5. From the team index you can navigate between all available reports

**Tips:**
- Passwords are case-sensitive — double-check for typos if you see "Bad password"
- To reset a saved password, clear your browser's localStorage for this site
- Everything is decrypted locally in your browser — nothing is sent to any server

---

## For Admins — Host Your Own

### Prerequisites

- [Node.js](https://nodejs.org/) (v18+)
- [jq](https://jqlang.github.io/jq/) (JSON processor, used by the build script)
- A GitHub account

### 1. Fork or clone this repo

```bash
# Option A: Fork on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/report.git

# Option B: Clone and set your own remote
git clone https://github.com/salahawad/report.git
cd report
git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
```

### 2. Install dependencies

```bash
cd report
npm install
```

### 3. Create `teams.json`

This file is gitignored (passwords stay local). Create it in the repo root:

```json
{
  "your-team": {
    "password": "your-secret-password",
    "title": "Your Team Name"
  }
}
```

You can add as many teams as you need. Each team gets its own password.

### 4. Add your team's HTML reports

Create a folder under `teams/` with your team slug and add HTML files:

```
teams/your-team/
  index.html          ← main report (will become full-report.html)
  summary.html        ← optional additional pages
  sprint-review.html  ← add as many as you want
```

A **test-team** template is included as a reference with all available UI components (cards, tables, badges, theme colors). To preview it:

```bash
# First create a minimal teams.json if you haven't yet:
echo '{"test-team":{"password":"test123","title":"Test Team"}}' > teams.json

bash build.sh
npx serve dist
# Open http://localhost:3000/test-team/ → password: test123
```

Copy the template to your team folder and replace the placeholder content.

### 5. Register your team on the landing page

Edit the root `index.html` and add your team to the `teams` array:

```js
const teams = [
  { slug: 'your-team', name: 'Your Team Name' },
  // add more teams here
];
```

### 6. Build

```bash
bash build.sh
```

The build script will automatically:
- Encrypt every HTML file with the team's password (AES-256)
- Generate a unique cryptographic salt per team
- Generate an index page per team listing all available reports
- Rename `index.html` → `full-report.html` (so the generated index takes its place)
- Warn if passwords are weak (not enforced, advisory only)
- Output everything to `dist/`

### 7. Enable GitHub Pages

Go to your repo on GitHub:

**Settings → Pages → Source → GitHub Actions**

### 8. Commit and deploy

```bash
git add dist/ index.html
git commit -m "Add reports"
git push
```

The GitHub Actions workflow will automatically deploy `dist/` to GitHub Pages. Your site will be live at:

```
https://YOUR_USERNAME.github.io/YOUR_REPO/
```

---

## Adding more teams later

1. Create `teams/new-team/*.html` with the report HTML
2. Add the team to `teams.json` with a password
3. Add the team to the `teams` array in root `index.html`
4. Run `bash build.sh`
5. Commit `dist/` and `index.html`, then push

## Multiple pages per team

Add as many HTML files as you want to a team folder. The build script encrypts each one and auto-generates a team index page listing all reports.

```
teams/your-team/
  index.html            → becomes full-report.html
  summary.html          → stays summary.html
  sprint-review.html    → stays sprint-review.html
```

All pages within a team share the same password. Enter it once and "Remember me" handles the rest.

## File structure

```
dist/                        ← encrypted output (committed, deployed to GitHub Pages)
  index.html                 ← public landing page (team selector, not encrypted)
  <team-slug>/
    index.html               ← auto-generated report listing (encrypted)
    full-report.html         ← main report (encrypted)
    *.html                   ← additional pages (encrypted)
teams/                       ← raw reports (local only, gitignored)
  <team-slug>/*.html
teams.json                   ← team names + passwords (local only, gitignored)
teams.json.example           ← example config for reference
build.sh                     ← encrypts team pages → dist/
custom_template.html         ← password prompt template (customizable)
SECURITY.md                  ← security policy and disclosure process
.github/workflows/deploy.yml ← GitHub Actions deployment workflow
.github/dependabot.yml       ← automated dependency updates
```

## Security

- **AES-256 encryption** with 600,000 PBKDF2 iterations per password
- **Unique salt per team** — prevents cross-team key reuse even if passwords match
- **Raw reports** (`teams/`) and **passwords** (`teams.json`) are gitignored — they never leave your machine
- Only **encrypted HTML** is committed and deployed — zero readable content
- **Page titles are hidden** (shows "Protected Report")
- **Client-side only** — no server, no backend, no cookies, no data sent anywhere
- **Password strength warnings** during build (advisory, not enforced)
- **Dependabot enabled** for automated dependency security updates
- **Branch protection** on main — requires PR review before merge

See [SECURITY.md](SECURITY.md) for the full security policy and vulnerability reporting.
