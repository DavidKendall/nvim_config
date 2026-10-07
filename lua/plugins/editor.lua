return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    config = function()
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
      statusline = {},
      notifier = {},
      indent = {},
      input = {},
      quickfile = {},
      bigfile = {},
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
