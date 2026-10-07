-- UnusedBinding ("Variable has been assigned but not used") is set unconditionally
-- during StaticLint's semantic pass with no server-side setting to disable it.
-- Capture the current default handler and filter the diagnostic out before display.
local default_diagnostics_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]

return {
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
