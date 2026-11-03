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

## golem-ai override scheme
The base `cfg.mih.uni.yml` is the only profile that routes AI traffic through the personal `golem` node:
* `proxy-providers.golem-ai` — `inline` provider with a single vless+ws+tls node (`golem`);
* proxy group `Pinned Proxy` uses `use: [golem-ai]`, AI-domain rules point to `Pinned Proxy`;
* top-level `tunnels:` has one entry (`tcp,127.0.0.1:18317,cpa.golem:8317,Pinned Proxy`).

Other layers (`cell`, `nas`) must **not** inherit the node. `yq` deep-merges maps but replaces lists whole, so each such layer has to:
* repeat all `proxy-groups` from the base, with `Pinned Proxy` using `use: [vpnd-io-vless, vpnd-io-ws]`;
* replace `proxy-providers.golem-ai` with a harmless `inline` provider holding one `type: direct` node (mihomo rejects `golem-ai: null` — "unset fields: type" — and an empty inline — "file doesn't have any proxy"; `inline` needs mihomo >= 1.18);
* set `tunnels: []`.

Safety nets: `mix.sh` refuses to write a layer if the base golem `uuid` is found in the merged result (opt out for a layer that intentionally ships golem with `ALLOW_GOLEM_<FLAVOR>=1`), and `mise run test` runs `test:verify-schema` over the fixtures.

## Quick Start Configuration

### Running instructions
1. Copy the environment file template: `cp .env.template .env`
2. Spin up the containers: `docker compose up -d`
3. Trigger the mixing pipeline:
```bash
curl -X POST "http://localhost:2026/hooks/trigger-mix?token=YOUR_WEBHOOK_SECRET"
```
