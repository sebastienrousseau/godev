<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

<p align="center">
  <img src="https://cloudcdn.pro/godev/v1/logos/godev.svg" alt="godev logo" width="128" />
</p>

<h1 align="center">godev</h1>

<p align="center">
  A portable, disposable Go development container — the pinned official
  toolchain plus <code>gopls</code>, <code>dlv</code>, <code>staticcheck</code>,
  and <code>gofumpt</code>, hardened by default and booting your own dotfiles.
</p>

<p align="center">
  <a href="https://github.com/sebastienrousseau/godev/actions"><img src="https://img.shields.io/github/actions/workflow/status/sebastienrousseau/godev/ci.yml?style=for-the-badge&logo=github" alt="Build" /></a>
  <a href="#license"><img src="https://img.shields.io/badge/license-Apache--2.0%20OR%20MIT-blue?style=for-the-badge" alt="License: Apache-2.0 OR MIT" /></a>
  <a href="https://scorecard.dev/viewer/?uri=github.com/sebastienrousseau/godev"><img src="https://img.shields.io/ossf-scorecard/github.com/sebastienrousseau/godev?style=for-the-badge&label=OpenSSF%20Scorecard&logo=openssf" alt="OpenSSF Scorecard" /></a>
  <a href="#portability"><img src="https://img.shields.io/badge/engines-docker%20%7C%20podman-1d63ed?style=for-the-badge&logo=docker" alt="Engines: Docker or Podman" /></a>
  <a href="#portability"><img src="https://img.shields.io/badge/arch-amd64%20%C2%B7%20arm64-555?style=for-the-badge" alt="Architectures: amd64, arm64" /></a>
</p>

---

## Contents

**Getting started**

