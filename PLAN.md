# Implementation Plan: Minimal Native-First Neovim Config

**Status:** approved for implementation (all grilling questions answered)
**Source of truth for behavior:** the *working tree* of `/workspace/nvim_config` (uncommitted state, not HEAD — it contains the julials block, treesitter `main` migration, and conform julia line). Old config is left untouched.
**Target:** fresh config in `/workspace/new_nvim_config` (empty dir).
**Informing philosophy:** user-provided ChatGPT text — "small, native-first, boring infrastructure"; Neovim ≥ 0.11 native LSP; no distribution (NvChad is dropped); plugins only for genuine gaps.

## 0. Resolved decisions (from Phase 1 grill)

| # | Decision | Choice |
|---|----------|--------|
| 1 | NvChad | **Drop entirely.** Re-provide theme, statusline, picker, explorer, keymaps from scratch. |
| 2 | Destination | Fresh rewrite in `/workspace/new_nvim_config`. Old repo untouched. |
| 3 | Completion engine | **blink.cmp** (nvim-cmp is maintenance mode). LaTeX symbols preserved via `blink.compat` + `cmp-latex-symbols` with `strategy = 0` (mixed `\alpha`/`α`). |
| 4 | Fuzzy finding | **snacks.nvim** (picker + explorer + statusline + notifier). ChatGPT's endorsed "one luxury toolkit". NOT both fzf-lua and snacks. |
| 5 | Mason | **Drop.** Tools expected on PATH (julials already comes from PATH in the working tree; texlab/tectonic/qpdfview/latexindent are system tools anyway). README documents required binaries; `tests/check_tools.lua` reports missing ones. |
| 6 | LSP config mechanism | Native **top-level `lsp/<name>.lua` rtp directory** (`:help lsp-config`), auto-merged over nvim-lspconfig's base definitions. No `vim.lsp.config(...)` calls needed in Lua — only `vim.lsp.enable`. |
| 7 | Formatting | conform.nvim, **manual only** (`<leader>lf`), preserving current behavior. `format_on_save` deliberately off — see Open Questions. |
| 8 | Keymaps | Fresh minimal set (below), documented in README. User's personal chords (`jk`, `;`→`:`, `<leader>tb`, `<leader>km`) preserved verbatim. |
| 9 | Compatibility floor | Neovim **≥ 0.11** (required for `vim.lsp.config`/`enable` and `lsp/` rtp dir). |
| 10 | Theme | catppuccin (via `catppuccin/nvim`, replacing NvChad/base46). |
| 11 | Lean / Kotlin / Rust / HTML / CSS / Julia / LaTeX | All preserved (parity list from grill). |

## 1. File structure and layout

```
/workspace/new_nvim_config/
├── init.lua                  # ~15 lines: leaders, lazy.nvim bootstrap, require config/*
├── lua/
│   ├── config/
│   │   ├── options.lua       # all vim.opt settings (one flat table of assignments)
│   │   ├── keymaps.lua       # ALL global keymaps in one file
│   │   └── autocmds.lua      # 1–2 genuine autocmds (TextYankPost highlight)
│   └── plugins/
│       ├── editor.lua        # catppuccin, snacks.nvim, which-key.nvim, gitsigns.nvim
│       ├── completion.lua    # blink.cmp, blink.compat, cmp-latex-symbols
│       ├── lsp.lua           # nvim-lspconfig + vim.lsp.enable({...}) list
│       ├── treesitter.lua    # nvim-treesitter (main branch) + parser list
│       ├── formatting.lua    # conform.nvim
│       └── lean.lua          # lean.nvim + plenary.nvim
├── lsp/                      # NATIVE rtp dir — auto-loaded by vim.lsp.enable, no require()
│   ├── julials.lua           # julia server: settings + diagnostic filter + env activation
│   ├── texlab.lua            # texlab: tectonic build, qpdfview forward search, latexindent
│   └── lua_ls.lua            # diagnostics.globals = { "vim" }
├── tests/
│   ├── smoke.lua             # headless assertions (run: nvim --headless -l tests/smoke.lua)
│   └── check_tools.lua       # PATH tool report (non-fatal)
├── README.md                 # philosophy, required binaries table, keymap reference
├── .stylua.toml              # copied verbatim from old config (column_width=120, 2-space, …)
└── lazy-lock.json            # generated at the end via :lazy lock
```

