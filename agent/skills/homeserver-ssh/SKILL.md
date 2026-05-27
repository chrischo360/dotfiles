---
name: homeserver-ssh
description: Safely operate the self-hosted homeserver over the homeserver-remote SSH alias, including Docker Compose maintenance, remote file inspection, deploys, logs, and SSH/security changes.
metadata:
  source: local://dotfiles/agent/skills/homeserver-ssh
---
# Homeserver SSH

Use this skill for tasks involving `homeserver-remote`, the self-hosted server stack, Docker Compose services, Traefik routes, or remote SSH maintenance.

## SSH Rules

- Prefer one-shot commands:
  ```bash
  ssh homeserver-remote '<command>'
  ```
- Avoid interactive SSH sessions unless the user explicitly asks.
- Use read-only inspection before changes.
- Do not print secrets from `.env`, private keys, tokens, passwords, or `acme.json`.
- Redact secret values if command output includes them.
- Ask before changing SSH users, authorized keys, firewall rules, router-facing config, or permissions.

## Approval Required

Ask before running:

- `rm`, `del`, `rmdir`, `Remove-Item`
- `docker-compose down`, `docker compose down`
- volume deletion or prune commands
- firewall, SSH daemon, or user-account changes
- commands that overwrite configs on the server
- commands that restart many services at once

## Docker Compose

- Edit the local repo first when the stack is represented locally.
- Ask before deploying remote changes.
- Deploy the smallest scope possible:
  ```bash
  ssh homeserver-remote 'cd <stack-path> && docker-compose up -d <service>'
  ```
- Prefer limited logs:
  ```bash
  ssh homeserver-remote 'cd <stack-path> && docker-compose logs --tail=100 <service>'
  ```
- For Traefik route changes, update both:
  - `docker-compose.yml`
  - `traefik/static/traefik-static.yml`

## Remote Editing

- Prefer local edits plus explicit deploy for tracked stack files.
- If editing remote-only files, create a backup first unless the user opts out.
- Show the exact target path before modifying remote files.

## Security Defaults

- Prefer a dedicated non-admin SSH user and dedicated key.
- Prefer LAN/VPN access over public SSH.
- Keep password auth disabled when possible.
- Treat Docker socket/group access as administrator-equivalent.
