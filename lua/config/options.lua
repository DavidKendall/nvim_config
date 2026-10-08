local opt = vim.opt

-- preserved from the old config
opt.clipboard = "unnamedplus"
opt.colorcolumn = "92"
opt.spelllang = "en_gb"

-- modern baseline
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.ignorecase = true
opt.smartcase = true
opt.splitright = true
opt.splitbelow = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.timeoutlen = 300
opt.undofile = true
opt.undodir = vim.fn.stdpath "state" .. "/undo"
vim.fn.mkdir(vim.fn.stdpath "state" .. "/undo", "p")

-- optional providers are unused; silence their health warnings
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