Notes:
- `lsp/` sits at config root (next to `lua/`), because Neovim 0.11 resolves `lsp/{name}.lua` against runtimepath — see `:help lsp-config`. Only servers needing overrides get a file; `html`, `cssls`, `rust_analyzer`, `kotlin_language_server` use nvim-lspconfig's shipped defaults and are merely enabled by name.
- No `ftplugin/`, no `after/`, no util modules. Deliberately no abstraction layer (ChatGPT rule 13).

## 2. "Public API" — keymap grammar and module contracts

There is no CLI; the user-facing interface is the keymap surface. `vim.g.mapleader = " "`, `vim.g.maplocalleader = " "`.

### 2.1 Global keymaps (lua/config/keymaps.lua) — complete list

| Chord | Mode | Action | Source/authority |
|-------|------|--------|------------------|
| `jk` | i | `<Esc>` | preserved from old `mappings.lua` |
| `;` | n | `:` (command mode) | preserved from old `mappings.lua` ⚠ see Edge case E1 |
| `<leader>w` / `<leader>q` | n | `:write` / `:quit` | new |
| `<C-h>/<C-j>/<C-k>/<C-l>` | n | window nav | new (ChatGPT example) |
| `<leader>e` | n | snacks explorer toggle | replaces NvChad's `<leader>e` |
| `<leader>ff` / `<leader>fg` / `<leader>fb` / `<leader>fr` / `<leader>fs` | n | snacks picker: files / grep / buffers / recent / document symbols | ChatGPT rule 11 chords |
| `<leader>km` | n | snacks picker keymaps | preserved intent from old config |
| `<leader>tb` | n | `:TexlabBuild<CR>` | preserved |
| `<leader>lf` | n | conform format buffer | replaces NvChad's `<leader>fm` |
| `gd`, `gD`, `K` | n | definition, declaration, hover | standard (replaces NvChad's LSP maps) |
| `grn`, `grr`, `gri`, `gra` | n | rename/references/implementation/actions | **native Neovim 0.11 defaults** — do not remap, only document (`:help grn`) |
| `]h`, `[h` | n | next/prev git hunk | gitsigns README |
| `<leader>hs` / `<leader>hr` / `<leader>hp` / `<leader>hb` | n | stage / reset / preview / blame hunk | gitsigns README |

Keymap rule: every mapping gets `{ desc = ... }` so which-key + `<leader>km` picker show it.

### 2.2 Module contracts

- `lua/plugins/*.lua` each `return { <lazy.nvim specs> }`; imported once via `{ import = "plugins" }` in init.lua. Each file answers "why is this plugin here and how is it configured".
- `lsp/<name>.lua` each `return { cmd = ..., filetypes = ..., root_markers = ..., settings = ..., on_attach = ... }` — a valid `vim.lsp.config` table per `:help lsp-config`. Exported table must be merge-compatible with nvim-lspconfig's base definition (overrides win).
- `lua/lsp-init` does **not** exist; enabling happens in `lua/plugins/lsp.lua`:
  ```lua
  config = function()
    vim.lsp.enable({ "julials", "texlab", "lua_ls", "html", "cssls", "rust_analyzer", "kotlin_language_server" })
  end
  ```

## 3. Step-by-step build order

### Step 1 — `init.lua`
```lua
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- bootstrap lazy.nvim (clone to stdpath("data")/lazy/lazy.nvim if missing, branch "stable")
require("config.options")
require("config.keymaps")
require("config.autocmds")

require("lazy").setup({
  spec = { { import = "plugins" } },
  change_detection = { notify = false },
  install = { colorscheme = { "catppuccin" } },
})
```
No base46 cache dofile, no nvchad imports. **Constant:** lazy.nvim bootstrap branch `"stable"`.

### Step 2 — `lua/config/options.lua`
Preserved-from-old overrides (authoritative: old `lua/options.lua` working tree):
- `opt.clipboard = "unnamedplus"`, `opt.colorcolumn = "92"`, `opt.spelllang = "en_gb"`

Modern baseline (authoritative: ChatGPT example §4, standard sane defaults):
- `number`, `relativenumber`, `mouse = "a"`, `expandtab`, `shiftwidth = 2`, `tabstop = 2`, `ignorecase`, `smartcase`, `splitright`, `splitbelow`, `termguicolors`, `signcolumn = "yes"`, `updatetime = 250`, `timeoutlen = 300`, `undofile`

⚠ `shiftwidth = 2` applies to Julia too; Julia community convention is 4 — flagged as OQ2, not silently changed.

### Step 3 — `lua/config/keymaps.lua`
Exactly the table from §2.1. Implementation detail: `local map = vim.keymap.set` helper. No plugin-keymap indirection.

### Step 4 — `lua/config/autocmds.lua`
Single autocmd: `TextYankPost` → `vim.hl.on_yank()` (Neovim 0.11 API; `:help vim.hl.on_yank`). Nothing else — resist adding more until needed.

### Step 5 — `lua/plugins/editor.lua`
```lua
return {
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, lazy = false,
    config = function() vim.cmd.colorscheme("catppuccin") end },
  { "folke/snacks.nvim", lazy = false, priority = 1000,
    opts = { picker = {}, explorer = {}, statusline = {}, notifier = {}, indent = {}, input = {}, quickfile = {}, bigfile = {} } },
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
  { "lewis6991/gitsigns.nvim", event = "BufReadPre",
    opts = { ... hunk keymaps from §2.1 ... } },
}
```
Lazy-loading policy (ChatGPT rule 15): theme/statusline/picker are `lazy = false` (needed at startup); everything else anchored on events only where it's free. No `performance.rtp.disabled_plugins` list at all (old config's `ftplugin`/`syntax` disabling was a latent bug — dropped with NvChad).

