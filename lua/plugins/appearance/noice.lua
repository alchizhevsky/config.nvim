return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = {
    'MunifTanjim/nui.nvim',
    -- Removed 'rcarriga/nvim-notify'
  },
  opts = {

    -- Disable Noice's internal notification view so Snacks.notifier renders them
    lsp = {
      signature = {
        enabled = false, -- Disable Noice signature popup so blink.cmp handles it
      },
      hover = {
        enabled = true, -- Keep hover (K) enabled, but it won't auto-popup during completion
      },
      -- ... rest of your noice config
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
