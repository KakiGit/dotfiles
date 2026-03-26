return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    ---@module "fzf-lua"
    ---@type fzf-lua.Config|{}
    opts = {},
    keys = {
      { "<C-f>", "<cmd>FzfLua files<cr>", mode = "n" },
      { "<C-b>", "<cmd>FzfLua buffers<cr>", mode = "n" },
    },
  },
}