### Step 6 — `lua/plugins/completion.lua`
```lua
return {
  { "saghen/blink.cmp", event = "InsertEnter", version = "*",
    dependencies = { "saghen/blink.compat", "kdheepak/cmp-latex-symbols" },
    opts = {
      keymap = { preset = "default" },
      completion = { documentation = { auto_show = true } },
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "latex_symbols" },
        providers = {
          latex_symbols = {
            module = "blink.compat.source",
            name = "latex_symbols",
            opts = { strategy = 0 },   -- 0 = mixed: completes both "\alpha" and "α"
          },
        },
      },
    } },
}
```
Authority: blink.cmp README (keymap presets, sources table), blink.compat README (bridging nvim-cmp sources), cmp-latex-symbols README (`strategy = 0` = mixed). No LuaSnip needed — blink.cmp ships its own snippet engine (`"snippets"` builtin source).

### Step 7 — `lua/plugins/lsp.lua` + `lsp/*.lua`

`lua/plugins/lsp.lua`:
```lua
return {
  { "neovim/nvim-lspconfig", lazy = false,
    config = function()
      vim.lsp.enable({ "julials", "texlab", "lua_ls", "html", "cssls", "rust_analyzer", "kotlin_language_server" })
    end },
}
```

`lsp/lua_ls.lua` — ChatGPT §7 verbatim pattern: `cmd = { "lua-language-server" }`, `filetypes = { "lua" }`, `root_markers = { ".luarc.json", ".luarc.jsonc", ".git" }`, `settings.Lua.diagnostics.globals = { "vim" }`.

