# Handover: from the NvChad config (`../nvim_config`) to this config

This document is for someone who has been using the NvChad-based config in
`../nvim_config` and needs to get productive in this one. It covers what
stayed the same, what changed structurally, plugin swaps, keymap changes,
migration steps, and where to look for more information.

---

## 1. The big picture

| | Old (`../nvim_config`) | New (this repo) |
|---|---|---|
| Base | **NvChad v2.5** distribution | Hand-written, "native-first", no distribution |
| Theme engine | base46 + NvChad themes | [catppuccin/nvim](https://github.com/catppuccin/nvim) |
| Completion | nvim-cmp (+ cmp-latex-symbols) | **blink.cmp** (nvim-cmp is in maintenance mode) |
| Fuzzy finding / explorer / statusline | Telescope / NvimTree / NvChad statusline | **snacks.nvim** (picker + explorer + notifier) + **lualine.nvim** (statusline) + **nvim-web-devicons** |
| LSP setup | nvim-lspconfig + `vim.lsp.config` wired through NvChad's helpers | nvim-lspconfig + **native Neovim 0.11** `vim.lsp.enable`; server overrides in `after/lsp/*.lua` |
| Tool installation | **Mason** (`ensure_installed`) | **None.** All binaries must be on `PATH` already |
| Keymaps | NvChad defaults + a few personal ones | Small explicit set in `lua/config/keymaps.lua` |
| Minimum Neovim | 0.9-ish | **0.11 or newer** (required) |

The philosophy here is: Neovim built-ins first, plugins only where there is a
genuine gap, no abstraction layer. If you want to know why something exists,
each file in `lua/plugins/` answers "why is this here".

## 2. What is unchanged (your muscle memory is safe)

These are preserved **verbatim** from the old config:

- **Leaders**: `<leader>` = space, `<localleader>` = space.
- `jk` in insert mode → `<Esc>`.
- `;` in normal mode → `:` (command mode). Note this still disables the
  native `;` repeat-`f`/`t` motion, exactly as before.
- `<leader>tb` → texlab build (invokes `LspTexlabBuild` when texlab is attached).
- `<leader>km` → keymap picker (now snacks picker instead of Telescope).
- Options: `clipboard = "unnamedplus"`, `colorcolumn = 92`,
  `spelllang = "en_gb"`.
- LSP behaviour for Julia and LaTeX is ported bit-for-bit:
  - **julials**: root detection via `Project.toml`/`JuliaProject.toml`,
    lint-on-type, `missingrefs = "none"`, symbol cache download, and the
    `UnusedBinding` diagnostic filter (see `after/lsp/julials.lua`). The
    command is overridden for LanguageServer.jl **v6**, which dropped
    `SymbolServer`/`StaticLint` and the `julia/activateenvironment` method.
  - **texlab**: tectonic build with `--synctex --keep-logs
    --keep-intermediates`, forward search via `qpdfview` after build,
    latexindent formatting, chktex deliberately off (see
    `after/lsp/texlab.lua`).
- Completion of LaTeX symbols with the **mixed strategy** (typing `\alp`
  offers both `\alpha` and `α`).
- Formatting is **manual only** (`format_on_save` intentionally off).
- Language coverage: Julia, LaTeX, Lua, Rust, Kotlin, HTML, CSS, Lean, plus
  treesitter for vim/lua/vimdoc/html/css/kotlin/julia/rust/latex/markdown/regex.
- Julia uses 4-space indentation (`after/ftplugin/julia.lua`); everything else
  is 2-space.

## 3. Plugin changes

| Concern | Old | New |
|---|---|---|
| Distribution | NvChad v2.5 (base46, nvchad plugins) | Removed entirely |
| Completion | hrsh7th/nvim-cmp + kdheepak/cmp-latex-symbols | saghen/blink.cmp + saghen/blink.compat + kdheepak/cmp-latex-symbols (same LaTeX source, bridged via blink.compat) |
| Fuzzy finder | Telescope (via NvChad) | folke/snacks.nvim `picker` |
| File explorer | nvim-tree.lua | snacks.nvim `explorer` |
| Statusline | NvChad/base46 statusline | nvim-lualine/lualine.nvim (+ nvim-web-devicons) |
| UI niceties | NvChad nvcheatsheet, tabufline, themes | snacks.nvim notifier/indent/input/quickfile/bigfile |
| Theme | NvChad base46 | catppuccin/nvim |
| Git | none | lewis6991/gitsigns.nvim (new capability) |
| Keymap help | which-key via NvChad | folke/which-key.nvim |
| Formatting | stevearc/conform.nvim | stevearc/conform.nvim (same config, plus `tex` via LSP) |
| LSP plumbing | nvim-lspconfig + williamboman/mason.nvim | nvim-lspconfig only; overrides in `after/lsp/*.lua` |
| Treesitter | nvim-treesitter (branch `main`) | same, plus `rust`, `latex`, `markdown`, `markdown_inline`, `regex`; installed explicitly at startup |
| Lean | Julian/lean.nvim + plenary.nvim | same (now anchored on `ft = "lean"`) |

**Mason is gone.** Nothing is auto-installed. The required binaries are
`julia`, `texlab`, `tectonic`, `qpdfview`, `latexindent`,
`lua-language-server`, `stylua`, `rust-analyzer`,
`kotlin-language-server`, `git`, the `tree-sitter` CLI, and `lazygit`
(optional, for `<leader>gg`). Run

```sh
nvim --headless -l tests/check_tools.lua
```

for a report of what is missing; the README documents where to get each one.

**Julia LSP install** (as before, LanguageServer.jl v6 in a dedicated env):

```sh
julia --project=~/.julia/environments/nvim-lspconfig -e 'using Pkg; Pkg.add("LanguageServer")'
```

## 4. Keymap changes

Your four personal chords are identical. The rest of the surface is smaller
and different in places.

### Changed / moved

| Chord | Old (NvChad) | New |
|---|---|---|
| `<leader>ff` | find files (Telescope) | find files (snacks picker) — same intent |
| `<leader>fg` | *(not a NvChad default)* | **grep files** (was `<leader>fw` in NvChad) |
| `<leader>fb` | buffers | buffers — same |
| `<leader>fr` | *(NvChad used `<leader>fo` for oldfiles)* | recent files |
| `<leader>fs` | *(NvChad used `<leader>ls` family for LSP symbols)* | document symbols |
| `<leader>e` | NvimTree focus | toggle snacks explorer |
| `<leader>w` / `<leader>q` | *(NvChad used these for LSP workspace folders)* | **write / quit** (now shadows those LSP chords) |
| `<leader>lf` | *(NvChad's format key was `<leader>fm`)* | format buffer (conform) |
| `gd` / `gD` / `K` | definition / declaration / hover (NvChad maps) | same, but explicit in `keymaps.lua` |
| rename / references / implementation / code actions | NvChad chords (`<leader>rn`, `gr`, `<leader>ra`, `gi`) | **native Neovim 0.11 defaults**: `grn`, `grr`, `gri`, `gra` — not remapped |

### Gone (NvChad conveniences with no replacement)

- NvChad **tabufline** and its `<Tab>`/`<S-Tab>`/`<leader>x` buffer tabs and
  close-buffer mappings — use native buffer commands or `<leader>fb` +
  picker. (Consider adding `<leader>bd` etc. if you miss it.)
- `<C-n>` NvimTree toggle → use `<leader>e`.
- NvChad terminal toggles (`<A-i>`, `<A-h>`, etc.) → use native `:terminal`
  (or add a snippet if you want).
- `:NvChadThemes` / `<leader>th` theme switcher, nvcheatsheet, dashboard —
  catppuccin is set once in `lua/plugins/editor.lua`; switch flavours there.
- Telescope-specific pickers (git status/commits, marks, help tags...) —
  snacks.nvim has equivalents via `require("snacks").picker.*`; they are not
  all mapped yet.

### New

- `<C-h>/<C-j>/<C-k>/<C-l>` — window navigation.
- `]h` / `[h` — next/previous git hunk.
- `<leader>hs` / `<leader>hr` / `<leader>hp` / `<leader>hb` — stage / reset /
  preview / blame hunk (gitsigns).
- `<leader>w` / `<leader>q` — write / quit.
- `<leader>gg` — open lazygit (git TUI; needs the `lazygit` binary on `PATH`).
- Yank highlighting via a `TextYankPost` autocmd (`vim.hl.on_yank()`).

Every mapping carries a `desc`, so `<leader>km` (or which-key) shows the full
authoritative list at any time.

## 5. Structural differences (where things live)

```
Old                                 New
init.lua (NvChad bootstrap)         init.lua (~20 lines, lazy bootstrap)
lua/chadrc.lua                      (gone — no NvChad)
lua/options.lua                     lua/config/options.lua
lua/mappings.lua                    lua/config/keymaps.lua (+ lua/config/autocmds.lua)
lua/configs/{lazy,lspconfig,        lua/plugins/*.lua (one file per concern:
  conform,texlab}.lua                 completion, editor, formatting, lean, lsp, treesitter)
—                                   after/lsp/{julials,lua_ls,texlab}.lua
—                                   after/ftplugin/julia.lua
lua/plugins/init.lua                (split into the files above)
```

Key mechanic: LSP server configs are no longer `vim.lsp.config(...)` calls in
Lua. They are `return { ... }` tables in `after/lsp/<name>.lua` (native 0.11
rtp directory), and `lua/plugins/lsp.lua` just calls
`vim.lsp.enable({...})`. Servers without a file (`html`, `cssls`,
`rust_analyzer`, `kotlin_language_server`) use nvim-lspconfig's shipped
defaults. Note they live in `after/lsp/`, **not** a top-level `lsp/` — see
the README's "Layout" section for the runtimepath-precedence reason.

## 6. Migration checklist (first run on your machine)

1. Make sure you run **Neovim ≥ 0.11**.
2. Remove stale NvChad caches (they can interfere):
   ```sh
   rm -rf "$(nvim --headless -c 'print(stdpath("data"))' -c q)/nvchad"
   ```
3. Point `NVIM_APPNAME` or your `XDG_CONFIG_HOME` at this directory and launch
   `nvim`. lazy.nvim bootstraps itself and installs plugins; run `:Lazy sync`
   once if needed.
4. Install/verify the PATH binaries (see §3), or run the tool report.
5. Run the tests:
   ```sh
   nvim --headless -l tests/smoke.lua        # assertions; exits 1 on failure
   nvim --headless -l tests/check_tools.lua  # binary report
   stylua --check .
   ```
6. Treesitter parsers install automatically at startup via
   `require("nvim-treesitter").install(...)`; this needs the `tree-sitter` CLI.
   Test 8 of the smoke suite is skipped until parsers are present.
7. Smoke-test the two bespoke stacks manually:
   - open `sample/juliaproj/test.jl` → `:checkhealth vim.lsp` shows julials
     attached, no `UnusedBinding` warnings;
   - open `sample/test.tex` → `<leader>tb` builds a PDF with tectonic and
     launches qpdfview forward search;
   - in a `.tex` file, type `\alp` → completion offers `α` / `\alpha`.
8. Load `sample/` fixtures (`test.lua`, `test.rs`, `test.kt`, `test.jl`,
   `test.tex`) to sanity-check each language.

## 7. Full first-time setup on Arch Linux

Everything below gets the config fully working on a fresh Arch system.
The official-repo list covers almost everything; only the Kotlin language
server needs the AUR (or a manual download).

### 7.1 Neovim itself

```sh
sudo pacman -S --needed neovim
nvim --version   # must be >= 0.11
```

Arch's `neovim` package tracks current stable, so this is fine. If you want
nightly features, `paru -S neovim-git` is the alternative.

### 7.2 Everything from the official repos (one command)

```sh
sudo pacman -S --needed \
  git \
  tree-sitter \
  julia \
  texlab \
  tectonic \
  qpdfview \
  lua-language-server \
  stylua \
  rust-analyzer \
  base-devel
```

What each is for:

| Package | Provides | Needed by |
|---|---|---|
| `git` | `git` | lazy.nvim bootstrap, gitsigns |
| `tree-sitter` | `tree-sitter` CLI | compiling treesitter parsers (`:TSUpdate`) |
| `julia` | `julia` | `julials` (LanguageServer.jl) |
| `texlab` | `texlab` | LaTeX LSP |
| `tectonic` | `tectonic` | `<leader>tb` build (`:TexlabBuild`) |
| `qpdfview` | `qpdfview` | texlab forward search (PDF viewer) |
| `lua-language-server` | `lua-language-server` | `lua_ls` |
| `stylua` | `stylua` | Lua formatting (`<leader>lf` on `.lua`) |
| `rust-analyzer` | `rust-analyzer` | Rust LSP |
| `base-devel` | `gcc`, `make`, etc. | C compiler used by tree-sitter to build parsers |

If a package name has changed by the time you read this, find it with
`sudo pacman -Fy && pacman -F tree-sitter` (needs `pacman -F` file database).

### 7.3 TeX distribution (for `latexindent`)

`latexindent` ships in the Arch TeX split packages:

```sh
sudo pacman -S --needed texlive-basic texlive-binextra
```

`texlive-binextra` provides `latexindent` (plus `latexmk`, `synctex`).
You do **not** need the full `texlive-meta`: tectonic downloads missing
LaTeX packages on demand at first build (it will be slow on the very first
`<leader>tb`, then cached). Add only what you actually edit with.

### 7.4 Rust toolchain (optional but recommended)

The repo `rust-analyzer` binary runs standalone, but it needs a Rust
toolchain (`rustc`, `cargo`) for full analysis:

```sh
sudo pacman -S --needed rustup
rustup default stable
rustup component add rust-analyzer
```

With the rustup component installed, rustup's `rust-analyzer` is used and
the pacman one becomes redundant — either setup works; just have one on
`PATH`.

### 7.5 Kotlin language server (AUR)

`kotlin-language-server` is **not in the official repos**. With an AUR
helper:

```sh
paru -S kotlin-language-server   # or: yay -S kotlin-language-server
```

(If you have no AUR helper yet: `sudo pacman -S --needed paru` is not
possible — paru itself is in the AUR; bootstrap it with
`sudo pacman -S --needed git && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si`.)

Manual alternative if you want to avoid the AUR entirely: download the
latest release zip from
<https://github.com/kotlin-language-server/language-server/releases>, unzip
it, and put its `server/bin/kotlin-language-server` on `PATH`, e.g.:

```sh
mkdir -p ~/.local/bin ~/.local/opt
unzip kotlin-language-server.zip -d ~/.local/opt/kls
ln -s ~/.local/opt/kls/server/bin/kotlin-language-server ~/.local/bin/
```

(`~/.local/bin` must be on `PATH` for this to work.)

### 7.6 Julia LSP (LanguageServer.jl v6)

The config launches `julia` with the dedicated `nvim-lspconfig` environment.
Create it once (first run downloads a full Julia depot; be patient):

```sh
julia --project=~/.julia/environments/nvim-lspconfig \
      -e 'using Pkg; Pkg.add("LanguageServer")'
```

This installs LanguageServer.jl **v6** (bundles SymbolServer/StaticLint) —
the version the config's command override expects. Symbol caches download
automatically on first use (`symbolCacheDownload = true` is already set).

If you prefer juliaup over the pacman `julia` package, install it from the
AUR (`juliaup`) or via `curl -fsSL https://julialang-s3.julialang.org/install_julia.sh | sh`;
either works since the config only needs a `julia` binary on `PATH`.

### 7.7 Verify the toolchain

```sh
nvim --headless -l tests/check_tools.lua
```

This prints a ✓/✗ table for every binary and never fails — it documents
gaps rather than fixing them. Every row should be ✓ before proceeding.
(A ✗ `qpdfview` is tolerable if you don't use forward search, but texlab
will error on it when configured — swap the executable in
`after/lsp/texlab.lua` if you use another viewer, e.g. `zathura`.)

### 7.8 First launch

```sh
# 1. clear stale NvChad caches from the old config
rm -rf "$(nvim --headless -c 'print(stdpath("data"))' -c q)/nvchad"

# 2. point Neovim at this config, e.g.:
mkdir -p ~/.config
ln -s /path/to/new_nvim_config ~/.config/nvim   # or set NVIM_APPNAME

# 3. launch — lazy.nvim bootstraps itself and installs plugins on first run
nvim
# run :Lazy sync inside nvim if anything was left pending

# 4. treesitter parsers install automatically at startup (needs tree-sitter CLI
#    + base-devel, done above); run :TSInstall/:TSUpdate only to force it

# 5. headless test suite
nvim --headless -l tests/smoke.lua   # exits 1 on failure; test 8 skips until parsers exist
```

First launch of each language stack will be slow (Julia depot, tectonic
package downloads, symbol caches) — that is normal and cached afterwards.

## 8. Known trade-offs / toggles (decisions left to you)

- **Format on save** is off (as in the old config). One-line change in
  `lua/plugins/formatting.lua` if you want it.
- **`shiftwidth = 2` globally**, except Julia which uses 4
  (`after/ftplugin/julia.lua`). Change in `lua/config/options.lua` if you want
  it different.
- **`;` → `:`** still disables repeat-motion `;`. Unmap one line in
  `lua/config/keymaps.lua` if you ever want it back.
- **Lean.nvim is not in the old lockfile** — it resolves fresh; its version
  is pinned in `lazy-lock.json` here.
- Snacks picker / git-hunk chords beyond the README's table are not mapped —
  add what you miss (every missing NvChad chord is one `map()` line in
  `lua/config/keymaps.lua`).

## 9. Sources of further information

Inside this repo:

- **`README.md`** — philosophy, required-binaries table, full keymap
  reference, `after/lsp/` vs `lsp/` explanation, Julia v6 install command.
  Start here.
- **`PLAN.md`** — the full design record: every decision, the old-working-
  tree authority for each ported value, edge cases, and the verification
  matrix. Read it when you wonder "why is it like this".
- **`lua/config/keymaps.lua`** — the authoritative keymap list.
- **`lua/plugins/*.lua`** — one file per concern, each explains why it exists.
- **`after/lsp/*.lua`** — the Julia/Lua/LaTeX server overrides.
- **`tests/`** — `smoke.lua` (headless assertions) and `check_tools.lua`
  (PATH report).
- **`sample/`** — fixtures for manual per-language checks.

External:

- `:help lsp-config`, `:help vim.lsp.enable`, `:help grn` — native LSP and
  the 0.11 `gr*` LSP motions (the biggest muscle-memory shift).
- [snacks.nvim](https://github.com/folke/snacks.nvim) — picker/explorer/
  notifier modules and their built-in keys.
- [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) — statusline
  configuration.
- [blink.cmp](https://github.com/Saghen/blink.cmp) — completion keymap
  presets and source configuration.
- [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) — hunk
  navigation/staging API.
- [catppuccin/nvim](https://github.com/catppuccin/nvim) — flavours and
  integrations.
- [conform.nvim](https://github.com/stevearc/conform.nvim) — formatter config.
- [texlab docs](https://github.com/latex-lsp/texlab) — the settings mirrored
  in `after/lsp/texlab.lua`.
