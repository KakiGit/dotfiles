return {
  "airblade/vim-gitgutter",
  init = function()
    vim.g.gitgutter_enabled = 1
    vim.g.gitgutter_signs = 1
    vim.o.updatetime = 100
    vim.cmd.highlight("GitGutterAdd    guifg=#000000 ctermfg=2")
    vim.cmd.highlight("GitGutterChange guifg=#000000 ctermfg=3")
    vim.cmd.highlight("GitGutterDelete guifg=#000000 ctermfg=1")
  end,
}
