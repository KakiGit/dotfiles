return {
  "joshdick/onedark.vim",
  lazy = false,
  priority = 1000,
  init = function()
    vim.g.airline_theme = "onedark"
  end,
  config = function()
    vim.cmd.colorscheme("onedark")
  end,
}