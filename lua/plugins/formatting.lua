return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- loads pre-write even though formatting is manual
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        julia = { "injected", lsp_format = "fallback" },
        latex = { "lsp_format" },
      },
      format_on_save = nil, -- manual only, preserved from the old config
      format_after_save = nil,
    },
    keys = {
      {
        "<leader>lf",
        function()
          require("conform").format { lsp_format = "fallback" }
        end,
        desc = "Format buffer",
      },
    },
  },
}
