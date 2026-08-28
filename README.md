<!-- SPDX-License-Identifier: MIT -->

# godev — portable, disposable Go development environment

`godev` is a member of the [`langdev`](../../dockerfile/langdev) suite:
a complete, batteries-included Go toolchain inside a container you can
**spin up and throw away in seconds** — on any machine with Docker or
Podman (Linux, macOS, Windows/WSL2).

It ships the pinned official Go toolchain (compiler, `go`, `gofmt`) plus
`gopls`, `dlv` (Delve), `staticcheck`, and `gofumpt`. The developer
environment (shell, editor, **tmux**) is **your own chezmoi-managed
dotfiles**, cloned and applied at build time — always the latest by default
(pin a tag/commit with the `DOTFILES_REF` build arg). A single
`nvim/plugins.local/lang.lua` spec is dropped into your dotfiles' Neovim to
wire `gopls`; plugins are baked headless at build time, so no network is
needed on first launch.

## Quick start

```sh
make up            # build (if needed) + drop into an interactive dev shell
make run CMD="go test ./..."   # one-shot command in a fresh container
make trash         # remove the image + dangling build cache
```

Your code is the **only** bind mount, at `/work`. Everything else is
ephemeral (read-only rootfs + tmpfs), so a container is truly disposable.

**tmux is loaded by default:** an interactive `make up` attaches to (or
creates) a persistent `langdev` tmux session so panes/windows survive
detach. Opt out with `LANGDEV_NO_TMUX=1`.

## What's inside (pinned)

| Component | Version | How it's pinned |
|---|---|---|
| Alpine base | `3.22` | by digest `sha256:14358309…695dce` |
| Go (stable) | `1.27.0` | `GO_VERSION` build arg; tarball sha256-verified (amd64 + arm64) |
| `gopls` (LSP) | `v0.23.0` | `GOPLS_VERSION`; `go install …@version` |
| `dlv` (Delve) | `v1.27.1` | `DELVE_VERSION`; `go install …@version` |
| `staticcheck` | `2026.2.1` | `STATICCHECK_VERSION`; `go install …@version` |
| `gofumpt` | `v0.11.0` | `GOFUMPT_VERSION`; `go install …@version` |
| Dotfiles | latest | `DOTFILES_REF` build arg (default `main`; pin a tag/commit for reproducible builds) |
| Neovim plugins | — | baked headless at build time from your dotfiles' `lazy-lock.json` |

The toolchain is built in a separate `toolchain` stage and only its
relocatable prefix (`/opt/langdev/toolchain`) is copied into the final
image — build tools (`curl`, `git`) and the Go build/module caches never
reach the runtime layer. The pinned tools are compiled with `CGO_ENABLED=0`
so they are static and need no C toolchain at runtime.

> **Dotfiles provenance:** the exact dotfiles commit bundled into the image
> is recorded at `~/.dotfiles.commit`. Builds are "always the latest" by
> default; pass `--build-arg DOTFILES_REF=<tag-or-commit>` (or set it in
> `compose.yaml`) to freeze a specific revision for reproducible builds.

## Make targets

| Target | Description |
|---|---|
| `make up` / `make shell` | Build then start an interactive dev shell |
| `make run CMD="…"` | Run a one-shot command in a fresh container |
| `make build` | Build the image for the host arch |
| `make buildx` | Build a multi-arch image (`linux/amd64,linux/arm64`) |
| `make trash` | Remove the image and dangling build cache |
| `make lint` | `hadolint` the Containerfile + `shellcheck` the scripts |
| `make scan` | Trivy vulnerability scan (HIGH/CRITICAL) of the built image |
| `make sbom` | Generate a CycloneDX SBOM (`sbom.cdx.json`) via syft |
| `make sync-common` | Refresh `common/` from the langdev source |

The `Makefile` auto-detects `docker` or `podman` (adding `:Z` SELinux
mount flags for Podman) so the same commands work with either engine.

## Aliases

General shell aliases come from **your own chezmoi-managed dotfiles**
(applied at build time), so they are whatever you already use day to day.
godev adds only the Go-specific fragment below.

