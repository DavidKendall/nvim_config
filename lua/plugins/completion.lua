return {
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "*",
    dependencies = {
      "saghen/blink.compat",
      "kdheepak/cmp-latex-symbols",
    },
    opts = {
      keymap = { preset = "default" },
      completion = { documentation = { auto_show = true } },
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "latex_symbols" },
        providers = {
          latex_symbols = {
            module = "blink.compat.source",
            name = "latex_symbols",
            opts = { strategy = 0 }, -- 0 = mixed: completes both "\alpha" and "α"
          },
        },
      },
    },
  },
}
