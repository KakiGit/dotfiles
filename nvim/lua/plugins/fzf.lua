return {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    ---@module "fzf-lua"
    ---@type fzf-lua.Config|{}
    opts = {},
    keys = {
        { "<C-f>", "<cmd>FzfLua files<cr>", mode = "n" },
        { "<C-b>", "<cmd>FzfLua buffers<cr>", mode = "n" },
        { "<leader>8", "<cmd>FzfLua grep<cr><c-r><c-w><cr>", mode = "n" },
        { "<leader>f", "<cmd>FzfLua grep<cr>", mode = "n" },
    },
}
