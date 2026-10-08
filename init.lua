vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

require "config.options"
require "config.keymaps"
require "config.autocmds"

require("lazy").setup {
  spec = { { import = "plugins" } },
  change_detection = { notify = false },
  install = { colorscheme = { "catppuccin" } },
  rocks = { enabled = false }, -- no plugin needs LuaRocks
}
