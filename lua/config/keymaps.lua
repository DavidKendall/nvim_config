local map = vim.keymap.set

-- preserved from the old config
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("n", ";", ":", { desc = "CMD enter command mode" })
-- Build the current LaTeX document with texlab.
-- nvim-lspconfig renamed the commands to a `Lsp` prefix (`TexlabBuild` ->
-- `LspTexlabBuild`). If texlab is attached but neither command exists, building
-- is still done directly via the `textDocument/build` request.
map("n", "<leader>tb", function()
  local clients = vim.lsp.get_clients { name = "texlab", bufnr = 0 }
  if #clients == 0 then
    vim.notify("texlab is not attached to this buffer", vim.log.levels.WARN)
    return
  end
  for _, cmd in ipairs { "LspTexlabBuild", "TexlabBuild" } do
    if vim.fn.exists(":" .. cmd) == 2 then
      return vim.cmd(cmd)
    end
  end
  local client = clients[1]
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  client:request("textDocument/build", params, function(err, result)
    if err then
      vim.notify("texlab build error: " .. tostring(err), vim.log.levels.ERROR)
    elseif result and result.status then
      local status = { "Success", "Error", "Failure", "Cancelled" }
      vim.notify("texlab build: " .. (status[result.status + 1] or result.status), vim.log.levels.INFO)
    end
  end, 0)
end, { desc = "Texlab build" })
map("n", "<leader>km", function()
  require("snacks").picker.keymaps()
end, { desc = "Show all keymaps" })

-- git (requires the `lazygit` binary on PATH)
map("n", "<leader>gg", function()
  require("snacks").lazygit()
end, { desc = "LazyGit" })

-- buffers
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write buffer" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })

-- window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- file explorer
map("n", "<leader>e", function()
  require("snacks").explorer()
end, { desc = "Toggle file explorer" })

-- fuzzy finding
map("n", "<leader>ff", function()
  require("snacks").picker.files()
end, { desc = "Find files" })
map("n", "<leader>fg", function()
  require("snacks").picker.grep()
end, { desc = "Grep files" })
map("n", "<leader>fb", function()
  require("snacks").picker.buffers()
end, { desc = "Find buffers" })
map("n", "<leader>fr", function()
  require("snacks").picker.recent()
end, { desc = "Recent files" })
map("n", "<leader>fs", function()
  require("snacks").picker.lsp_symbols()
end, { desc = "Document symbols" })

-- LSP (native 0.11 defaults grn/grr/gri/gra are documented, not remapped)
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover" })

-- terminal mode (single <Esc> still reaches the program; double <Esc> leaves)
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
map("t", "<C-h>", [[<C-\><C-n><C-w>h]], { desc = "Terminal: go to left window" })
map("t", "<C-j>", [[<C-\><C-n><C-w>j]], { desc = "Terminal: go to lower window" })
map("t", "<C-k>", [[<C-\><C-n><C-w>k]], { desc = "Terminal: go to upper window" })
map("t", "<C-l>", [[<C-\><C-n><C-w>l]], { desc = "Terminal: go to right window" })
