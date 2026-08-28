# ~/.bashrc.d/go.sh — Go language fragment (godev)
# SPDX-License-Identifier: MIT
#
# Sourced by the common ~/.bashrc for interactive shells. Sets the Go
# environment for the pre-installed, relocatable toolchain and adds a few
# aliases ONLY for tools that are actually installed in the image
# (go build/test/vet, gofumpt, staticcheck). No host PATH is propagated.

# Relocatable toolchain prefix baked in at build time.
#   GOROOT   — the official Go distribution.
#   GOPATH   — holds the pre-installed tools' bin (gopls, dlv, staticcheck,
#              gofumpt). It is read-only (part of the baked image), so builds
#              must not write here.
export GOROOT=/opt/langdev/toolchain/go
export GOPATH=/opt/langdev/toolchain/gopath

# The rootfs is read-only; keep the build cache, module cache, and any
# `go install` output on the writable tmpfs (~/.cache) so `go build`/`go test`
# work — and vanish with the disposable container.
export GOCACHE="${XDG_CACHE_HOME:-$HOME/.cache}/go/build"
export GOMODCACHE="${XDG_CACHE_HOME:-$HOME/.cache}/go/mod"
export GOBIN="${XDG_CACHE_HOME:-$HOME/.cache}/go/bin"

# Reproducibility: never mutate go.mod/go.sum implicitly, and never auto-fetch
# a different toolchain over the network — always use the baked release.
export GOFLAGS=-mod=readonly
export GOTOOLCHAIN=local

# Put go/gofmt, the baked tools, then this session's GOBIN on PATH without
# clobbering the existing PATH.
for __d in "${GOROOT}/bin" "${GOPATH}/bin" "${GOBIN}"; do
  case ":${PATH}:" in
    *":${__d}:"*) ;;
    *) export PATH="${__d}:${PATH}" ;;
  esac
done
unset __d

# --- Aliases (only for tools present in the image) ---------------------------
alias gob='go build ./...'
alias got='go test ./...'
alias gov='go vet ./...'
alias gor='go run .'
alias gofm='gofumpt -l -w .'
alias golint='staticcheck ./...'
