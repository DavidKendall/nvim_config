-- Headless smoke tests for the config.
-- Run: nvim --headless -l tests/smoke.lua
-- Prints PASS/FAIL per assertion and exits 1 if any assertion fails.

local failures = 0

local function check(name, cond, detail)
  if cond then
    print("PASS: " .. name)
  else
    failures = failures + 1
    print("FAIL: " .. name .. (detail ~= nil and (" -- " .. tostring(detail)) or ""))
  end
end

local function contains(list, value)
  for _, v in ipairs(list or {}) do
    if v == value then
      return true
    end
  end
  return false
end

-- Locate the config root (parent of tests/) and load the config.
-- `nvim -l` runs in silent mode with 'loadplugins' off; turn it back on so
-- lazy.nvim and the imported plugin specs are registered.
local script = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(script, ":p:h:h")
vim.opt.rtp:prepend(root)
vim.go.loadplugins = true

dofile(root .. "/init.lua")

-- `nvim -l` starts without filetype plugins; enable them so `after/ftplugin`
-- files are sourced the way they are in a normal session.
vim.cmd "filetype plugin indent on"

local loader = require "lazy.core.loader"

-- 1. Config + full plugin registration, no startup errors
local expected = {
  "catppuccin",
  "snacks.nvim",
  "which-key.nvim",
  "gitsigns.nvim",
  "blink.cmp",
  "blink.compat",
  "cmp-latex-symbols",
  "nvim-lspconfig",
  "nvim-treesitter",
  "conform.nvim",
  "lean.nvim",
  "plenary.nvim",
  "lualine.nvim",
  "nvim-web-devicons",
}
local registered = require("lazy.core.config").plugins
local missing = {}
for _, name in ipairs(expected) do
  if not registered[name] then
    table.insert(missing, name)
  end
end
check(
  "1. config loads and expected plugins are registered",
  #missing == 0 and vim.v.errmsg == "",
  "missing=" .. table.concat(missing, ",") .. " errmsg=" .. tostring(vim.v.errmsg)
)

-- 2. Leaders
check(
  "2. leaders",
  vim.g.mapleader == " " and vim.g.maplocalleader == " ",
  "mapleader=" .. tostring(vim.g.mapleader) .. " maplocalleader=" .. tostring(vim.g.maplocalleader)
)

-- 3. Preserved options
check(
  "3. preserved options",
  vim.o.clipboard == "unnamedplus" and vim.o.colorcolumn == "92" and vim.o.spelllang == "en_gb",
  string.format("clipboard=%s colorcolumn=%s spelllang=%s", vim.o.clipboard, vim.o.colorcolumn, vim.o.spelllang)
)

-- Load plugins needed by the remaining assertions.
loader.load({ "blink.cmp", "conform.nvim", "gitsigns.nvim", "snacks.nvim", "lualine.nvim" }, {})

-- 4. Keymaps
check("4a. <leader>tb mapped", vim.fn.maparg("jk", "i") ~= "" and vim.fn.maparg(vim.g.mapleader .. "tb", "n") ~= "")
check("4b. <leader>lf mapped", vim.fn.maparg(vim.g.mapleader .. "lf", "n") ~= "")

local gitdir = vim.fn.tempname()
vim.fn.mkdir(gitdir, "p")
vim.fn.system { "git", "init", "-q", gitdir }
vim.fn.writefile({ "local x = 1" }, gitdir .. "/smoke.lua")
vim.fn.system { "git", "-C", gitdir, "add", "." }
vim.fn.system {
  "git",
  "-C",
  gitdir,
  "-c",
  "user.email=smoke@example.com",
  "-c",
  "user.name=smoke",
  "commit",
  "-qm",
  "init",
}
vim.fn.writefile({ "local x = 1", "local y = 2" }, gitdir .. "/smoke.lua")
vim.cmd.edit(gitdir .. "/smoke.lua")
vim.wait(2000, function()
  return vim.fn.maparg("]h", "n") ~= ""
end, 50)
check("4c. gitsigns ]h mapped in a git repo", vim.fn.maparg("]h", "n") ~= "")

