vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  desc = "Highlight when yanking text",
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Terminal buffers are `nomodifiable` while the job runs and are driven from
-- Terminal-Job mode. Open them ready to type, and strip the editor furniture
-- (line numbers, sign column, colorcolumn) that leaks in from global options.
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("terminal", { clear = true }),
  desc = "Terminal buffers: friendly local options and enter terminal mode",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.colorcolumn = ""
    vim.opt_local.spell = false
    vim.opt_local.scrollback = 10000
    vim.cmd "startinsert"
  end,
})
