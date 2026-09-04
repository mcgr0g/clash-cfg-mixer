# clash-cfg-mixer

`clash-cfg-mixer` is a lightweight, secure, and automated configuration pipeline tool designed to orchestrate and merge proxy configurations. It acts as an event-driven middleman between `git-sync` and your core container.

## Architecture & Flow
1. **gitsync** pulls updates from a private repository containing config fragments.
2. **gitsync** triggers `clash-cfg-mixer` via an authorized webhook endpoint.
3. `clash-cfg-mixer` validates incoming layers, dynamically merges them with the base file using `yq`, and writes unified ready-to-use profiles to an external shared directory.
4. `clash-cfg-mixer` commands the nearby proxy container to reload by calling `PUT /configs?force=true` on its RESTful API.

## Key Features
* **Zero-Write on Inbound**: The source directory is strictly read-only (`:ro`). No accidental cluttering that could break `git-sync`.
* **Dynamic Layer Resolution**: Automatically detects new configurations following the `cfg.mih.*.yml` schema and generates matching outputs.
* **Anti-Corruption & Atomic Writes**: Incorporates automatic size checks (`> 0 bytes`) to prevent overwriting perfectly valid running configurations with empty payloads.
* **LinuxServer Base**: Built on top of `ghcr.io/linuxserver/baseimage-alpine` for built-in `s6-overlay` supervisor control and pristine host `PUID`/`PGID` permission mirroring.
* **Bot-friendly Upstream**: Formatted explicitly for daily out-of-the-box tracking by automated dependency bots like Dependabot.

## Quick Start Configuration

### Running instructions
1. Copy the environment file template: `cp .env.template .env`
2. Spin up the containers: `docker compose up -d`
3. Trigger the mixing pipeline:
```bash
curl -X POST "http://localhost:2026/hooks/trigger-mix?token=YOUR_WEBHOOK_SECRET"
```
