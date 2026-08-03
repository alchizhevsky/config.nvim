return {
  'saghen/blink.cmp',
  -- Use a release tag to download prebuilt binaries
  version = '*',
  -- Or build from source
  -- build = 'cargo build --release',

  opts = {
    -- 'default' for mappings similar to vscode
    -- 'super-tab' for tab-completion
    -- 'enter' for enter-completion
    keymap = {
      preset = 'enter',
      ['<C-n>'] = { 'select_next', 'fallback' },
      ['<C-p>'] = { 'select_prev', 'fallback' },
      ['<C-y>'] = { 'select_and_accept' },
      ['<C-l>'] = { 'snippet_forward' },
      ['<C-h>'] = { 'snippet_backward' },
    },

    appearance = {
      -- Set to 'mono' for 'Nerd Font' symbols
      use_nvim_cmp_as_default = true,
      nerd_font_variant = 'mono',
    },

    sources = {
      -- Default sources are LSP, path, buffer, snippets, and minuet (AI)
      default = { 'lsp', 'path', 'snippets', 'buffer', 'minuet' },
      providers = {
        minuet = {
          name = 'minuet',
          module = 'minuet.blink',
          async = true,
          -- should match minuet's request_timeout (in ms)
          timeout_ms = 3000,
          score_offset = 50,
        },
      },
    },

    completion = {
      menu = { draw = { columns = { { 'kind_icon' }, { 'label', gap = 1 }, { 'kind' } } } },
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      trigger = { prefetch_on_insert = false },
    },
  },
}
