return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    config = function()
      -- Explicit integrations instead of `auto_integrations`, which calls
      -- `vim.pack.get()` on Neovim 0.12 and creates an empty
      -- `site/pack/core/opt` directory that lazy.nvim's health check flags.
      require("catppuccin").setup {
        auto_integrations = false,
        integrations = {
          blink_cmp = { enabled = true, style = "bordered" },
          gitsigns = true,
          snacks = true,
          which_key = true,
        },
      }
      vim.cmd.colorscheme "catppuccin"
    end,
  },

  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      picker = {},
      explorer = {},
      notifier = {},
      indent = {},
      input = {},
      quickfile = {},
      bigfile = {},
    },
    config = function(_, opts)
      require("snacks").setup(opts)

      -- Snacks highlights picker entries with tree-sitter. If a parser no longer
      -- matches the host Neovim's bundled queries (e.g. a stale `vim` parser
      -- after a Neovim upgrade), compiling the query throws and aborts the
      -- picker (seen with <leader>km). Degrade to unhighlighted lines instead.
      local highlight = require "snacks.picker.util.highlight"
      local get_highlights = highlight.get_highlights
      highlight.get_highlights = function(...)
        local ok, result = pcall(get_highlights, ...)
        return ok and result or {}
      end
    end,
  },

  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "catppuccin-nvim",
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },

  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    opts = {
      on_attach = function(bufnr)
        local gs = require "gitsigns"
        local map = vim.keymap.set

        map("n", "]h", function()
          gs.nav_hunk "next"
        end, { desc = "Next git hunk", buffer = bufnr })
        map("n", "[h", function()
          gs.nav_hunk "prev"
        end, { desc = "Previous git hunk", buffer = bufnr })
        map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage git hunk", buffer = bufnr })
        map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset git hunk", buffer = bufnr })
        map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview git hunk", buffer = bufnr })
        map("n", "<leader>hb", function()
          gs.blame_line { full = true }
        end, { desc = "Blame line", buffer = bufnr })
      end,
    },
  },
}
