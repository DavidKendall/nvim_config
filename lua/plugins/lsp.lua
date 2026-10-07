return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      vim.lsp.enable { "julials", "texlab", "lua_ls", "html", "cssls", "rust_analyzer", "kotlin_language_server" }
    end,
  },
}
