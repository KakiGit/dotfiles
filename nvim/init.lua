require("config.lazy")

vim.opt.encoding = "utf-8"
vim.opt.mouse = ""
vim.opt.termguicolors = true
vim.opt.updatetime = 100
vim.opt.number = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.g.mapleader = ","

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    command = "%s/\\s\\+$//e",
})

vim.keymap.set("n", "<C-k>", "<cmd>wincmd k<CR>", { silent = true })
vim.keymap.set("n", "<C-j>", "<cmd>wincmd j<CR>", { silent = true })
vim.keymap.set("n", "<C-h>", "<cmd>wincmd h<CR>", { silent = true })
vim.keymap.set("n", "<C-l>", "<cmd>wincmd l<CR>", { silent = true })

vim.keymap.set("i", "(", "()<Esc>i", {})
vim.keymap.set("i", "{", "{}<Esc>i", {})
vim.keymap.set("i", "{<CR>", "{<CR>}<Esc>O", {})
vim.keymap.set("i", "[", "[]<Esc>i", {})
vim.keymap.set("i", "<", "<><Esc>i", {})
vim.keymap.set("i", "'", "''<Esc>i", {})
vim.keymap.set("i", '"', '""<Esc>i', {})
vim.keymap.set("v", "$1", "<esc>`>a)<esc>`<i(<esc>", {})
vim.keymap.set("v", "$2", "<esc>`>a]<esc>`<i[<esc>", {})
vim.keymap.set("v", "$3", "<esc>`>a}<esc>`<i{<esc>", {})
vim.keymap.set("v", "$$", '<esc>`>a"<esc>`<i"<esc>', {})
vim.keymap.set("v", "$q", "<esc>`>a'<esc>`<i'<esc>", {})
vim.keymap.set("v", "$e", "<esc>`>a`<esc>`<i`<esc>", {})
