-- Non-fatal report of the external tools this config expects on PATH.
-- Run: nvim --headless -l tests/check_tools.lua
-- Always exits 0; missing tools are documented in the README, not fixed here.

local tools = {
  { "lua-language-server", "Lua LSP (lua_ls)" },
  { "stylua", "Lua formatter (conform)" },
  { "texlab", "LaTeX LSP" },
  { "tectonic", "LaTeX build engine (texlab)" },
  { "qpdfview", "PDF viewer (forward search)" },
  { "latexindent", "LaTeX formatter (conform/texlab)" },
  { "rust-analyzer", "Rust LSP" },
  { "kotlin-language-server", "Kotlin LSP" },
  { "git", "gitsigns / lazy.nvim bootstrap" },
  { "julia", "Julia runtime (julials launcher)" },
}

print "Required tools on PATH:"
for _, tool in ipairs(tools) do
  local found = vim.fn.executable(tool[1]) == 1
  print(string.format("  %s %-24s %s", found and "OK " or "MISSING", tool[1], tool[2]))
end
