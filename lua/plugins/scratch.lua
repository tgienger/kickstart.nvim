local filetypes = {
  { text = 'odin' },
  { text = 'css' },
  { text = 'go' },
  { text = 'html' },
  { text = 'javascript' },
  { text = 'javascriptreact' },
  { text = 'lua' },
  { text = 'markdown' },
  { text = 'python' },
  { text = 'rust' },
  { text = 'typescript' },
  { text = 'typescriptreact' },
  { text = 'zig' },
  { text = 'odin' },
  { text = 'log' },
}

return {
  'folke/snacks.nvim',
  scratch = {
    enabled = true,
  },
  keys = {
    {
      '<leader>.',
      function()
        print 'working'
        require('utils.snacks.scratch').new_scratch(filetypes)
      end,
      desc = 'Toggle scratch buffer',
    },
  },
}