`lsp/texlab.lua` — **preserved verbatim** from old `lua/configs/texlab.lua` working tree (user's toolchain preferences, source of truth = old working tree, flagged as user-derived values, not spec values):
- `settings.texlab.build.executable = "tectonic"`, `args = { "-X", "compile", "%f", "--synctex", "--keep-logs", "--keep-intermediates" }`, `forwardSearchAfter = true`, `onSave = false`
- `forwardSearch.executable = "qpdfview"`, `args = { "--unique", "%p#src:%f:%l:1" }`
- `formatting = latexindent, modifyLineBreaks = false`; `bibtexFormatter = "texlab"`; `formatterLineLength = 80`; `auxDirectory = "."`; `diagnosticsDelay = 300`
- `chktex.onEdit = false`, `chktex.onOpenAndSave = false` (deliberately off)

`lsp/julials.lua` — the one non-trivial file. **Port bit-for-bit** from old `lua/configs/lspconfig.lua` working tree:
- `root_markers = { "Project.toml", "JuliaProject.toml", ".git" }`
- `settings.julia = { lint = { run = true, missingrefs = "none" }, symbolCacheDownload = true }`
- `publishDiagnostics` handler: wraps the previous handler (`vim.lsp.handlers["textDocument/publishDiagnostics"]` captured before override), filters out diagnostics where `result.diagnostics[i].message` matches StaticLint's `UnusedBinding`, then calls the saved handler. (Exact predicate copied from old file — do not "improve" it.)
- `on_attach`: after defaults, if the client's `root_dir` is non-nil, `client.rpc.notify("julia/activateenvironment", { envPath = root })`.

`rust_analyzer`, `kotlin_language_server`, `html`, `cssls`: **no files** — nvim-lspconfig ships their definitions; they are only enabled by name.

### Step 8 — `lua/plugins/treesitter.lua`
```lua
{ "nvim-treesitter/nvim-treesitter", branch = "main", lazy = false,
  build = ":TSUpdate",
  opts = { ensure_installed = { "vim", "lua", "vimdoc", "html", "css", "kotlin", "julia", "rust", "latex", "markdown", "markdown_inline" } } }
```
Authority: old config list = `{vim, lua, vimdoc, html, css, kotlin, julia}` (preserved). **Additions flagged:** `rust` (rust_analyzer is enabled but parser was missing — a gap), `latex`/`markdown`/`markdown_inline` (needed for conform's `injected` formatter on julia strings and general LaTeX editing). Main-branch API: pass opts through; parsers install via `:TSUpdate` (note: current main branch requires the tree-sitter CLI for some parser builds — mention in README).

### Step 9 — `lua/plugins/formatting.lua`
```lua
{ "stevearc/conform.nvim", event = "BufWritePre",   -- loads pre-write even though format is manual (cheap, keeps save-path warm)
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      julia = { "injected", lsp_format = "fallback" },
      latex = { "lsp_format" },
    },
    format_on_save = nil,            -- manual only, preserved from old config
    format_after_save = nil,
  },
  keys = { { "<leader>lf", function() require("conform").format({ lsp_format = "fallback" }) end, desc = "Format buffer" } } }
```
Authority: old `configs/conform.lua` working tree (the `injected` + lsp fallback julia line is user WIP — preserved exactly). Dead commented css/html prettier lines from old file: **not carried over**.

### Step 10 — `lua/plugins/lean.lua`
```lua
{ "Julian/lean.nvim", dependencies = { "nvim-lua/plenary.nvim" },
  lazy = true, ft = "lean",
  opts = { mappings = true } }
```
Semantics preserved (old spec used `BufReadPre/BufNewFile *.lean` patterns; `ft = "lean"` is the equivalent lazy anchor). lean.nvim is absent from the old lockfile — it will resolve fresh; pin whatever `:lazy lock` produces.

### Step 11 — Tests

`tests/check_tools.lua` (non-fatal report): `vim.fn.executable()` for `lua-language-server`, `stylua`, `texlab`, `tectonic`, `qpdfview`, `latexindent`, `rust-analyzer`, `kotlin-language-server`, `git`, `julia`. Print ✓/✗ table; exit 0 always.

`tests/smoke.lua` (run: `nvim --headless -l tests/smoke.lua`; each assert prints PASS/FAIL, exit code 1 on any FAIL):

| # | Assertion | Authoritative source for expected value |
|---|-----------|----------------------------------------|
| 1 | init.lua + full plugin load complete with no errors (check `vim.v.errmsg` empty and `require("lazy.core.config").plugins` contains catppuccin, snacks.nvim, which-key.nvim, gitsigns.nvim, blink.cmp, blink.compat, cmp-latex-symbols, nvim-lspconfig, nvim-treesitter, conform.nvim, lean.nvim, plenary.nvim) | lazy.nvim docs (`lazy.core.config.plugins`) |
| 2 | `vim.g.mapleader == " "` and `vim.g.maplocalleader == " "` | plan §2 |
| 3 | `vim.o.clipboard == "unnamedplus"`, `vim.o.colorcolumn == "92"`, `vim.o.spelllang == "en_gb"` | old options.lua working tree (preserved values) |
| 4 | `vim.fn.maparg("jk", "i")` non-empty; `vim.fn.maparg("<leader>tb", "n")` non-empty; `<leader>lf` resolves; gitsigns `]h` maps after opening a buffer in a git repo | plan §2.1 |
| 5 | For each of the 7 enabled server names: `vim.lsp.get_clients()` doesn't error and `vim.api.nvim_get_autocmds({ event = "FileType" })` registration via enable succeeded — implemented as: `vim.lsp.enable(name)` inside `pcall` returns true (idempotent re-enable) and `vim.lsp.config[name]` resolves (config table exists) | `:help lsp-config` |
| 6 | `require("conform").get_formatter_info("stylua")` and for julia ft: `formatters_by_ft.julia` contains `"injected"` | conform.nvim README API |
| 7 | `require("blink.cmp.config").sources.default` contains `"lsp"`, `"path"`, `"snippets"`, `"buffer"`, `"latex_symbols"` | blink.cmp docs |
| 8 | `require("nvim-treesitter").get_installed()` superset of plan parser list (run after `:TSUpdate`; mark as slow/optional if parsers must download) | nvim-treesitter main-branch README |

**Manual verification matrix** (cannot be fully automated headlessly — documented commands, run after install):
- Open `sample/test.jl` (with a `Project.toml` in dir): `:checkhealth vim.lsp` shows julials attached; no `UnusedBinding` diagnostics appear; `:messages` shows no activation error.
- Open `sample/test.tex`: texlab attached; `<leader>tb` produces a PDF (tectonic present); forward search launches qpdfview.
- Insert-mode completion in a `.tex` file: typing `\alp` offers `α`/`\alpha` (mixed strategy).
- `:Lazy profile` — record startup; target: no plugin complained about in the profile.

Test fixtures: create `sample/` with `test.jl` (in a subdir with empty `Project.toml`), `test.tex`, `test.rs`, `test.kt`, `test.lua` — minimal valid files.

### Step 12 — README.md, style, lock
- README: philosophy paragraph (5 lines), **required binaries table** (tool → what needs it → suggested install: julia/julias via juliaup, tectonic via tectonic installer, texlab/rust-analyzer via package mgr or rustup, stylua/latexindent/kotlin-lsp), keymap reference (§2.1 table), test instructions, Neovim ≥ 0.11 requirement.
- Copy `.stylua.toml` verbatim from old config; run `stylua lua/ lsp/ tests/ init.lua`.
- Run `:lazy lock` to generate `lazy-lock.json`. `git init` + initial commit.

## 4. Edge cases and error paths

- **E1 — `;` maps away repeat-motion.** Mapping `;` to `:` in normal mode disables the built-in `;` (repeat `f`/`t`). The user's old config does this deliberately; preserve it, but note the tradeoff in README. If user later objects, unmapping restores native behavior — decision stays with user (flagged, not deferred).
- **E2 — Missing binary on PATH.** `vim.lsp.enable("texlab")` with no texlab binary → error surfaces on first matching buffer (LSP log). Guard: `tests/check_tools.lua` documents the gap; README lists binaries. No silent fallbacks.
- **E3 — Julia file outside a project.** `on_attach` env activation must guard `nil` root_dir (no notification without `envPath`). Copied logic must keep this guard.
- **E4 — Diagnostic handler chaining.** The julials `publishDiagnostics` override must capture and call the *previous* handler; filtering only `UnusedBinding`; all other diagnostics pass through unchanged.
- **E5 — blink.compat with cmp-latex-symbols.** If the compat bridge fails (source module load error), completion must still work for the 4 builtin sources; the provider is isolated — a failing provider must not break the menu (verify manually; blink catches provider errors per its docs).
- **E6 — Stale NvChad caches on the user's machine.** Migration note (README + final handoff): `rm -rf $(nvim --headless -c 'print(stdpath("data"))' -c q)/nvchad` before first launch, else old base46 caches may interfere.
- **E7 — First run with no lockfile.** lazy.nvim bootstraps itself; `install.colorscheme` fallback is catppuccin; run `:lazy sync` once. Document in README.
- **E8 — Treesitter main-branch parser install failures** (missing tree-sitter CLI): `:TSUpdate` errors are non-fatal for editor startup; README notes CLI requirement.
- **E9 — conform on files without a formatter.** `lsp_format = "fallback"` → no-op when neither formatter nor LSP formatting exists; must not error.
- **E10 — lean.nvim not in old lockfile.** Fresh resolution may pull API-incompatible version if the plugin changed; pin the resolved commit and note it in the lockfile diff review.

## 5. Open questions / flagged decisions

| # | Question | Status |
|---|----------|--------|
| OQ1 | ChatGPT suggests `format_on_save` is "much nicer"; current config is manual-only. **Preserved manual** (per parity defaults). Switch to `format_on_save = { timeout_ms = 1000, lsp_format = "fallback" }` if you want — one-line change in `formatting.lua`. | user toggle, not blocking |
| OQ2 | `shiftwidth = 2` globally vs `4` for Julia (`ftplugin/julia.lua` could set it). Current = 2 everywhere; preserved. | user toggle |
| OQ3 | `;` → `:` footgun (E1). Preserved; unmapping is one line in keymaps.lua. | user toggle |
| OQ4 | Exact snack module set (§ Step 5 list is proposed; trim/extend freely). | minor |
| OQ5 | Tool installation strategy outside Neovim (mise/nix/brew). Out of scope for the config itself; README table lists the binaries only. | deferred — out of scope |

## 6. Definition of done

A fresh agent implementing this plan is finished when:
1. `nvim --headless -l tests/smoke.lua` exits 0 (test 8 may be skipped on first run before parsers download).
2. `nvim --headless -l tests/check_tools.lua` prints the tool table (missing tools documented, not fixed).
3. Manual matrix §3-Step-11 passes for julia and latex (the two bespoke stacks).
4. `stylua --check .` passes; `lazy-lock.json` committed; README complete.