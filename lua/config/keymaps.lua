local map = vim.keymap.set

-- preserved from the old config
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("n", ";", ":", { desc = "CMD enter command mode" })
-- nvim-lspconfig renamed the texlab commands to a `Lsp` prefix
-- (`TexlabBuild` -> `LspTexlabBuild`). Invoke whichever is defined for the
-- current (texlab-attached) buffer.
map("n", "<leader>tb", function()
  for _, cmd in ipairs { "LspTexlabBuild", "TexlabBuild" } do
    if vim.fn.exists(":" .. cmd) == 2 then
      return vim.cmd(cmd)
    end
  end
  vim.notify("TexlabBuild: no texlab client attached to this buffer", vim.log.levels.WARN)
end, { desc = "Texlab build" })
map("n", "<leader>km", function()
  require("snacks").picker.keymaps()
end, { desc = "Show all keymaps" })

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
