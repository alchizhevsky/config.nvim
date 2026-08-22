return {
  -- TODO: fix scrollbar
  'saghen/blink.cmp',
  version = '*',

  -- Fix Neovim's native grey scrollbar block for float popups
  init = function()
    vim.api.nvim_set_hl(0, 'PmenuThumb', { link = 'FloatBorder' })
    vim.api.nvim_set_hl(0, 'PmenuSbar', { bg = 'NONE' })
  end,

  opts = {
    keymap = {
      preset = 'enter',
      ['<C-n>'] = { 'select_next', 'fallback' },
      ['<C-p>'] = { 'select_prev', 'fallback' },
      ['<C-y>'] = { 'select_and_accept' },
      ['<C-l>'] = { 'snippet_forward' },
      ['<C-h>'] = { 'snippet_backward' },
    },

    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = 'mono',
    },

    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer', 'minuet' },
      providers = {
        minuet = {
          name = 'minuet',
          module = 'minuet.blink',
          async = true,
          timeout_ms = 3000,
          score_offset = 50,
        },
      },
    },

    completion = {
      menu = {
        border = 'rounded',
        scrollbar = false,
        draw = {
          padding = 1,
          columns = { { 'kind_icon' }, { 'label', gap = 1 }, { 'kind' } },
        },
      },

      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        window = {
          border = 'rounded',
          scrollbar = false,
        },
      },

      trigger = { prefetch_on_insert = false },
    },

    signature = {
      enabled = true,
      window = {
        border = 'rounded',
      },
    },
  },
}
