vim.env.LAZY_STDPATH = ".repro_minimal"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

vim.opt.number = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.swapfile = false

require("lazy.minit").repro({
  spec = {
    {
      "4513ECHO/nvim-keycastr",
      lazy = false,
      keys = {
        {
          "<C-k>",
          function()
            require("keycastr").disable()
            require("keycastr").enable()
          end,
        },
      },
      config = function()
        require("keycastr").config.set({
          win_config = {
            border = "rounded",
            width = 50,
            height = 1,
          },
          ignore_mouse = true,
          position = "SE",
        })
      end,
    },

    "nvim-lua/plenary.nvim",
    "neovim/nvim-lspconfig",
    {
      "hrsh7th/nvim-cmp",
      dependencies = { "hrsh7th/cmp-nvim-lsp" },
      name = "cmp",
      config = function()
        local cmp = require("cmp")
        local compare = require("cmp.config.compare")
        cmp.setup({
          sources = { { name = "nvim_lsp" } },
          mapping = cmp.mapping.preset.insert({
            ["<C-a>"] = cmp.mapping.complete(),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
          }),
          sorting = {
            priority_weight = 1,
            comparators = {
              compare.sort_text,
            },
          },
        })
      end,
    },
    { "windwp/nvim-autopairs", opts = {} },
    { "windwp/nvim-ts-autotag", opts = {} },
    {
      "nvim-treesitter/nvim-treesitter",
      config = function()
        require("nvim-treesitter.configs").setup({
          auto_install = true,
          ensure_installed = { "javascript" },
          ignore_install = {},
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
          },
        })
      end,
    },
    { dir = vim.uv.cwd() .. "/..", name = "js-i18n.nvim", opts = {} },
  },
})
