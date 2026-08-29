---
layout: index
title: "godev — Portable, Hardened Go 1.24+ AI Developer Container"
name: "godev"
headline: "Hardened Go 1.24+ Development Container for AI Agents"
lead: "High-throughput Go container preloaded with gopls, golangci-lint, delve debugger, Go 1.24+ toolchain, 4-pane TMUX IDE, and stdio Model Context Protocol (MCP) server."
permalink: "/"
language: "en-GB"
date: "2026-08-29"
description: "High-performance Go container preloaded with gopls, golangci-lint, delve, Go toolchain, 4-pane TMUX IDE, and stdio MCP server."
eyebrow: "Go Stack"
author: "Sebastien Rousseau"
---

<section id="overview" class="section">
  <div class="container text-center">
    <h2 class="section-title">Engineered for Go Developers & Terminal AI Agents</h2>
    <p class="section-desc">High-concurrency Go workflows powered by gopls LSP, golangci-lint, and native MCP container tooling.</p>
    <div class="grid-2x2">
      <div class="card">
        <h3>Go 1.24+ Toolchain</h3>
        <p>Pre-installed with Go official toolchain, <code>gopls</code> language server, <code>golangci-lint</code>, and <code>dlv</code> debugger.</p>
      </div>
      <div class="card">
        <h3>4-Pane TMUX IDE (Prefix + i)</h3>
        <p>Dedicated split layout with File Tree Explorer, Neovim (gopls + Treesitter), bash shell, and AI Agent pane.</p>
      </div>
      <div class="card">
        <h3>Parallel AI Task Worktrees (muxtree)</h3>
        <p>Automate Git worktrees paired with separate TMUX sessions for concurrent multi-agent and human feature branches.</p>
      </div>
      <div class="card">
        <h3>Model Context Protocol (MCP)</h3>
        <p>Stdio JSON-RPC 2.0 interface exposing go test execution, package discovery, and repository diagnostics to Claude Code and Cursor.</p>
      </div>
    </div>
  </div>
</section>

<section id="quickstart" class="section">
  <div class="container narrow">
    <h2 class="section-title text-center">Quick Start in 30 Seconds</h2>
    <p class="section-desc text-center">Disposable developer environment running anywhere Docker or Podman runs.</p>
    <pre><code>&#35; 1. Clone the repository
git clone https://github.com/sebastienrousseau/godev.git
cd godev

&#35; 2. Build and launch 4-pane TMUX IDE
make up

&#35; 3. Mobile WebTTY (port 7681) &amp; Mosh roaming
make web
make mosh</code></pre>
  </div>
</section>

<section id="features" class="section">
  <div class="container text-center">
    <h2 class="section-title">Core Developer Capabilities</h2>
    <p class="section-desc">A terminal-first Go 1.24+ environment with the
      modern CLI tooling already wired up.</p>
    <div class="grid-2x2">
      <div class="card">
        <h3>OSC 52 Universal Clipboard</h3>
        <p>Copy from Neovim or TMUX straight to your local clipboard over
          SSH, WebTTY, or Mosh — no X11 forwarding, no helper daemon.</p>
      </div>
      <div class="card">
        <h3>Floating TUI Modals</h3>
        <p><code>Prefix + g</code> opens Lazygit and <code>Prefix + d</code>
          opens Lazydocker as floating popups over your work, then
          disappear.</p>
      </div>
      <div class="card">
        <h3>Pre-Configured Modern CLI Suite</h3>
        <p>ripgrep, fd, bat, eza, fzf, jq, curl, git and zsh with
          autosuggestions and syntax highlighting, configured on first
          boot.</p>
      </div>
      <div class="card">
        <h3>Deterministic Reproducibility</h3>
        <p>Pinned tool versions, an immutable root filesystem, and
          hermetic builds verified by the CI test suite.</p>
      </div>
    </div>
  </div>
</section>


<section id="ai-ide" class="section">
  <div class="container text-center">
    <h2 class="section-title">AI Coding Agent Architecture</h2>
    <p class="section-desc">Press <code>Prefix + i</code> for a four-pane
      TMUX workspace: explorer, editor, shell, and a dedicated AI agent
      terminal, laid out in the proportions below.</p>
    <div class="ide-layout">
      <div class="ide-pane ide-explorer">
        <h3>Left Panel (20% W)</h3>
        <p>Intelligent project explorer (<code>langdev-explorer</code>, <code>yazi</code>) with visual Git branch status.</p>
      </div>
      <div class="ide-center">
        <div class="ide-pane ide-editor">
          <h3>Center-Top (56% W, 70% H)</h3>
          <p>Editor pane loaded with Neovim and <code>gopls</code>.</p>
        </div>
        <div class="ide-pane ide-terminal">
          <h3>Center-Bottom (56% W, 30% H)</h3>
          <p>Integrated bash terminal with Go toolchain on PATH.</p>
        </div>
      </div>
      <div class="ide-pane ide-agent">
        <h3>Right Panel (24% W)</h3>
        <p>Dedicated AI Agent terminal (Claude Code, Agy, Aider, Ollama).</p>
      </div>
    </div>
    <p class="ide-caption">Every pane is a real TMUX pane — detach,
      resize, or drive it from a script like any other session.</p>
    <div class="grid-2x2">
      <div class="card">
        <h3>Parallel AI Task Worktrees (<code>muxtree</code>)</h3>
        <p>Spawn an ephemeral Git worktree paired with its own TMUX
          session, so an agent can work a branch without touching your
          working tree.</p>
      </div>
      <div class="card">
        <h3>Model Context Protocol (MCP) Server</h3>
        <p>A stdio JSON-RPC 2.0 server exposing file reads, search, shell
          execution and diagnostics to Claude Code, Cursor, and any other
          MCP client.</p>
      </div>
      <div class="card">
        <h3>Context Packing (<code>ai-pack</code>)</h3>
        <p>Pack a whole repository into a token-efficient XML or Markdown
          prompt context, with no external dependencies.</p>
      </div>
      <div class="card">
        <h3>Zero-Trust Capability Drop</h3>
        <p>Runs unprivileged (UID 1000) with all root capabilities
          dropped (<code>cap_drop: [ALL]</code>) and a read-only root
          filesystem.</p>
      </div>
    </div>
  </div>