-- 5. All enabled LSP servers resolve a config and can be (re-)enabled
local servers = { "julials", "texlab", "lua_ls", "html", "cssls", "rust_analyzer", "kotlin_language_server" }
local bad_servers = {}
for _, name in ipairs(servers) do
  local enabled = pcall(vim.lsp.enable, name)
  local ok, config = pcall(function()
    return vim.lsp.config[name]
  end)
  if not enabled or not ok or type(config) ~= "table" then
    table.insert(bad_servers, name)
  end
end
check("5. enabled servers resolve configs", #bad_servers == 0, "bad=" .. table.concat(bad_servers, ","))

-- 5b. Our after/lsp overrides actually win over nvim-lspconfig's defaults.
local julials = vim.lsp.config.julials
local julials_cmd = julials.cmd and julials.cmd[4] or ""
local overrides_ok = julials_cmd:find "SymbolServer" == nil
  and contains(julials.root_markers, ".git")
  and type(julials.on_attach) == "function"
  and vim.tbl_get(vim.lsp.config.texlab, "settings", "texlab", "build", "executable") == "tectonic"
check("5b. after/lsp overrides take precedence", overrides_ok)

-- 6. conform
local conform = require "conform"
local stylua_ok, stylua_info = pcall(conform.get_formatter_info, "stylua")
check(
  "6. conform formatters",
  stylua_ok
    and stylua_info ~= nil
    and contains(conform.formatters_by_ft.julia, "injected")
    and type(conform.formatters_by_ft.tex) == "table"
)

-- 7. blink.cmp sources
local blink_ok, blink_config = pcall(require, "blink.cmp.config")
local sources = blink_ok and blink_config.sources and blink_config.sources.default or {}
check(
  "7. blink.cmp default sources",
  contains(sources, "lsp")
    and contains(sources, "path")
    and contains(sources, "snippets")
    and contains(sources, "buffer")
    and contains(sources, "latex_symbols"),
  table.concat(sources, ",")
)

-- 8. Treesitter parsers (optional/slow: requires parsers to be installed)
local ts_ok, treesitter = pcall(require, "nvim-treesitter")
if ts_ok and type(treesitter.get_installed) == "function" then
  local wanted = {
    "vim",
    "lua",
    "vimdoc",
    "html",
    "css",
    "kotlin",
    "julia",
    "rust",
    "latex",
    "markdown",
    "markdown_inline",
    "regex",
  }
  local ok, installed = pcall(treesitter.get_installed)
  if ok then
    local absent = {}
    for _, name in ipairs(wanted) do
      if not contains(installed, name) then
        table.insert(absent, name)
      end
    end
    if #absent == 0 then
      check("8. treesitter parsers installed", true)
    else
      print("SKIP: 8. treesitter parsers not all installed: " .. table.concat(absent, ","))
    end
  else
    print "SKIP: 8. nvim-treesitter.get_installed() unavailable"
  end
else
  print "SKIP: 8. nvim-treesitter not loaded"
end

-- 9. Statusline is provided by lualine (snacks has no statusline module)
local lualine_ok = pcall(require, "lualine")
check(
  "9. lualine sets the statusline",
  lualine_ok and type(vim.o.statusline) == "string" and vim.o.statusline:find "lualine" ~= nil,
  vim.o.statusline
)

-- 10. Julia uses 4-space indentation via after/ftplugin/julia.lua
vim.cmd "enew"
vim.bo.filetype = "julia"
check("10. julia indent is 4", vim.bo.shiftwidth == 4 and vim.bo.tabstop == 4, "shiftwidth=" .. vim.bo.shiftwidth)

-- 11. lazygit integration (mapping + module present; binary is external)
local snacks_ok, snacks = pcall(require, "snacks")
check(
  "11. <leader>gg mapped and Snacks.lazygit present",
  vim.fn.maparg(vim.g.mapleader .. "gg", "n") ~= "" and snacks_ok and snacks.lazygit ~= nil
)

print(string.format("\n%d failure(s)", failures))
os.exit(failures == 0 and 0 or 1)
