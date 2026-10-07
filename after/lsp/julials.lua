-- nvim-lspconfig's bundled julials command still runs
-- `using LanguageServer, SymbolServer, StaticLint`, but LanguageServer.jl v6
-- dropped SymbolServer/StaticLint (they are now bundled) and exits 1 if they
-- are missing. Override the command with the v6-compatible invocation.
local cmd = {
  "julia",
  "--startup-file=no",
  "--history-file=no",
  "-e",
  [[
    # Load LanguageServer.jl: attempt to load from ~/.julia/environments/nvim-lspconfig
    # with the regular load path as a fallback
    ls_install_path = joinpath(
        get(DEPOT_PATH, 1, joinpath(homedir(), ".julia")),
        "environments", "nvim-lspconfig"
    )
    pushfirst!(LOAD_PATH, ls_install_path)
    using LanguageServer
    popfirst!(LOAD_PATH)
    @info "Running language server" VERSION pwd()
    LanguageServer.runserver()
  ]],
}

-- UnusedBinding ("Variable has been assigned but not used") is set unconditionally
-- during StaticLint's semantic pass with no server-side setting to disable it.
-- Capture the current default handler and filter the diagnostic out before display.
local default_diagnostics_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]

return {
  cmd = cmd,
  root_markers = { "Project.toml", "JuliaProject.toml", ".git" },
  settings = {
    julia = {
      lint = {
        run = true,
        missingrefs = "none", -- suppress false-positive "Missing reference" warnings
      },
      symbolCacheDownload = true,
    },
  },
  handlers = {
    ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
      if result and result.diagnostics then
        result.diagnostics = vim.tbl_filter(function(d)
          return d.code ~= "UnusedBinding"
        end, result.diagnostics)
      end
      default_diagnostics_handler(err, result, ctx, config)
    end,
  },
  on_attach = function(client, bufnr)
    -- Tell LanguageServer.jl which project to analyse. Without this, the LSP
    -- startup script resolves project_path from its own CWD (inherited from
    -- wherever Neovim was launched), which may not be the project root.
    local root = client.config.root_dir or client.root_dir
    if root then
      client:notify("julia/activateenvironment", { envPath = root })
    end
  end,
}
