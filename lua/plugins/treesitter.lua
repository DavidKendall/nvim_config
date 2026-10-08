return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
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
      },
    },
    -- `ensure_installed` is not read by the `main` branch and `:TSUpdate` only
    -- updates already-installed parsers, so install explicitly at startup.
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
      require("nvim-treesitter").install(opts.ensure_installed)
    end,
  },
}
