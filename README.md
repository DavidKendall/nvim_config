# Neovim config

A small, native-first, boring Neovim setup. It leans on Neovim ≥ 0.11's built-in
LSP client (`vim.lsp.config` / `vim.lsp.enable`), so server configuration lives in
`lsp/*.lua` and no Mason layer is needed. Plugins exist only for genuine gaps:
completion (blink.cmp), fuzzy finding/explorer/statusline (snacks.nvim), theme
(catppuccin), formatting (conform.nvim), git signs, which-key, treesitter, and
Lean. There is no distribution, no base46, and no abstraction layer.

## Requirements

- **Neovim ≥ 0.11** (native `lsp/` runtime directory and `vim.lsp.enable`).
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
needed. If you are migrating from an NvChad setup, remove its stale caches first:

```sh
rm -rf "$(nvim --headless -c 'print(stdpath("data"))' -c q)/nvchad"
```

## Layout

```
init.lua            leaders, lazy.nvim bootstrap, config imports
lua/config/         options, keymaps, autocmds
lua/plugins/        one file per concern, returns lazy.nvim specs
lsp/                native server configs (auto-loaded, no require)
tests/              headless smoke + tool report
sample/             minimal fixtures for manual checks
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
| `<leader>tb` | n | `:TexlabBuild` |
| `<leader>lf` | n | format buffer (conform) |
| `gd` / `gD` / `K` | n | definition / declaration / hover |
| `grn` / `grr` / `gri` / `gra` | n | rename / references / implementation / code action (native 0.11) |
| `]h` / `[h` | n | next / previous git hunk |
| `<leader>hs` / `hr` / `hp` / `hb` | n | stage / reset / preview / blame hunk |

Formatting is manual only (`format_on_save` is intentionally off).

## Tests

```sh
nvim --headless -l tests/smoke.lua       # assertions; exits 1 on failure
nvim --headless -l tests/check_tools.lua # binary report; always exits 0
stylua --check .
```

`tests/smoke.lua` test 8 is skipped until treesitter parsers are installed.
The Julia and LaTeX stacks have manual checks described in `PLAN.md`; open
`sample/juliaproj/test.jl` and `sample/test.tex` to exercise them.
