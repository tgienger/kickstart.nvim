vim.o.foldcolumn = '1'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99

vim.o.foldenable = true

-- vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = 'Open all folds' })
-- vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = 'Close all folds' })
-- vim.keymap.set('n', 'zK', function()
--   local winid = require('ufo').peekFoldedLineUnderCursor()
--   if not winid then
--     vim.lsp.buf.hover()
--   end
-- end, { desc = 'Preview fold' })
--
-- require('ufo').setup {
--   provider_selector = function(bufnr, filetype, buftype)
--     return { 'lsp', 'indent' }
--   end,
-- }
