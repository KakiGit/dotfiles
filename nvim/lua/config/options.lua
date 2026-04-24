vim.opt.encoding = "utf-8"
vim.opt.mouse = ""
vim.opt.updatetime = 100
vim.opt.number = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.cmd("set t_Co=256")

vim.g.mapleader = ","

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    command = "%s/\\s\\+$//e",
})
