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
--
-- Those are *window-local* options and a window persists them across buffers,
-- so reconcile them from the buffer type whenever a window is (re)entered:
-- terminal buffers get clean options, normal buffers get the editor defaults
-- (read from the option globals). Buffers opened by plugins (nofile, prompt,
-- quickfix, help, ...) are left untouched.
local terminal = vim.api.nvim_create_augroup("terminal", { clear = true })

local term_win_opts = {
  number = false,
  relativenumber = false,
  signcolumn = "no",
  foldcolumn = "0",
  statuscolumn = "",
  colorcolumn = "",
  spell = false,
}
local term_win_names = vim.tbl_keys(term_win_opts)

local function editor_win_opts()
  local opts = {}
  for _, name in ipairs(term_win_names) do
    opts[name] = vim.api.nvim_get_option_value(name, { scope = "global" })
  end
  return opts
end

local function apply_win_opts(win, opts)
  for name, value in pairs(opts) do
    -- scope="local" is required: with only `win`, window-local options are set
    -- like `:set` and would clobber the global defaults we read back below.
    vim.api.nvim_set_option_value(name, value, { win = win, scope = "local" })
  end
end

local function reconcile_win(win)
  local buftype = vim.bo[vim.api.nvim_win_get_buf(win)].buftype
  if buftype == "terminal" then
    apply_win_opts(win, term_win_opts)
  elseif buftype == "" then
    apply_win_opts(win, editor_win_opts())
  end
end

-- TermOpen also fires after BufWinEnter, which momentarily sees the buffer as
-- a normal one; reconcile again once it is really a terminal. TermEnter
-- catches re-entering a terminal buffer, and BufEnter covers buffer switches
-- (e.g. `:buffer`) that may not re-trigger BufWinEnter.
--
-- The buffer's type can still be settling when the event fires (e.g. a window
-- is entered before the terminal buffer is re-listed), which would make us
-- apply the editor defaults. So reconcile now *and* once on the next tick, when
-- state has settled, so the correct options win.
vim.api.nvim_create_autocmd({ "BufWinEnter", "BufEnter", "WinEnter", "TermOpen", "TermEnter" }, {
  group = terminal,
  desc = "Reconcile window options with the shown buffer (terminal vs normal)",
  callback = function()
    local win = vim.api.nvim_get_current_win()
    reconcile_win(win)
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(win) then
        reconcile_win(win)
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = terminal,
  desc = "Terminal buffers: enter terminal mode and set scrollback",
  callback = function()
    vim.opt_local.scrollback = 10000
    vim.cmd "startinsert"
  end,
})