### Go (`/etc/profile.d/go.sh`)

| Alias | Expands to |
|---|---|
| `gob` | `go build ./...` |
| `got` | `go test ./...` |
| `gov` | `go vet ./...` |
| `gor` | `go run .` |
| `gofm` | `gofumpt -l -w .` |
| `golint` | `staticcheck ./...` |

`go.sh` (installed to `/etc/profile.d/go.sh`, root-owned `0644`) also exports
`GOROOT`, `GOPATH`, `GOBIN`, prepends the toolchain bins to `PATH`, and sets
`GOFLAGS=-mod=readonly` and `GOTOOLCHAIN=local` for reproducible builds. It
does **not** propagate any host `PATH`. It lives in `/etc/profile.d` (not the
user's dotfiles) so those stay pristine and langdev-agnostic; the same values
are also set as image `ENV` so non-login one-shot commands (e.g.
`make run CMD="go test ./..."`) get the identical environment.

> **Read-only rootfs & the module cache.** `GOROOT` and the baked
> `GOPATH` (which holds the pre-installed tools) are read-only. So that
> `go build`/`go test` still work, the build cache, module cache, and any
> `go install` output are redirected onto the writable tmpfs under
> `~/.cache/go` (`GOCACHE`, `GOMODCACHE`, `GOBIN`). They are ephemeral and
> vanish with the disposable container — populate a project's dependencies
> from a committed `go.sum` (the proxy is reachable at runtime unless you
> also drop network).

## Neovim

- Your **own chezmoi-managed Neovim config** is authoritative — cloned and
  applied at build time, then its full plugin set is baked headless so first
  launch needs no network.
- godev drops **one** spec, `nvim/plugins.local/lang.lua`, into your config's
  `plugins.local/` directory (auto-imported via that convention). It wires
  `gopls` through `nvim-lspconfig` pointed at the pre-installed binary on
  `PATH`, with `gofumpt` and `staticcheck` analysis enabled inside `gopls` to
  match the CLI tools.
- Treesitter grammars `go`, `gomod`, `gosum`, `gowork` are added on top of
  whatever your config already installs.
- `gopls` is installed at build time by the toolchain stage, so no LSP
  package manager is needed at runtime and the image stays reproducible.

## Security posture

Enforced by `compose.yaml` (and mirrored in `make run`/`make shell`):

- Runs as non-root `dev` (UID/GID `1000`); no `sudo`, no setuid binaries
  (setuid/setgid bits stripped at build; `/tmp` is `1777`, sticky — not `777`).
- `read_only: true` root filesystem, with tmpfs for `/tmp`,
  `/home/dev/.cache`, `/home/dev/.local/state`.
- `cap_drop: [ALL]`, `security_opt: [no-new-privileges:true]`, `init: true`.
- Resource limits: `pids_limit: 512`, `mem_limit: 4g`, `cpus: 2.0`. The
  memory limit is raised from the langdev default of 2g because Go's
  compiler/linker are memory-hungry on larger modules; lower it if you like.
- The **only** bind mount is your project directory at `/work`.
- Base image pinned by digest; the Go tarball sha256-verified (amd64 +
  arm64, no `curl | sh`); Go tools installed with pinned `…@version`.
- No `.env` is committed or `COPY`'d into an image — secrets are
  runtime-only via compose `env_file`. `.env` is gitignored **and**
  dockerignored. `godev` needs no secrets to build or run.

## Portability

One OCI `Containerfile` builds with `docker build`, `podman build`,
`buildah`, or `nerdctl`, for `linux/amd64` and `linux/arm64`. The official
Go binaries are statically linked and run on Alpine/musl. No host-path
assumptions beyond the `/work` bind mount.

## CI

`.github/workflows/ci.yml` gates every change with `hadolint`,
`shellcheck`, a Docker build, a Trivy scan (fails on HIGH/CRITICAL), and
uploads a CycloneDX SBOM artifact.

## License

MIT — see [`LICENSE`](LICENSE).
