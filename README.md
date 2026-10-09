# Neovim config

A small, native-first, boring Neovim setup. It leans on Neovim ≥ 0.11's built-in
LSP client (`vim.lsp.config` / `vim.lsp.enable`), so server configuration lives in
`after/lsp/*.lua` and no Mason layer is needed. Plugins exist only for genuine
gaps: completion (blink.cmp), fuzzy finding/explorer (snacks.nvim), statusline
(lualine) and icons (nvim-web-devicons), theme (catppuccin), formatting
(conform.nvim), git signs, which-key, treesitter, and Lean. There is no
distribution, no base46, and no abstraction layer.

## Requirements

- **Neovim ≥ 0.11** (native `after/lsp/` runtime directory and `vim.lsp.enable`).
- The binaries below on `PATH`. Run `nvim --headless -l tests/check_tools.lua`
  for a report; missing tools are documented, not auto-installed.

| Binary | Needed by | Suggested install |
|--------|-----------|-------------------|
| `julia` | `julials` (LanguageServer.jl) | [juliaup](https://github.com/JuliaLang/juliaup) |
| `texlab` | LaTeX LSP | package manager, or [releases](https://github.com/latex-lsp/texlab/releases) |
| `tectonic` | `texlab` build (`<leader>tb`) | [tectonic installer](https://tectonic-typesetting.github.io/) |
| `qpdfview` | `texlab` forward search | package manager |
| `latexindent` | LaTeX formatting | TeX distribution |
| `lua-language-server` | `lua_ls` | package manager, or [releases](https://github.com/LuaLS/lua-language-server/releases) |
| `stylua` | Lua formatting | `cargo install stylua`, or [releases](https://github.com/JohnnyMorganz/StyLua/releases) |
| `rust-analyzer` | Rust LSP | `rustup component add rust-analyzer` |
| `kotlin-language-server` | Kotlin LSP | package manager, or [releases](https://github.com/kotlin-language-server/language-server/releases) |
| `git` | gitsigns, lazy.nvim bootstrap | package manager |
| `tree-sitter` CLI | compiling parsers (`:TSUpdate`) | `cargo install tree-sitter-cli` |

## First run

lazy.nvim bootstraps itself and installs plugins on first launch
(`install.colorscheme` falls back to catppuccin). Run `:Lazy sync` once if
needed. Treesitter parsers are installed automatically at startup
(`require("nvim-treesitter").install`) and require the `tree-sitter` CLI. If you
are migrating from an NvChad setup, remove its stale caches first:

```sh
rm -rf "$(nvim --headless -c 'print(stdpath("data"))' -c q)/nvchad"
```

If you previously used an older nvim-treesitter (`main` branch changed its
parser install location), remove the stale parsers in the plugin directory so
they stop shadowing Neovim's bundled parsers:

```sh
rm -rf ~/.local/share/nvim/lazy/nvim-treesitter/parser
```

Leftover `vim.pack` packages from an earlier experiment trigger warnings in
`:checkhealth lazy`/`:checkhealth vim.pack`; the config no longer creates that
directory (catppuccin auto-integration detection used to, via `vim.pack.get`).
Remove a stale one if present:

```sh
rm -rf ~/.local/share/nvim/site/pack/core ~/.config/nvim/nvim-pack-lock.json
```

## Layout

```
init.lua            leaders, lazy.nvim bootstrap, config imports
lua/config/         options, keymaps, autocmds
lua/plugins/        one file per concern, returns lazy.nvim specs
after/lsp/          native server configs (auto-loaded, no require)
after/ftplugin/     buffer-local tweaks (Julia 4-space indent)
tests/              headless smoke + tool report
sample/             minimal fixtures for manual checks
```

Server overrides live in `after/lsp/`, not `lsp/`. lazy.nvim resets
`runtimepath` with the config dir *before* plugin dirs, and Neovim merges
`lsp/{name}.lua` files with later runtimepath entries taking precedence — so a
top-level `lsp/` would be clobbered by nvim-lspconfig's shipped defaults. The
`after/` entry is always last, so these files win.

Julia note: the julials command is overridden for LanguageServer.jl **v6**
(which bundles SymbolServer/StaticLint). Install it with:

```sh
julia --project=~/.julia/environments/nvim-lspconfig -e 'using Pkg; Pkg.add("LanguageServer")'
```

## Keymaps

| Chord | Mode | Action |
|-------|------|--------|
| `jk` | i | exit insert mode |
| `;` | n | command mode (disables native `;` repeat-motion) |
| `<leader>w` / `<leader>q` | n | write / quit |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | n | window navigation |
| `<leader>e` | n | toggle file explorer |
| `<leader>ff` / `fg` / `fb` / `fr` / `fs` | n | find files / grep / buffers / recent / document symbols |
| `<leader>km` | n | pick keymaps |
| `<leader>tb` | n | texlab build (`LspTexlabBuild`) |
| `<leader>lf` | n | format buffer (conform) |
| `gd` / `gD` / `K` | n | definition / declaration / hover |
| `grn` / `grr` / `gri` / `gra` | n | rename / references / implementation / code action (native 0.11) |
| `]h` / `[h` | n | next / previous git hunk |
| `<leader>hs` / `hr` / `hp` / `hb` | n | stage / reset / preview / blame hunk |
| `<Esc><Esc>` | t | exit terminal mode (single `<Esc>` reaches the program) |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | t | terminal-mode window navigation |

Formatting is manual only (`format_on_save` is intentionally off). Julia uses
4-space indentation via `after/ftplugin/julia.lua`; everything else is 2-space.

`:terminal` opens in Terminal-Job mode (type immediately) and terminal buffers
get clean local options (no line numbers, sign column, or `colorcolumn`).

## Tests

```sh
nvim --headless -l tests/smoke.lua       # assertions; exits 1 on failure
nvim --headless -l tests/check_tools.lua # binary report; always exits 0
stylua --check .
```

`tests/smoke.lua` test 8 is skipped until treesitter parsers are installed.
The Julia and LaTeX stacks have manual checks described in `PLAN.md`; open
`sample/juliaproj/test.jl` and `sample/test.tex` to exercise them.

## Troubleshooting

**`Invalid node type "tab"` when opening a picker (e.g. `<leader>km`)** — a
tree-sitter parser no longer matches the queries bundled with your Neovim
(common after a Neovim upgrade). Most often a stale parser from an older
nvim-treesitter is shadowing Neovim's bundled one; remove it and let the
startup install recreate parsers in the current location:

```sh
rm -rf ~/.local/share/nvim/lazy/nvim-treesitter/parser
nvim --headless "+TSInstall vim lua vimdoc" +qa   # or just restart nvim
```

Check `:checkhealth vim.treesitter` and `:checkhealth nvim-treesitter` to
confirm the parsers come from the expected paths. As a safety net, the snacks
picker degrades to unhighlighted entries instead of erroring when a query
cannot be compiled.

