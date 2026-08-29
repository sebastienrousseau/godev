<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.4] - 2026-08-29

### Added

- **TUI Power Suite & Interactive Explorer.**
  - Added `common/explorer.sh` providing an interactive TUI sidebar for Left Panel navigation with Git branch context, dirty file indicators, visual tree view, and Neovim editor dispatch.
  - Enhanced `common/tmux-ide.sh` to auto-detect and launch Yazi or the interactive project explorer.
- **Bats Unit Tests.**
  - Added `test/explorer.bats`.

## [0.0.3] - 2026-08-29

### Added

- **Model Context Protocol (MCP) Server Suite.**
  - Added `common/mcp-server.sh` implementing JSON-RPC 2.0 stdio transport exposing workspace tools (`list_files`, `read_file`, `git_status`, `git_diff`, `run_tests`, `run_command`) to AI coding agents.
  - Added `common/mcp.json` configuration template for Claude Code, Cursor, and Aider.
- **AI Context Packing (`ai-pack`).**
  - Added `common/ai-pack.sh` for fast, token-efficient XML and Markdown codebase bundling respecting `.gitignore`.
- **Local LLM Routing.**
  - Added automatic resolution for local Ollama instances (`http://host.containers.internal:11434`).
- **Bats Unit Tests.**
  - Added `test/mcp.bats` and `test/ai-pack.bats`.

## [0.0.2] - 2026-08-29

### Added

- **Remote & Mobile Web Access.**
  - `make web` and `make web-auth` targets using `ttyd` for browser-based access on iPads and mobile devices over WebSocket/SSL.
  - `make mosh` for UDP-based roaming mobile shell sessions that survive connection drops.
- **Diagnostic CLI (`make doctor`).**
  - Added `common/doctor.sh` to probe host engines, architecture, cgroups, kernel security, and clipboard readiness.
- **Universal Clipboard (OSC 52).**
  - Added `set -s set-clipboard on` in `common/tmux.conf` for seamless copy-paste to host/mobile clipboards.
- **TUI Popups.**
  - Added floating TMUX popups for Lazygit (`Prefix + g`) and Lazydocker (`Prefix + d`).
- **VS Code IDE Grid & Parallel Task Worktrees.**
  - Added `common/tmux-ide.sh` (`Prefix + i`) and `common/muxtree.sh` (`Prefix + m`).

## [0.0.1] - 2026-08-29

`godev` is the Go member of the [`langdev`](https://github.com/sebastienrousseau/langdev)
suite: a portable, disposable Go development container built on the
shared, hardened langdev core, that builds with **both** Docker and
Podman and boots the developer's own chezmoi-managed dotfiles.

### Added

- **Go toolchain stage.** The official, checksum-verified Go `1.27.0`
  distribution (amd64 + arm64) plus the pinned Go tools `gopls`
  `v0.23.0`, `dlv` (Delve) `v1.27.1`, `staticcheck` `2026.2.1`, and
  `gofumpt` `v0.11.0`, all installed with `CGO_ENABLED=0` into a
  relocatable `/opt/langdev/toolchain` prefix copied into the final
  image — no build tools or module caches reach the runtime layer.
- **Go language wiring.** A single `nvim/plugins.local/lang.lua` spec
  wiring `gopls` through `nvim-lspconfig` (with `gofumpt` and
  `staticcheck` analysis enabled to match the CLI), and a
  `dotfiles.d/go.sh` fragment installed to `/etc/profile.d/go.sh` that
  exports `GOROOT`/`GOPATH`/`GOBIN`, sets `GOFLAGS=-mod=readonly` and
  `GOTOOLCHAIN=local`, and adds the Go-specific shell aliases.
- **Read-only-rootfs cache redirect.** `GOCACHE`, `GOMODCACHE`, and
  `GOBIN` are redirected onto the writable `~/.cache/go` tmpfs so
  `go build`/`go test` work under the read-only root filesystem.
- **Shared langdev core.** Vendored `common/entrypoint.sh` and
  `common/bootstrap-dotfiles.sh`, the hardened `Containerfile`,
  `compose.yaml`, and docker/podman-autodetecting `Makefile`.
- **Security posture, on by default.** Non-root `dev` (UID/GID 1000);
  `cap_drop: [ALL]`; `no-new-privileges`; read-only root filesystem with
  `tmpfs` for writable state; `pids_limit: 512`, `mem_limit: 4g`,
  `cpus: 2.0`; base image pinned by digest; the Go tarball
  sha256-verified (no `curl | sh`); no committed or baked-in secrets.
- **CI gates.** `hadolint`, `shellcheck`, a Docker build, and a Trivy
  image scan (fail on HIGH/CRITICAL) on every push and pull request; a
  CycloneDX SBOM uploaded as an artifact.

### Documentation

- README rewritten to the langdev suite [`STYLE.md`](https://github.com/sebastienrousseau/langdev/blob/main/STYLE.md)
  house style — centered header, badge row, Contents ToC, and the
  standard suite section order.
- Community docs vendored from the langdev core:
  [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md),
  [`CONTRIBUTING.md`](CONTRIBUTING.md), [`SECURITY.md`](SECURITY.md),
  [`SUPPORT.md`](SUPPORT.md), [`GOVERNANCE.md`](GOVERNANCE.md).
- `.github/` scaffolding: `CODEOWNERS`, `FUNDING.yml`, `dependabot.yml`,
  a pull-request template, and issue forms (bug report, feature request,
  and a config routing questions and security reports).

### Licensing

- Relicensed from single MIT to **dual `Apache-2.0 OR MIT`**. Added
  `LICENSE-APACHE` and `LICENSE-MIT`, removed the single `LICENSE` file,
  and applied `SPDX-License-Identifier: Apache-2.0 OR MIT` headers across
  the non-vendored sources.

[Unreleased]: https://github.com/sebastienrousseau/godev/commits/main
