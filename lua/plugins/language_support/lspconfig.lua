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
    -- event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'williamboman/mason.nvim', opts = {} },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      -- WARN: worked fine with cmp-nvim-lsp, trying blink
      -- 'hrsh7th/cmp-nvim-lsp',
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

          -- Fix overlaping
          -- Add this near the top of your LSP config callback function
          pcall(vim.keymap.del, 'n', 'grr', { buffer = bufnr })
          pcall(vim.keymap.del, 'n', 'grn', { buffer = bufnr })
          pcall(vim.keymap.del, 'n', 'gra', { buffer = bufnr })
          pcall(vim.keymap.del, 'n', 'gri', { buffer = bufnr })
          pcall(vim.keymap.del, 'n', 'grx', { buffer = bufnr })
          pcall(vim.keymap.del, 'n', 'grt', { buffer = bufnr })
          -- Helper to easily define mappings local to the current LSP buffer
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
          end

          -- =================================================================
          -- 1. GLOBAL / UNIFIED SHORTCUTS (Works everywhere via abstraction)
          -- =================================================================
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('K', vim.lsp.buf.hover, 'Hover Documentation')
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

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
            end, '[T]oggle Inlay [H]ints')
          end

          -- =================================================================
          -- 2. SERVER-SPECIFIC EXTENSIONS (Safely sandboxed)
          -- =================================================================
          if client and client.name == 'clangd' then
            -- Uses client:request directly to isolate execution to clangd only
            map('<leader>ch', function()
              client:request('textDocument/switchSourceHeader', { uri = vim.uri_from_bufnr(bufnr) }, function(err, result)
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

      -- Native Neovim 0.11+ Server Configurations
      vim.lsp.config('clangd', {
        capabilities = vim.tbl_deep_extend('force', capabilities, {
          positionEncodings = { 'utf-16' },
        }),
        cmd = {
          'clangd',
          '--background-index',
          '--clang-tidy',
          -- '--header-insertion=iwyu',
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

      -- Force LSP to use a specific offset encoding for all clients
      local _publish_diagnostics = vim.lsp.diagnostic.on_publish_diagnostics
      vim.lsp.diagnostic.on_publish_diagnostics = function(err, result, ctx, config)
        result.offsetEncoding = 'utf-16' -- or 'utf-8' based on what clangd prefers
        _publish_diagnostics(err, result, ctx, config)
      end

      -- Explicitly set offsetEncoding for your LSP clients
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.offsetEncoding = { 'utf-16' }

      -- Setup Mason tools
      local ensure_installed = {}
      vim.list_extend(ensure_installed, { 'stylua', 'clang-format' })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason').setup()
      require('mason-lspconfig').setup {
        ensure_installed = { 'clangd', 'pyright', 'lua_ls', 'bashls', 'qmlls' },
      }

      -- Auto-enable the servers natively
      -- vim.lsp.enable({ 'clangd', 'pyright', 'lua_ls', 'bashls', 'qmlls' })

      -- HERE: Define the missing commands manually
      vim.api.nvim_create_user_command('LspInfo', 'checkhealth vim.lsp', {})
      vim.api.nvim_create_user_command('LspLog', function()
        vim.cmd('edit ' .. vim.lsp.log.get_filename())
      end, {})
    end,
  },
}
