-- LSP Plugins
return {
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', opts = {} },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      -- This single function handles configuring every buffer when an LSP server attaches
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local bufnr = event.buf
          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- VIRTUAL BUFFER GUARD (Fixes Diffview / non-file clangd panics)
          if client and client.name == 'clangd' then
            local uri = vim.uri_from_bufnr(bufnr)
            if not string.match(uri, '^file://') then
              vim.lsp.buf_detach_client(bufnr, client.id)
              return
            end
          end

          -- Completely disable Neovim 0.11+ default LSP mappings
          pcall(vim.keymap.del, 'n', 'grn')
          pcall(vim.keymap.del, 'n', 'gra')
          pcall(vim.keymap.del, 'n', 'grr')
          pcall(vim.keymap.del, 'n', 'gri')
          pcall(vim.keymap.del, 'n', 'gO')
          pcall(vim.keymap.del, 'n', 'grt')
          pcall(vim.keymap.del, 'n', 'grx')

          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = desc })
          end

          -- 1. GLOBAL / UNIFIED SHORTCUTS
          map('gd', require('telescope.builtin').lsp_definitions, 'Go to Definition')
          map('gr', require('telescope.builtin').lsp_references, 'Go to References')
          map('gI', require('telescope.builtin').lsp_implementations, 'Go to Implementation')
          map('gD', vim.lsp.buf.declaration, 'Go to Declaration')
          map('gt', require('telescope.builtin').lsp_type_definitions, 'Go to Type Definition')
          map('K', vim.lsp.buf.hover, 'Hover Documentation')
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, 'Document Symbols')
          map('<leader>cs', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Workspace Symbols')
          map('<leader>rn', vim.lsp.buf.rename, 'Rename')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code Action', { 'n', 'x' })
          map('<leader>cy', function()
            vim.diagnostic.open_float { border = 'rounded' }
          end, 'Show Line Diagnostics')

          -- Document Highlighting
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- Inlay Hints
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr })
            end, 'Toggle Inlay Hints')
          end

          -- 2. SERVER-SPECIFIC EXTENSIONS
          if client and client.name == 'clangd' then
            map('<leader>ch', function()
              ---@diagnostic disable-next-line: param-type-mismatch
              client:request('textDocument/switchSourceHeader' --[[@as any]], { uri = vim.uri_from_bufnr(bufnr) }, function(err, result)
                if err then
                  vim.notify('LSP Error switching files: ' .. tostring(err.message or err), vim.log.levels.ERROR)
                  return
                end
                if not result then
                  vim.notify('No corresponding source/header found.', vim.log.levels.WARN)
                  return
                end
                vim.api.nvim_command('edit ' .. vim.uri_to_fname(result))
              end, bufnr)
            end, 'Clangd: Switch Source/Header')
          end
        end,
      })

      -- Diagnostic icons setup
      if vim.g.have_nerd_font then
        local signs = { ERROR = '', WARN = '', INFO = '', HINT = '' }
        local diagnostic_signs = {}
        for type, icon in pairs(signs) do
          diagnostic_signs[vim.diagnostic.severity[type]] = icon
        end
        vim.diagnostic.config { signs = { text = diagnostic_signs } }
      end

      -- Register custom filetypes
      vim.filetype.add { extension = { qmljs = 'qmljs' } }

      -- Base Capabilities Setup
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      if capabilities.general then
        capabilities.general.positionEncodings = { 'utf-16' }
      end
      capabilities['offsetEncoding'] = { 'utf-16' }

      -- Native Neovim Server Configurations
      vim.lsp.config('clangd', {
        capabilities = vim.tbl_deep_extend('force', capabilities, {
          positionEncodings = { 'utf-16' },
        }),
        cmd = {
          'clangd',
          '--background-index',
          '--clang-tidy',
          '--header-insertion=never',
          '--enable-config',
          '--completion-style=detailed',
          '--function-arg-placeholders',
          '--fallback-style=llvm',
          '--query-driver=/usr/bin/ccache,/opt/x-tools/**/*,/opt/android-*/**/*',
        },
      })

      vim.lsp.config('lua_ls', {
        capabilities = capabilities,
        settings = {
          Lua = {
            codeLens = { enable = true },
            hint = { enable = true, semicolon = 'Disable' },
            diagnostics = {
              globals = { 'vim', 'hl' },
            },
          },
        },
      })

      vim.lsp.config('pyright', {
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = 'openFilesOnly',
              useLibraryCodeForTypes = true,
            },
          },
        },
      })

      vim.lsp.config('qmlls', { capabilities = capabilities })

      -- Force LSP offsetEncoding override safely without field injection warnings
      local _publish_diagnostics = vim.lsp.diagnostic.on_publish_diagnostics
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.lsp.diagnostic.on_publish_diagnostics = function(err, result, ctx, config)
        if result then
          result['offsetEncoding'] = 'utf-16'
        end
        _publish_diagnostics(err, result, ctx, config)
      end

      -- Setup Mason tools
      local ensure_installed = {}
      vim.list_extend(ensure_installed, { 'stylua', 'clang-format' })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason').setup()
      require('mason-lspconfig').setup {
        ensure_installed = { 'clangd', 'pyright', 'lua_ls', 'bashls', 'qmlls' },
      }

      -- Custom Commands
      vim.api.nvim_create_user_command('LspInfo', 'checkhealth vim.lsp', {})
      vim.api.nvim_create_user_command('LspLog', function()
        vim.cmd('edit ' .. vim.lsp.log.get_filename())
      end, {})
      vim.api.nvim_create_user_command('LspRestart', function()
        local clients = vim.lsp.get_clients()
        for _, client in ipairs(clients) do
          client:stop()
        end
        vim.notify('LSP clients stopped. Re-open buffer or edit file to restart.', vim.log.levels.INFO)
      end, { desc = 'Restart all active LSP clients' })
    end,
  },
}