- [Quick start](#quick-start) — `make up`, and you are in a Go dev shell
- [Why this approach?](#why-this-approach) — the choices that shape the image

**What you get**

- [What's inside](#whats-inside) — the pinned toolchain, versions, how each is pinned
- [The developer environment IS your dotfiles](#the-developer-environment-is-your-dotfiles) — tmux, Neovim, aliases

**Operational**

- [Security model](#security-model) — the container threat model and controls
- [Portability](#portability) — engines, architectures, host assumptions
- [When not to use godev](#when-not-to-use-godev) — limitations, stated plainly
- [Development](#development) — `make` targets, lint, scan, SBOM, CI
- [Documentation](#documentation) — community docs and the house style
- [License](#license)

---

## Quick start

`godev` is standalone. Clone it, and one command gets you an
interactive, hardened Go shell in a fresh container:

```sh
git clone https://github.com/sebastienrousseau/godev.git
cd godev
make up                        # build (if needed) + drop into a dev shell
```

`make up` builds for the host architecture and runs the container
non-root, read-only, with all capabilities dropped (see
[Security model](#security-model)). Your project directory is the **only**
bind mount, at `/work`. One-shot commands and teardown:

```sh
make run CMD="go test ./..."   # one-shot command in a fresh container
make trash                     # remove the image and dangling build cache
```

No registry pull and no base-image dependency — the image is built
entirely from the repo you cloned. Everything except `/work` is
ephemeral (read-only rootfs + tmpfs), so a container is truly
disposable.

---

## Why this approach?

`godev` is the Go member of the [`langdev`](https://github.com/sebastienrousseau/langdev)
suite. It inherits the suite's design; three choices matter most for the
Go image specifically:

1. **Secure by default, not by opt-in.** The container runs as a
   non-root `dev` user (UID/GID 1000) with **all Linux capabilities
   dropped**, `no-new-privileges`, and a **read-only root filesystem**;
   writable state is confined to explicit `tmpfs` mounts. This is the
   default `make up` posture, not a hardened variant you have to
   remember to select. The threat model is [documented](SECURITY.md),
   not implied.

2. **Ultra-small but complete.** The Go compiler and its
   LSP/formatter/analysis tools are built in a separate `toolchain`
   stage; only the relocatable prefix (`/opt/langdev/toolchain`) is
   copied into the final image. Build tools (`curl`, `git`) and the Go
   build/module caches never reach the runtime layer, and the pinned
   tools are compiled with `CGO_ENABLED=0` so they are static and need
   no C toolchain at runtime. You can edit, build, test, and debug
   without reaching outside the container.

3. **Reliable and reproducible.** Everything is pinned: the Alpine base
   **by digest**, the Go distribution as a **sha256-verified** tarball
   (amd64 + arm64 — there is no `curl | sh`), the Go tools by
   `…@version`, and the Neovim plugin set via the dotfiles'
   `lazy-lock.json`. `GOFLAGS=-mod=readonly` and `GOTOOLCHAIN=local`
   keep builds reproducible; pin `DOTFILES_REF` to a tag or commit and a
   build is byte-reproducible.

---

## What's inside

Every input is pinned. Bump the toolchain versions together.

| Component | Version | How it's pinned |
|---|---|---|
| Alpine base | `3.22` | by digest `sha256:14358309…695dce` |
| Go (official) | `1.27.0` | `GO_VERSION` build arg; tarball sha256-verified (amd64 + arm64) |
| `gopls` (LSP) | `v0.23.0` | `GOPLS_VERSION`; `go install …@version` |
| `dlv` (Delve) | `v1.27.1` | `DELVE_VERSION`; `go install …@version` |
| `staticcheck` | `2026.2.1` | `STATICCHECK_VERSION`; `go install …@version` |
| `gofumpt` | `v0.11.0` | `GOFUMPT_VERSION`; `go install …@version` |
| Dotfiles | latest | `DOTFILES_REF` build arg (default `main`; pin for reproducible builds) |
| Neovim plugins | — | baked headless at build time from the dotfiles' `lazy-lock.json` |

The `go`, `gofmt`, `gopls`, `dlv`, `staticcheck`, and `gofumpt` binaries
are all on `PATH`. The exact dotfiles commit baked into the image is
recorded at `~/.dotfiles.commit`.

### The read-only rootfs and the Go caches

`GOROOT` and the baked `GOPATH` (which holds the pre-installed tools) are
read-only. So that `go build`/`go test` still work, the build cache,
module cache, and any `go install` output are redirected onto the
writable `tmpfs` under `~/.cache/go` via `GOCACHE`, `GOMODCACHE`, and
`GOBIN`. These are ephemeral and vanish with the disposable container —
populate a project's dependencies from a committed `go.sum` (the proxy
is reachable at runtime unless you also drop network). The same values
are set as image `ENV`, so non-login one-shot commands (e.g.
`make run CMD="go test ./..."`) get the identical environment.

---

## The developer environment IS your dotfiles

`godev` does **not** ship a synthetic shell or editor config. At build
time it clones the user's chezmoi-managed **dotfiles repo** and runs
`chezmoi apply`, so the container has the *real* bashrc, aliases, tmux
config, and Neovim setup — **always the latest** by default. Pin
`DOTFILES_REF` to a tag or commit for reproducible builds.

- **tmux** is installed and **loaded by default**: an interactive
  `make up` attaches to (or creates) a persistent `langdev` tmux session
  so panes and windows survive detach. Opt out with `LANGDEV_NO_TMUX=1`.
- **Neovim** uses your own config, authoritative and baked headless at
  build time (no network on first launch). `godev` drops **one** spec,
  `nvim/plugins.local/lang.lua`, into the config's `plugins.local/`
  directory (auto-imported via that convention). It wires `gopls`
  through `nvim-lspconfig` at the pre-installed binary on `PATH`, with
  `gofumpt` and `staticcheck` analysis enabled inside `gopls` to match
  the CLI tools, and adds the `go`, `gomod`, `gosum`, and `gowork`
  Treesitter grammars.
- **Go aliases** come from `/etc/profile.d/go.sh` (root-owned `0644`),
  kept **out** of the user's dotfiles so those stay pristine and
  langdev-agnostic: `gob` (`go build ./...`), `got` (`go test ./...`),
  `gov` (`go vet ./...`), `gor` (`go run .`), `gofm` (`gofumpt -l -w .`),
  and `golint` (`staticcheck ./...`).

---

## Security model

Enforced by [`compose.yaml`](compose.yaml) and mirrored in
`make run`/`make shell`. The full threat model and the private
disclosure process are in [`SECURITY.md`](SECURITY.md).

- **Non-root.** Runs as `dev` (UID/GID 1000); no `sudo`, no setuid
  binaries — setuid/setgid bits are stripped at build, and `/tmp` is
  `1777` sticky (not `777`).
- **Least privilege at runtime.** `cap_drop: [ALL]`,
  `security_opt: [no-new-privileges:true]`, `read_only: true` (with
  `tmpfs` for `/tmp`, `/home/dev/.cache`, and `/home/dev/.local/state`),
  and `init: true`.
- **Resource limits.** `pids_limit: 512`, `mem_limit: 4g`, `cpus: 2.0`.
  The memory limit is raised from the langdev default of 2g because Go's
  compiler and linker are memory-hungry on larger modules; lower it if
  you like.
- **Pinned, checksummed inputs.** Base image pinned **by digest**; the
  Go tarball **sha256-verified** (amd64 + arm64) — never `curl | sh`; Go
  tools installed with pinned `…@version`.
- **No committed secrets.** No `.env` is committed or `COPY`'d into an
  image — secrets are runtime-only via compose `env_file`. `.env` is
  gitignored **and** dockerignored. `godev` needs no secrets to build or
  run.
- **The only bind mount** is your project directory at `/work`.

Report a vulnerability privately — see [`SECURITY.md`](SECURITY.md). Do
not open a public issue.

---

## Portability

- **One `Containerfile` (OCI).** `docker build`, `podman build`,
  `buildah`, and `nerdctl` all work from the same file.
- **Engine autodetection.** The `Makefile` detects `docker` or `podman`
  and adjusts flags (SELinux `:Z` mounts) accordingly.
- **Multi-arch.** Builds for `linux/amd64` and `linux/arm64`; the
  official Go binaries are statically linked and run on Alpine/musl.
- **No host assumptions** beyond the `/work` bind mount.

---

## When not to use godev

Stated plainly, so you can rule it out fast:

- **You need a production runtime image.** `godev` builds a *development*
  environment — editor, LSP, test tooling, a shell. It is deliberately
  not a minimal production artifact; build a separate `FROM scratch` or
  distroless image for your compiled binary.
- **You do not use chezmoi-managed dotfiles.** The environment *is* the
  user's dotfiles. Without a chezmoi dotfiles repo you lose the main
  point, though the hardening and Go toolchain layers still stand on
  their own.
- **You need cgo, or GPU / host-device access.** The pinned tools are
  built `CGO_ENABLED=0` and the default posture drops all capabilities
  and forbids privilege escalation. Workloads needing a C toolchain or
  device access require deliberate, documented relaxations that run
  against the grain of the design.
- **You are on a platform without Docker or Podman.** There is no
  VM-less fallback; the image targets an OCI engine on Linux, macOS, or
  Windows/WSL2.

---

## Development

The `Makefile` auto-detects `docker` or `podman` (adding `:Z` SELinux
mount flags for Podman) so the same commands work with either engine.
The common targets:

```sh
make up          # build + interactive dev shell (alias: make shell)
make run CMD=… # one-shot command in a fresh container
make build       # build the image for the host arch
make buildx      # multi-arch build (linux/amd64, linux/arm64)
make lint        # hadolint the Containerfile + shellcheck the scripts
make scan        # Trivy vulnerability scan (fail on HIGH/CRITICAL)
make sbom        # CycloneDX SBOM (sbom.cdx.json) via syft
make trash       # remove the image and dangling build cache
make sync-common # refresh common/ from the langdev source
```

CI (`.github/workflows/ci.yml`) gates every change with `hadolint`,
`shellcheck`, a Docker build, and a Trivy scan (fails on HIGH/CRITICAL),
and uploads a CycloneDX SBOM artifact. Contributions require signed
commits and Conventional Commit messages — see
[`CONTRIBUTING.md`](CONTRIBUTING.md).

---

## Documentation

| Document | What it covers |
|---|---|
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | The container workflow: build/lint/scan/sbom, signed commits, Conventional Commits. |
| [`SECURITY.md`](SECURITY.md) | The container threat model and the private disclosure process. |
| [`GOVERNANCE.md`](GOVERNANCE.md) | Who decides what, and how the maintainer base is meant to grow. |
| [`SUPPORT.md`](SUPPORT.md) | Where to go for questions, bugs, and feature requests. |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Community standards and enforcement. |
| [`CHANGELOG.md`](CHANGELOG.md) | Notable changes, Keep a Changelog format. |
| [`langdev`](https://github.com/sebastienrousseau/langdev) | The shared core and the suite house style (`STYLE.md`). |

---

## License

Licensed under either of

- Apache License, Version 2.0 ([`LICENSE-APACHE`](LICENSE-APACHE))
- MIT license ([`LICENSE-MIT`](LICENSE-MIT))

at your option. The suite is dual-licensed `Apache-2.0 OR MIT`; every
non-vendored file carries an `SPDX-License-Identifier: Apache-2.0 OR MIT`
header.

Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in the work by you, as defined in the Apache-2.0
license, shall be dual licensed as above, without any additional terms
or conditions.
