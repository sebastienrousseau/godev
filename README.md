<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

<p align="center">
  <img src="https://cloudcdn.pro/godev/v1/logos/godev.svg" alt="godev logo" width="128" />
</p>

<h1 align="center">godev</h1>

<p align="center">
  A portable, disposable Go development container — the pinned official
  toolchain plus <code>gopls</code>, <code>dlv</code>, <code>staticcheck</code>,
  and <code>gofumpt</code> on the hardened <a href="https://github.com/sebastienrousseau/langdev">langdev</a>
  core that builds with <b>both</b> Docker and Podman and boots the
  developer's own dotfiles.
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

- [Quick start](#quick-start) — clone, `make up`, and you are in a dev shell
- [Why this approach?](#why-this-approach) — the choices that shape the image

**What you get**

- [What's inside](#whats-inside) — the pinned toolchain, exactly
- [The developer environment IS your dotfiles](#the-developer-environment-is-your-dotfiles) — no synthetic config, tmux loaded by default

**Operational**

- [Security model](#security-model) — the container threat model and controls
- [Portability](#portability) — engines, architectures, host assumptions
- [When not to use godev](#when-not-to-use-godev) — limitations, stated plainly
- [Development](#development) — `make` targets, tests, lint, scan, SBOM, CI
- [Documentation](#documentation) — community docs and the house style
- [License](#license)

---

## Quick start

`godev` is standalone. Clone it, and one command gets you an
interactive, hardened Go shell in a fresh container:

```sh
git clone https://github.com/sebastienrousseau/godev.git
cd godev
make up                        # build (if needed) + interactive dev shell
```

Other everyday commands:

```sh
make run CMD="go test ./..."   # one-shot command in a fresh container
make trash                     # remove the image + dangling build cache
```

Your project directory is the **only** bind mount, at `/work`.
Everything else is ephemeral (read-only rootfs + tmpfs), so a container
is truly disposable. No registry pull and no network are needed on first
launch — the image is built entirely from the repo you cloned, and the
Neovim plugin set is baked headless at build time.

---

## Why this approach?

`godev` is the Go member of the
[`langdev`](https://github.com/sebastienrousseau/langdev) suite: a
complete Go toolchain in a container you spin up and throw away in
seconds. Four choices, in priority order, shape the image:

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

3. **Portable and disposable.** One OCI `Containerfile` builds with
   Docker, Podman, Buildah, and nerdctl. The `Makefile` auto-detects the
   engine and adjusts flags (SELinux `:Z` mounts) accordingly. Images
   are multi-arch (`linux/amd64`, `linux/arm64`). The only bind mount is
   your project at `/work`, and `make trash` leaves nothing behind.

4. **Reliable and reproducible.** Everything is pinned: the Alpine base
   **by digest**, the Go distribution as a **sha256-verified** tarball
   (amd64 + arm64 — there is no `curl | sh`), the Go tools by
   `…@version`, and the Neovim plugin set via the dotfiles'
   `lazy-lock.json`. `GOFLAGS=-mod=readonly` and `GOTOOLCHAIN=local`
   keep builds reproducible; pin `DOTFILES_REF` to a tag or commit and a
   build is byte-reproducible.

Everything language-agnostic — the entrypoint, dotfiles bootstrap, and
`Containerfile`/`compose`/`Makefile` shape — is **vendored** from the
langdev core under `common/` and refreshed with `make sync-common`.
godev is therefore a complete, auditable unit on its own, with no
base-image drift and no supply-chain hop at build time.

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
`DOTFILES_REF` to a tag or commit for a reproducible build; the exact
commit bundled is recorded at `~/.dotfiles.commit`.

- **tmux is installed and loaded by default.** An interactive shell
  attaches to (or creates) a persistent `langdev` tmux session, so panes
  and windows survive detach. Opt out with `LANGDEV_NO_TMUX=1`.
- **The dotfiles' Neovim config is authoritative.** godev drops exactly
  one `nvim/plugins.local/lang.lua` spec into the config's
  `plugins.local/` directory (auto-imported via that convention), so it
  composes with the rest of your setup untouched.
- **LSP via `nvim-lspconfig`.** Go is wired through `nvim-lspconfig`'s
  `gopls` server at the pre-installed binary on `PATH`, with `gofumpt`
  and `staticcheck` analysis enabled inside `gopls` to match the CLI
  tools — no Mason, no network on first launch. The `go`, `gomod`,
  `gosum`, and `gowork` Treesitter grammars are added on top of your
  set.
- **Baked, offline-ready.** The full plugin set (yours plus this spec)
  is baked headless at build time from your dotfiles'
  `nvim/lazy-lock.json`, so the container is reproducible and needs no
  network on first launch.

Go aliases come from `/etc/profile.d/go.sh` (root-owned, `0644`), kept
**out** of the user's dotfiles so those stay pristine and
langdev-agnostic: `gob` (`go build ./...`), `got` (`go test ./...`),
`gov` (`go vet ./...`), `gor` (`go run .`), `gofm` (`gofumpt -l -w .`),
and `golint` (`staticcheck ./...`).

---

## Security model

Enforced by [`compose.yaml`](compose.yaml) and mirrored in
`make run` / `make shell`. The full threat model and the private
disclosure process are in [`SECURITY.md`](SECURITY.md).

- **Non-root.** Runs as `dev` (UID/GID 1000); no `sudo`, no setuid
  binaries — setuid/setgid bits are stripped at build, and `/tmp` is
  `1777`, sticky — not `777`.
- **Least privilege at runtime.** `cap_drop: [ALL]`,
  `security_opt: [no-new-privileges:true]`, `read_only: true` (with
  `tmpfs` for `/tmp`, `/home/dev/.cache`, and `/home/dev/.local/state`),
  and `init: true` (tini as PID 1 for clean signal handling).
- **Resource limits.** `pids_limit: 512`, `mem_limit: 4g`, `cpus: 2.0`.
  The memory limit is raised from the langdev default of 2g because Go's
  compiler and linker are memory-hungry on larger modules; lower it if
  you like.
- **Pinned, checksummed inputs.** Base image pinned **by digest**; the
  Go tarball **sha256-verified** (amd64 + arm64) — never `curl | sh`; Go
  tools installed with pinned `…@version`.
- **No committed secrets.** No `.env` is committed or `COPY`'d into an
  image — secrets are runtime-only via compose `env_file`. `.env` is
  gitignored **and** dockerignored. godev needs no secrets to build or
  run.
- **One bind mount.** The only bind mount is your project directory at
  `/work`.
- **CI gates every change.** `hadolint`, `shellcheck`, a Docker build,
  and a Trivy image scan (fail on HIGH/CRITICAL) run on every push and
  pull request; a CycloneDX SBOM is uploaded as an artifact.

Report a vulnerability privately — see [`SECURITY.md`](SECURITY.md). Do
not open a public issue.

---

## Portability

- **One `Containerfile` (OCI).** `docker build`, `podman build`,
  `buildah`, and `nerdctl` all work from the same file.
- **Engine autodetection.** The `Makefile` detects `docker` or `podman`
  and adjusts flags (SELinux `:Z` mounts) accordingly.
- **Multi-arch.** Images build for `linux/amd64` and `linux/arm64` via
  `docker buildx` / `podman --platform`; the official Go binaries are
  statically linked and run on Alpine/musl.
- **No host assumptions.** The only bind mount is your project directory
  at `/work`.

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
  VM-less fallback; godev targets an OCI engine on Linux, macOS, or
  Windows/WSL2.

---

## Development

The `Makefile` exposes the full lifecycle and auto-detects `docker` or
`podman` (adding `:Z` SELinux mount flags for Podman), so the same
commands work with either engine:

```sh
make up          # build + interactive dev shell (alias: make shell)
make run CMD=…   # one-shot command in a fresh container
make build       # build the image for the host arch
make buildx      # multi-arch build (linux/amd64, linux/arm64)
make lint        # hadolint the Containerfile + shellcheck the scripts
make scan        # Trivy vulnerability scan (fail on HIGH/CRITICAL)
make sbom        # CycloneDX SBOM via syft
make trash       # remove the image and dangling build cache
make sync-common # refresh common/ from the langdev source
```

### Tests and coverage

The language-agnostic shell core — `common/bootstrap-dotfiles.sh` and
`common/entrypoint.sh` — is vendored verbatim from the
[`langdev`](https://github.com/sebastienrousseau/langdev) core and
refreshed with `make sync-common`. That core is unit-tested with
[bats-core](https://github.com/bats-core/bats-core) under
[kcov](https://github.com/SimonKagstrom/kcov) in the langdev repo, whose
`make test` / `make coverage` gate **fails below 95 % line coverage**.
The tests are hermetic — `git`, `chezmoi`, `nvim`, `tmux`, and `rsync`
are test doubles on a closed `PATH`, so no network or container is
needed. The suite and its coverage gate are documented in
[langdev's `test/README.md`](https://github.com/sebastienrousseau/langdev/blob/main/test/README.md).

### CI and security workflows

This repo's [`.github/workflows/ci.yml`](.github/workflows/ci.yml) gates
every push and pull request with `hadolint`, `shellcheck`, a Docker
build, a Trivy image scan (fail on HIGH/CRITICAL), and a CycloneDX SBOM
artifact. The suite's OpenSSF hardening workflows are maintained in the
langdev core and provisioned across the suite from
[`templates/github-workflows/`](https://github.com/sebastienrousseau/langdev/tree/main/templates/github-workflows):

| Workflow | What it gates |
|---|---|
| `ci.yml` | shellcheck, hadolint, Docker build, Trivy image scan (fail HIGH/CRITICAL), CycloneDX SBOM |
| `scorecard.yml` | OpenSSF Scorecard, results published + SARIF to code-scanning |
| `sast.yml` | ShellCheck + Trivy config + Checkov, SARIF → code-scanning |
| `dependency-review.yml` | dependency + action changes reviewed on every PR |

The OpenSSF Best-Practices self-assessment lives in the langdev core's
[`doc/CII-BEST-PRACTICES.md`](https://github.com/sebastienrousseau/langdev/blob/main/doc/CII-BEST-PRACTICES.md);
a maintainer can apply the branch-protection ruleset with langdev's
[`scripts/set-branch-protection.sh`](https://github.com/sebastienrousseau/langdev/blob/main/scripts/set-branch-protection.sh).

Contributions require signed commits and Conventional Commit messages —
see [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

## Documentation

| Document | What it covers |
|---|---|
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | The container workflow: build/test/lint/scan/sbom, signed commits, Conventional Commits. |
| [`SECURITY.md`](SECURITY.md) | The container threat model and the private disclosure process. |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Community standards and enforcement. |
| [`GOVERNANCE.md`](GOVERNANCE.md) | Who decides what, and how the maintainer base is meant to grow. |
| [`SUPPORT.md`](SUPPORT.md) | Where to go for questions, bugs, and feature requests. |
| [`CHANGELOG.md`](CHANGELOG.md) | Notable changes, Keep a Changelog format. |
| [langdev `doc/CII-BEST-PRACTICES.md`](https://github.com/sebastienrousseau/langdev/blob/main/doc/CII-BEST-PRACTICES.md) | OpenSSF Best-Practices self-assessment for the suite. |

godev follows the langdev suite's house style — see
[`STYLE.md`](https://github.com/sebastienrousseau/langdev/blob/main/STYLE.md)
in the `langdev` core.

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
