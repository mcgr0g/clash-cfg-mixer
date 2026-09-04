# Agent System Map & Registry

This registry serves as an index for AI assistants to navigate operational logic and testing routines.

## Codebase Map

| File Path | Purpose | Key Operational Logic |
| :--- | :--- | :--- |
| `Dockerfile` | Multi-stage LinuxServer build | Base image tags pinned literally in `FROM` (no `ARG` indirection) so Dependabot can propose updates; integrates s6-overlay init services. |
| `docker-compose.yml` | Production deployment stack | Uses production `core-proxy` container names and fetches built artifacts from GHCR. Proxy API secret comes from env via mihomo's `CLASH_OVERRIDE_SECRET` (config layers stay secret-free); `SAFE_PATHS=/config` allows file-based reload. |
| `docker-compose.test.yml` | Isolated local/CI test environment | Directs `PROXY_NAS_HOST` variables to `test-proxy-nas` to separate testing domains; same `CLASH_OVERRIDE_SECRET`/`SAFE_PATHS` env wiring as prod. |
| `hooks.json` | Webhook definitions & cascading actions | Token resolved via Go-template (`` {{ getenv `WEBHOOK_SECRET_TOKEN` }} `` — backtick literal keeps the file valid JSON at rest); requires the `-template` flag in the Dockerfile; reload cascade lives in `mix.sh`. |
| `mix.sh` | Core mixing compiler utility | Contains size checks (`[ -s "$file" ]`) preventing empty-file overwrites, processes `yq` merges, and reloads the matching proxy via RESTful API (`PUT /configs?force=true`) after each successful compile. |
| `tests/fixtures/input/` | Mock source layers repository | Static YAML files stored inside Git for test baseline processing. |
| `tests/fixtures/expected/` | Expected target profiles output | Static ground-truth YAML outputs for final `diff` validation assertions, plus normalized runtime-dump ground truth (`general-*.yml`) for the mihomo API comparison. |
| `.github/dependabot.yml` | Upstream automated tracking file | Daily updates for the Dockerfile base images; requires literal tags in `FROM` (docker-ecosystem cannot parse `ARG`-based versions). |
| `mise.toml` | Tasks orchestration matrix | Houses the granular `test:*` DAG tasks (`build`, `up-mixer`, `mix-direct`, `up-proxies`, `trigger`, `verify-mix-*`, `verify-api-*`) orchestrated via `depends`; aggregate `test` entry point with `depends_post` teardown; also `up`, `down`. |
| `tests/fixtures/output/` | Compiled-config scratch dir for tests | Gitignored except the committed `.gitkeep` (see Conventions); populated by `mix.sh` via bind-mount. |

## Conventions & Secrets

* All environment values and secrets for the test stack live in `mise.toml` `[env]`. `.env` is only an optional local override (gitignored). CI never copies `.env.template` — that file is an example for the production `docker compose up` flow.
* `tests/fixtures/output/.gitkeep` is committed intentionally: the bind-mounted output dir must exist on a fresh checkout, otherwise Docker creates it root-owned and `mix.sh` (running as `abc`) fails with `mv: Permission denied`. Never manage bind-mount permissions from the Dockerfile (build stage runs before mounts exist) — prepare the directory in the repo/CI instead.
* Production operators must create `${HOST_OUTPUT_DIR}` themselves before `docker compose up`; ownership of host bind-mounts is outside the image's scope.
* The yq version must stay in sync between `Dockerfile` (`FROM mikefarah/yq:<v>`, used by `mix.sh` in the container) and `mise.toml` `[vars].yq_version` (host yq normalizes/regenerates fixtures); a mismatch silently breaks byte-diffs in `test:verify-mix-*`.

## Execution Hooks For AI Agents
* To initialize the workspace environment on a clean checkout: `mise run init`
* To execute the pristine automated integration check suite: `mise run test`
* To spin up containers for manual troubleshooting or logs viewing: `mise run up`
