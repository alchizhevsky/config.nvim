return {
  'saghen/blink.cmp',
  version = '*',

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
        border = {
          { '╭' },
          { '─' },
          { '╮' },
          { '│' },
          { '╯' },
          { '─' },
          { '╰' },
          { '│' },
        },
        draw = {
          padding = 1,
          columns = { { 'kind_icon' }, { 'label', gap = 1 }, { 'kind' } },
        },
      },

      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        window = {
          border = {
            { '╭' },
            { '─' },
            { '╮' },
            { '│' },
            { '╯' },
            { '─' },
            { '╰' },
            { '│' },
          },
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
