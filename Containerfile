# syntax=docker/dockerfile:1.9
# langdev Containerfile template — OCI, builds with Docker AND Podman.
# SPDX-License-Identifier: MIT
#
# Multi-stage, hardened, ultra-small base for <language>dev images.
# A language repo fills in the `toolchain` stage and copies its LSP
# binaries + nvim/plugins/lang.lua. Everything below the "COMMON BASE"
# banner is identical across the suite (kept in sync via `make sync-common`).
#
# Pin the base by DIGEST. Update via `make bump-base` (looks up the
# current digest for the tag and rewrites the two lines below).
ARG ALPINE_VERSION=3.22
# renovate: datasource=docker depName=alpine
ARG ALPINE_DIGEST=sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

###############################################################################
# Stage: toolchain  (LANGUAGE-SPECIFIC — Go via the official toolchain)
#   Downloads the checksum-verified official Go distribution (amd64 + arm64)
#   into a relocatable GOROOT, then `go install`s the pinned Go tools we ship
#   (gopls, dlv, staticcheck, gofumpt) straight into GOPATH/bin. Everything
#   lands under a single relocatable prefix (/opt/langdev/toolchain) that the
#   final stage copies in — no build tools or caches leak into the runtime.
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS toolchain

# Pinned, checksum-verified toolchain inputs. Bump together (see README).
ARG GO_VERSION=1.27.0
ARG GOPLS_VERSION=v0.23.0
ARG DELVE_VERSION=v1.27.1
ARG STATICCHECK_VERSION=2026.2.1
ARG GOFUMPT_VERSION=v0.11.0

# Relocatable prefix: GOROOT (the official toolchain) and GOPATH (installed
# tools' bin) live side by side so the final stage can COPY the whole tree and
# get a working toolchain on PATH. GOTOOLCHAIN=local pins to the baked release;
# CGO_ENABLED=0 yields static tool binaries (no C toolchain needed).
ENV GOROOT=/opt/langdev/toolchain/go \
    GOPATH=/opt/langdev/toolchain/gopath \
    GOTOOLCHAIN=local \
    CGO_ENABLED=0 \
    PATH=/opt/langdev/toolchain/go/bin:/opt/langdev/toolchain/gopath/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Build-only packages (curl to fetch the tarball, git for module fetches).
# These stay in the toolchain stage and never reach the runtime image.
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      git \
 && update-ca-certificates

# Install the official Go toolchain with a verified sha256 (no `curl | sh`).
# The official Go binaries are statically linked and run on Alpine/musl.
RUN set -eux; \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
      x86_64)  goArch='amd64'; \
               goSha256='675c26c449cbb18fc24b74650de1eabbae6e16f64326fd85a283fb3b58280685' ;; \
      aarch64) goArch='arm64'; \
               goSha256='51798d2c42d0e1c6ed7fd9f48728b4193abac9e8aad6dbac2fe96a81f5909bda' ;; \
      *) echo >&2 "unsupported architecture: $apkArch"; exit 1 ;; \
    esac; \
    url="https://go.dev/dl/go${GO_VERSION}.linux-${goArch}.tar.gz"; \
    curl -fsSL "$url" -o /tmp/go.tar.gz; \
    echo "${goSha256}  /tmp/go.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/langdev/toolchain; \
    tar -C /opt/langdev/toolchain -xzf /tmp/go.tar.gz; \
    rm -f /tmp/go.tar.gz; \
    go version

# Pinned Go tools installed straight into GOPATH/bin (static, CGO disabled).
# Build + module caches are scratch and stripped afterwards, so only the tool
# binaries (GOPATH/bin) and GOROOT survive into the `final` stage.
RUN set -eux; \
    export GOCACHE=/tmp/gocache GOMODCACHE=/tmp/gomodcache; \
    go install "golang.org/x/tools/gopls@${GOPLS_VERSION}"; \
    go install "github.com/go-delve/delve/cmd/dlv@${DELVE_VERSION}"; \
    go install "honnef.co/go/tools/cmd/staticcheck@${STATICCHECK_VERSION}"; \
    go install "mvdan.cc/gofumpt@${GOFUMPT_VERSION}"; \
    rm -rf /tmp/gocache /tmp/gomodcache "${GOPATH}/pkg"; \
    gopls version; \
    dlv version; \
    staticcheck --version; \
    gofumpt --version

###############################################################################
# Stage: nvim-build  (COMMON — bakes the editor + plugins into the image)
#   Runs Neovim headless to install the exact plugin set from lazy-lock.json,
#   so the runtime image needs NO network on first launch.
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS nvim-build
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash ca-certificates curl git \
      neovim ripgrep fd \
      build-base cmake
# LazyVim starter pinned to a commit (reproducible); overridable at build.
ARG LAZYVIM_STARTER_REF=c31e5cc9f77b16d20a693c30f28fdf907f1caf95
ENV XDG_CONFIG_HOME=/root/.config \
    XDG_DATA_HOME=/root/.local/share \
    XDG_STATE_HOME=/root/.local/state \
    XDG_CACHE_HOME=/root/.cache
