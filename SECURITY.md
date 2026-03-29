# Security

## How Encryption Works

Reports are encrypted client-side using **AES-256** via [StatiCrypt](https://github.com/robinmoisson/staticrypt). The encrypted HTML pages contain only a password prompt and an encrypted payload. Decryption happens entirely in the browser using the Web Crypto API — no data is sent to any server.

## What Is Public

- The encrypted HTML files in `dist/` (unreadable without the password)
- The landing page with team names
- The password prompt template

## What Stays Private

- Raw HTML reports (`teams/`) — gitignored, never committed
- Team passwords (`teams.json`) — gitignored, never committed
- Encryption salt (`.staticrypt.json`) — gitignored

## Limitations

- This is **client-side encryption** — it protects content from casual access but is not a substitute for server-side authentication
- If a password is compromised, the encrypted pages can be decrypted by anyone
- The encryption key is derived from the password — use strong, unique passwords per team
- "Remember me" stores a salted hash in browser localStorage — anyone with access to the device can view previously decrypted reports

## Reporting a Vulnerability

If you discover a security issue in this project, please report it responsibly:

1. **Do not** open a public issue
2. Email **salah.awad@outlook.com** with a description of the vulnerability
3. Allow reasonable time for a fix before public disclosure

## Best Practices for Users

- Use strong passwords (12+ characters, mixed case, numbers, symbols)
- Rotate passwords periodically and rebuild encrypted pages
- Never commit `teams.json` or raw reports to the repository
- Verify `.gitignore` is intact before pushing
