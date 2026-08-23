--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = true

require 'options'

require 'keymaps'

require 'lazy-bootstrap'

require 'lazy-plugins'

-- TODO: avoid this and make conform itself choose clang-format instead of clangd
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('force-disable-clangd-format', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.name == 'clangd' then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end
  end,
})

-- vim.ts=2 sts=2 sw=2 et=false
