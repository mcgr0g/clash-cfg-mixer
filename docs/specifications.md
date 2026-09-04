# Project Specifications & Core Constraints

## 1. Technical Requirements & Environment Configuration
* **Runtime Platform**: Linux-based Docker environment utilizing the `s6-overlay` ecosystem from LinuxServer.
* **Upstream Tracking (Dependabot)**: Dependabot configurations are mandatory to scan `linuxserver/baseimage-alpine` daily to pull down security patches.
* **Environment Strategy**:
  * `.env.template` - just example of production usage. All env vars  in mise.toml
  * Internal container directories are hardcoded to `/config-src` and `/config-out`. Users must never change these inside the container logic.
  * **Permission Fallbacks**: If `HOST_UID` and `HOST_GID` are not explicitly defined, they must fallback gracefully to the executing user's `$UID` and `$GID` to prevent root-owned file lockout on the host machine.
  * **Path Fallbacks**: Source and target paths default to local `./cfg-in` and `./cfg-out` subdirectories relative to the workspace root.
  * **Secret Fallbacks**: API and webhook secrets default to development placeholders (e.g., `make_mihomo_great_again`).

## 2. File Integrity & Empty-File Protection
* **Anti-Corruption Guard**: Before executing any merge sequence, the application MUST programmatically check that all incoming payload files (`cfg.mih.*.yml`) are **not empty (size > 0 bytes)** using `[ -s "$file" ]`.
* **Validation Failure Handling**: If an incoming layer is empty or corrupted, the process for that specific profile MUST be aborted immediately, retaining the previously generated valid configuration file.
* **Strict Read-Only Input**: The host input volume mapped to `/config-src` must be mounted as read-only (`:ro`).
