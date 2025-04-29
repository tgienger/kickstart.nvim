return {
  'rcarriga/nvim-dap-ui',
  dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
  opts = {},
  -- config = function(_, opts)
  --   local dap = require('dapui').setup(opts)
  --
  --   dap.adapters.codelldb = {
  --     type = 'server',
  --     port = '${port}',
  --     executable = {
  --       command = '/path/to/codelldb', -- Adjust to your codelldb installation path
  --       args = { '--port', '${port}' },
  --     },
  --   }
  --
  --   dap.configurations.odin = {
  --     {
  --       name = 'Launch Odin',
  --       type = 'codelldb',
  --       request = 'launch',
  --       program = function()
  --         return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
  --       end,
  --       cwd = '${workspaceFolder}',
  --       stopOnEntry = false,
  --     },
  --   }
  -- end,
}
