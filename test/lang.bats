#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for dotfiles.d/go.sh — the Go language profile fragment installed
# to /etc/profile.d and sourced by login shells. The fragment exports the Go
# toolchain env (GOROOT/GOPATH, read-only build flags, tmpfs-backed caches) and
# prepends the toolchain bins to PATH (guarded, so it is safe to re-source).
# These tests source it in a hermetic sandbox and assert it sets that
# environment without error and is idempotent.
load helpers/common

setup() { common_setup; }

SCRIPT="dotfiles.d/go.sh"

@test "go.sh: sets the toolchain env and prepends the Go bins to PATH" {
  run bash -c '
    set -euo pipefail
    export PATH="/langdev-base"
    # shellcheck source=/dev/null
    source "$1"
    printf "GOROOT=%s\n" "$GOROOT"
    printf "GOPATH=%s\n" "$GOPATH"
    printf "GOFLAGS=%s\n" "$GOFLAGS"
    printf "GOTOOLCHAIN=%s\n" "$GOTOOLCHAIN"
    printf "PATHVAL=%s\n" "$PATH"
  ' _ "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"GOROOT=/opt/langdev/toolchain/go"* ]]
  [[ "$output" == *"GOPATH=/opt/langdev/toolchain/gopath"* ]]
  [[ "$output" == *"GOFLAGS=-mod=readonly"* ]]
  [[ "$output" == *"GOTOOLCHAIN=local"* ]]
  [[ "$output" == *"/opt/langdev/toolchain/go/bin"* ]]
}

@test "go.sh: is idempotent — re-sourcing does not duplicate the PATH entry" {
  run bash -c '
    set -euo pipefail
    export PATH="/langdev-base"
    source "$1"; source "$1"
    printf "PATHVAL=%s" "$PATH"
  ' _ "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  pathval="${output#PATHVAL=}"
  n="$(printf '%s' "$pathval" | grep -oF '/opt/langdev/toolchain/go/bin' | wc -l)"
  [ "$n" -eq 1 ]
}
