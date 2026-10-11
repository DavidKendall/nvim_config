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
-- These are window-local options, so apply them both when the buffer is
-- created (TermOpen) and whenever it is shown in a window (BufWinEnter) --
-- plugin terminals like snacks/lazygit open in a float created after TermOpen.
local function terminal_window_opts()
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.wo.foldcolumn = "0"
  vim.wo.statuscolumn = ""
  vim.wo.colorcolumn = ""
  vim.wo.spell = false
end

local terminal = vim.api.nvim_create_augroup("terminal", { clear = true })

vim.api.nvim_create_autocmd("TermOpen", {
  group = terminal,
  desc = "Terminal buffers: friendly local options and enter terminal mode",
  callback = function()
    terminal_window_opts()
    vim.opt_local.scrollback = 10000
    vim.cmd "startinsert"
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = terminal,
  desc = "Terminal buffers shown in any window get clean window options",
  callback = function()
    if vim.bo.buftype == "terminal" then
      terminal_window_opts()
    end
  end,
})
