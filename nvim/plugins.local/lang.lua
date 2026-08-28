-- godev — Go language wiring for Neovim (langdev lang.lua)
-- SPDX-License-Identifier: Apache-2.0 OR MIT
--
-- Dropped into the user's chezmoi-managed Neovim config via its
-- `plugins.local` convention (auto-imported), so the dotfiles stay pristine
-- and langdev-agnostic. Baked headless at build time — no network on first
-- launch, fully reproducible.
--
-- gopls is installed at BUILD time by the toolchain stage (`go install`) and
-- lives on PATH at /opt/langdev/toolchain/gopath/bin, so Mason is unnecessary.
-- We wire gopls through nvim-lspconfig's `servers` table pointed at the
-- pre-installed binary, and enable gofumpt + staticcheck analysis inside gopls
-- so formatting/linting match the shipped CLI tools.
return {
  -- Treesitter grammars for Go + its module/workspace files.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "go", "gomod", "gosum", "gowork" })
    end,
  },

  -- gopls via nvim-lspconfig, pointed at the build-time binary on PATH.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          -- Use the pre-installed gopls (Mason disabled).
          cmd = { "gopls" },
          settings = {
            gopls = {
              -- Match the shipped CLI formatter/linter.
              gofumpt = true,
              staticcheck = true,
              analyses = {
                unusedparams = true,
                unusedwrite = true,
                nilness = true,
                useany = true,
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
            },
          },
        },
      },
    },
  },
}
