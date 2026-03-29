# Team Reports

Password-protected HTML reports published via GitHub Pages. Each team gets their own folder with AES-256 encrypted pages — without the correct password, the content is unreadable even though the repo is public.

Built with [StatiCrypt](https://github.com/robinmoisson/staticrypt).

## Structure

```
dist/                     ← encrypted output (committed, deployed)
  index.html              ← public landing page
  <team-slug>/index.html  ← encrypted report
teams/                    ← raw reports (local only, gitignored)
teams.json                ← team config + passwords (local only, gitignored)
build.sh                  ← encrypts team pages → dist/
```

## Setup

### 1. Enable GitHub Pages

Go to **Settings → Pages → Source** and select **GitHub Actions**.

### 2. Push to `main`

The workflow deploys the pre-built `dist/` folder automatically.

## Workflow

Raw reports and passwords never touch GitHub. The workflow is:

1. Put raw HTML reports in `teams/<team-slug>/index.html` (local)
2. Configure `teams.json` with team names and passwords (local)
3. Run `bash build.sh` to encrypt → `dist/`
4. Commit `dist/` and push — GitHub Pages deploys it

## Adding a new team

1. Create `teams/<team-slug>/index.html` with the report HTML
2. Add an entry to `teams.json`:
   ```json
   {
     "team-slug": {
       "password": "your-password",
       "title": "Team Display Name"
     }
   }
   ```
3. Add the team to the links array in `index.html`:
   ```js
   { slug: 'team-slug', name: 'Team Display Name' },
   ```
4. Run `bash build.sh`
5. Commit and push

## Local development

```bash
npm install
bash build.sh
npx serve dist
```

## How encryption works

StatiCrypt encrypts the entire HTML content with AES-256 using the team's password. The deployed page contains only a password prompt and the encrypted payload. Decryption happens client-side in the browser — no server-side auth needed.

The "Remember me" checkbox saves a salted hash in localStorage for 30 days so team members don't have to re-enter the password on every visit.