</section>

<section id="suite" class="section">
  <div class="container">
    <h2 class="section-title text-center">Unified Multi-Language Suite</h2>
    <p class="section-desc text-center">Every container shares an identical security baseline, TMUX shortcuts, and MCP interfaces.</p>
    <div class="table-responsive">
      <table>
        <thead>
          <tr>
            <th scope="col">Container</th>
            <th scope="col">Language Stack</th>
            <th scope="col">Built-in Tooling</th>
            <th scope="col">Version</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><a href="https://sebastienrousseau.com/langdev/" class="suite-link"><strong>langdev</strong></a></td>
            <td>Core Foundation</td>
            <td>TMUX IDE, MCP server, ai-pack, WebTTY, OSC 52</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><a href="https://sebastienrousseau.com/pythondev/" class="suite-link"><strong>pythondev</strong></a></td>
            <td>Python 3.12+</td>
            <td>uv, ruff, mypy, pytest, debugpy, Pyright</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><a href="https://sebastienrousseau.com/rustdev/" class="suite-link"><strong>rustdev</strong></a></td>
            <td>Rust 1.85+</td>
            <td>rustup, rust-analyzer, clippy, cargo-audit, sccache</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><a href="https://sebastienrousseau.com/godev/" class="suite-link"><strong>godev</strong></a></td>
            <td>Go 1.24+</td>
            <td>gopls, golangci-lint, delve, Go toolchain</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><a href="https://sebastienrousseau.com/javadev/" class="suite-link"><strong>javadev</strong></a></td>
            <td>Java 21+</td>
            <td>OpenJDK 21, Maven, Gradle, JDTLS</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><a href="https://sebastienrousseau.com/kotlindev/" class="suite-link"><strong>kotlindev</strong></a></td>
            <td>Kotlin 2.1+</td>
            <td>kotlinc, OpenJDK 21, Gradle, Maven, KLS</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><a href="https://sebastienrousseau.com/swiftdev/" class="suite-link"><strong>swiftdev</strong></a></td>
            <td>Swift 6.0+</td>
            <td>Swift toolchain, SourceKit-LSP, swift-format</td>
            <td>v0.0.4</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</section>

<section id="security" class="section">
  <div class="container text-center">
    <h2 class="section-title">Zero-Trust Hardened Security</h2>
    <p class="section-desc">Strict security guarantees verified in CI and container runtime.</p>
    <div class="grid-2x2">
      <div class="card">
        <h3>Unprivileged Non-Root</h3>
        <p>Runs as unprivileged dev user (UID/GID 1000). Drops all Linux capabilities (<code>cap_drop: [ALL]</code>) with <code>no-new-privileges:true</code>.</p>
      </div>
      <div class="card">
        <h3>Read-Only Root Filesystem</h3>
        <p>Immutable rootfs prevents container modification or persistent malware. Writable state is restricted to explicit tmpfs mounts.</p>
      </div>
      <div class="card">
        <h3>Supply Chain Integrity</h3>
        <p>Base images pinned to cryptographic SHA256 digests. Zero unpinned curl-to-sh scripts. Automated CycloneDX SBOM generation.</p>
      </div>
      <div class="card">
        <h3>Hermetic CI & SAST</h3>
        <p>100% unit tested with Bats, ShellCheck linting, Hadolint OCI auditing, and Trivy CVE vulnerability scans.</p>
      </div>
    </div>
  </div>
</section>

<section id="faq" class="section">
  <div class="container narrow">
    <h2 class="section-title text-center">Frequently Asked Questions</h2>
    <div class="faq-stack">
      <div class="card">
        <h3>Are GOCACHE and GOMODCACHE preserved?</h3>
        <p>Yes. Configurable volume mounts support persisting the Go module cache across container runs.</p>
      </div>
      <div class="card">
        <h3>How fast is the container cold start?</h3>
        <p>Under 500 milliseconds. All Go toolchain binaries and Neovim plugins are pre-baked.</p>
      </div>
    </div>
  </div>
</section>
