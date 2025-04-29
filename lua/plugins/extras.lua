-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  { 'j-hui/fidget.nvim' },
  { 'nvim-lua/plenary.nvim' }, -- Ensure dependency is loaded first
  -- {
  --   name = "Grok",
  --   dir = vim.fn.expand("~/AppData/Local/nvim/lua/custom/grok"),
  --   dev = true,
  --   opts = { api_key = "xai-PfJZ058O8P3C2AxLJmgR3dAqu6nXrSL4mVer9260pyULyfNlPBDbdE5IRQq3h12AbuheQBGUbOejenZk" },
  --   dependencies = { "nvim-lua/plenary.nvim" },
  --   lazy = false,
  --   config = function(_, opts)
  --     require("custom.grok").setup(opts)
  --   end,
  --   -- keys = {
  --   --   { "<leader>g", "<Cmd>Grok<CR>", mode = "n", desc = "Ask Grok a question" },
  --   --   { "<leader>gf", "<Cmd>Grok!<CR>", mode = "n", desc = "Ask Grok a question about current file" },
  --   --   { "<leader>g", ":<C-u>normal! gv<CR>:Grok<CR>", mode = "v", desc = "Ask Grok about selection" },
  --   --   { "<leader>gh", "<Cmd>GrokHistory<CR>", mode = "n", desc = "Show Grok chat history" },
  --   --   { "<leader>gc", "<Cmd>GrokChat<CR>", mode = "n", desc = "Open most recent Grok chat" },
  --   --   { "<leader>gn", "<Cmd>GrokNewChat<CR>", mode = "n", desc = "Start a new Grok chat" },
  --   --   { "<leader>gC", "<Cmd>GrokClearHistory<CR>", mode = "n", desc = "Clear all Grok chat history" },
  --   -- },
  -- },
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    -- Optional dependencies
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
  {
    'brenoprata10/nvim-highlight-colors',
    config = function()
      require('nvim-highlight-colors').setup {
        render = 'virtual', -- Use 'virtual' for squares instead of background/foreground
        virtual_symbol = '■', -- The square symbol (you can change this)
        virtual_symbol_prefix = '', -- Optional: spacing before the square
        virtual_symbol_suffix = ' ', -- Optional: spacing after the square
      }
    end,
  },
  -- {
  --   'Shatur/neovim-session-manager',
  -- },
  { 'nvim-telescope/telescope-ui-select.nvim' },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = true,
    -- use opts = {} for passing setup options
    -- this is equivalent to setup({}) function
  },
  -- {
  --   'Exafunction/windsurf.vim',
  --   config = function ()
  --     -- Change '<C-g>' here to any keycode you like.
  --     vim.keymap.set('i', '<C-g>', function () return vim.fn['codeium#Accept']() end, { expr = true, silent = true })
  --     vim.keymap.set('i', '<c-;>', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true, silent = true })
  --     vim.keymap.set('i', '<c-,>', function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true, silent = true })
  --     vim.keymap.set('i', '<c-x>', function() return vim.fn['codeium#Clear']() end, { expr = true, silent = true })
  --   end
  -- },
  -- add this to the file where you setup your other plugins:
  -- lazy.nvim
  {
    'monkoose/neocodeium',
    event = 'VeryLazy',
    config = function()
      local neocodeium = require 'neocodeium'
      neocodeium.setup()
      vim.keymap.set('i', '<Tab>', neocodeium.accept)
    end,
  },
  -- {
  --   'NeogitOrg/neogit',
  --   dependencies = {
  --     'nvim-lua/plenary.nvim', -- required
  --     'sindrets/diffview.nvim', -- optional - Diff integration
  --
  --     -- Only one of these is needed.
  --     'nvim-telescope/telescope.nvim', -- optional
  --     -- "ibhagwan/fzf-lua",              -- optional
  --     -- "echasnovski/mini.pick",         -- optional
  --   },
  --   config = true,
  -- },
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup { settings = {
        save_on_ui_close = true,
      } }

      local harpoon_extensions = require 'harpoon.extensions'
      harpoon:extend(harpoon_extensions.builtins.highlight_current_file())

      vim.keymap.set('n', '<leader>a', function()
        harpoon:list():add()
      end)
      vim.keymap.set('n', '<C-e>', function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)

      vim.keymap.set('n', '<leader>1', function()
        harpoon:list():select(1)
      end)
      vim.keymap.set('n', '<leader>2', function()
        harpoon:list():select(2)
      end)
      vim.keymap.set('n', '<leader>3', function()
        harpoon:list():select(3)
      end)
      vim.keymap.set('n', '<leader>4', function()
        harpoon:list():select(4)
      end)
      vim.keymap.set('n', '<leader>5', function()
        harpoon:list():select(5)
      end)

      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set('n', '<C-S-P>', function()
        harpoon:list():prev()
      end)
      vim.keymap.set('n', '<C-S-N>', function()
        harpoon:list():next()
      end)
    end,
  },
}
