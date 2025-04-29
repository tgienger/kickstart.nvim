return {
  'folke/snacks.nvim',
  terminal = {
    win = {
      wo = {
        winbar = '',
      },
    },
    enabled = true,
    keys = {
      q = 'hide',
      gf = function(self)
        local f = vim.fn.findfile(vim.fn.expand '<cfile>', '**')
        if f == '' then
          Snacks.notify.warn 'No file under cursor'
        else
          self:hide()
          vim.schedule(function()
            vim.cmd('e ' .. f)
          end)
        end
      end,
      term_normal = {
        '<Esc><Esc>',
        '<C-\\><C-n>',
        mode = 't',
        expr = true,
        desc = 'Double escape to normal mode',
      },
    },
  },
}
