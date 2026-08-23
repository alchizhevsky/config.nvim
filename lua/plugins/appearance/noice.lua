return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = {
    'MunifTanjim/nui.nvim',
  },
  opts = {

    -- Disable Noice's internal notification view so Snacks.notifier renders them
    lsp = {
      signature = {
        enabled = false,
      },
      hover = {
        enabled = true,
      },
    },

    notify = {
      enabled = false,
    },
    cmdline = {
      enabled = true,
      view = 'cmdline_popup',
    },
    views = {
      cmdline_popup = {
        position = { row = 5, col = '50%' },
        size = { width = 60, height = 'auto' },
        border = { style = 'rounded', padding = { 0, 1 } },
      },
      cmdline_popupmenu = {
        relative = 'editor',
        position = { row = 8, col = '50%' },
        size = { width = 60, height = 10 },
        border = { style = 'rounded', padding = { 0, 1 } },
      },
    },
    throttle = 100,
    routes = {
      {
        filter = { event = 'cmdline_hide' },
        opts = { skip = true },
      },
    },
  },
}
