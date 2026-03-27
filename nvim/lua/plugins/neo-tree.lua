return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
       "nvim-lua/plenary.nvim",
       "MunifTanjim/nui.nvim",
       "nvim-tree/nvim-web-devicons", -- optional, but recommended
    },
    lazy = false,
    keys = {
      { "<leader>nf", "<cmd>Neotree reveal<cr>", desc = "Reveal current file in Neo-tree" },
    },
    opts = {
        event_handlers = {
          {
            event = "neo_tree_window_after_open",
            handler = function(args)
              if args.position == "left" or args.position == "right" then
                vim.cmd("wincmd =")
              end
            end
          },
          {
            event = "neo_tree_window_after_close",
            handler = function(args)
              if args.position == "left" or args.position == "right" then
                vim.cmd("wincmd =")
              end
            end
          }
       },
    },
}