RUN git clone --filter=blob:none https://github.com/LazyVim/starter /root/.config/nvim \
 && git -C /root/.config/nvim checkout "${LAZYVIM_STARTER_REF}" \
 && rm -rf /root/.config/nvim/.git
# Common + language plugin specs (language repo adds lang.lua before build).
COPY common/nvim/plugins/ /root/.config/nvim/lua/plugins/
COPY nvim/plugins/ /root/.config/nvim/lua/plugins/
# Reproducible plugin set: restore from committed lockfile, then sync.
COPY nvim/lazy-lock.json /root/.config/nvim/lazy-lock.json
RUN nvim --headless "+Lazy! restore" +qa 2>&1 | tail -n 5 || true \
 && nvim --headless "+TSUpdateSync" +qa 2>&1 | tail -n 5 || true

###############################################################################
#                              COMMON BASE
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS base

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

LABEL org.opencontainers.image.title="langdev" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="Sebastien Rousseau"

# Minimal, pinned runtime. `tini` is the init (compose sets init:true, but
# shipping it keeps `docker run` correct too). Versions are pinned by the
# digest-locked Alpine repository for this release.
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      git \
      less \
      neovim \
      ripgrep \
      fd \
      tini \
      tzdata \
 && update-ca-certificates

# Non-root user with a real home.
RUN addgroup -g "${USER_GID}" "${USERNAME}" \
 && adduser -D -u "${USER_UID}" -G "${USERNAME}" -s /bin/bash "${USERNAME}"

# Portable dotfiles.
COPY --chown=${USER_UID}:${USER_GID} common/dotfiles/bashrc        /home/${USERNAME}/.bashrc
COPY --chown=${USER_UID}:${USER_GID} common/dotfiles/bash_profile  /home/${USERNAME}/.bash_profile
COPY --chown=${USER_UID}:${USER_GID} common/dotfiles/bash_aliases  /home/${USERNAME}/.bash_aliases

# Editor + baked-in plugins from the nvim-build stage.
COPY --from=nvim-build --chown=${USER_UID}:${USER_GID} /root/.config/nvim /home/${USERNAME}/.config/nvim
COPY --from=nvim-build --chown=${USER_UID}:${USER_GID} /root/.local/share/nvim /home/${USERNAME}/.local/share/nvim

# Entrypoint.
COPY common/entrypoint.sh /usr/local/bin/langdev-entrypoint
RUN chmod 0755 /usr/local/bin/langdev-entrypoint \
 && mkdir -p /usr/local/lib/langdev

# --- Hardening ---------------------------------------------------------------
# Sticky bit preserved (1777, NOT 777). Remove any setuid/setgid bits so no
# privilege escalation vector survives. No `chattr` theatre (no-op in a
# container). No account-lock theatre — we simply run as an unprivileged user.
RUN chmod 1777 /tmp \
 && find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -exec chmod -s {} + 2>/dev/null || true

USER ${USERNAME}
WORKDIR /work
ENV HOME=/home/${USERNAME} \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    EDITOR=nvim \
    XDG_CONFIG_HOME=/home/${USERNAME}/.config \
    XDG_DATA_HOME=/home/${USERNAME}/.local/share \
    XDG_STATE_HOME=/home/${USERNAME}/.local/state \
    XDG_CACHE_HOME=/home/${USERNAME}/.cache

# Cheap, honest liveness probe (no full-FS scans).
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD nvim --version >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/local/bin/langdev-entrypoint"]

###############################################################################
# Stage: final  (Go runtime — tiny: toolchain artifacts only, no build tools)
#   Copies the relocatable Go prefix (GOROOT + the pinned tools' GOPATH/bin)
#   from the toolchain stage and drops the language shell fragment. No curl,
#   build-base, or module caches here.
###############################################################################
FROM base AS final

# Relocatable Go toolchain + pinned tools built & checksum-verified above.
COPY --from=toolchain --chown=1000:1000 /opt/langdev/toolchain /opt/langdev/toolchain

# Language shell fragment: sets GOROOT/GOPATH/GOBIN/PATH + a few aliases and
# redirects the build/module caches onto the writable tmpfs (see README).
COPY --chown=1000:1000 dotfiles.d/go.sh /home/dev/.bashrc.d/go.sh

# go, gofmt, gopls, dlv, staticcheck, gofumpt are all on PATH. Build/module
# caches default onto the tmpfs-backed ~/.cache so `go build`/`go test` work on
# the read-only rootfs; GOFLAGS/GOTOOLCHAIN keep builds reproducible.
ENV GOROOT=/opt/langdev/toolchain/go \
    GOPATH=/opt/langdev/toolchain/gopath \
    GOTOOLCHAIN=local \
    GOFLAGS=-mod=readonly \
    GOCACHE=/home/dev/.cache/go/build \
    GOMODCACHE=/home/dev/.cache/go/mod \
    GOBIN=/home/dev/.cache/go/bin \
    PATH=/opt/langdev/toolchain/go/bin:/opt/langdev/toolchain/gopath/bin:/home/dev/.cache/go/bin:/home/dev/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
