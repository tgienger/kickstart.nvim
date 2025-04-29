local lspconfig = require 'lspconfig'
lspconfig.ols.setup {
  cmd = { 'odin', 'lsp' },
  filetypes = { 'odin' },
  root_dir = lspconfig.util.root_pattern('ols.json', '.git', '*.odin'),
  settings = {
    ols = {
      enable_document_symbols = true,
      enable_semantic_tokens = true,
      enable_document_diagnostics = true,
      enable_hover = true, -- Ensure hover is enabled
    },
  },
}
