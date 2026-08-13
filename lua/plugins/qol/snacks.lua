return {
  'folke/snacks.nvim',
  --move noice notifications to the bottom
  ---@type snacks.Config
  opts = {
    -- Replace native input prompts with Snacks-styled dialogs.
    input = {
      enabled = true,
    },
    -- Enable Snacks' fuzzy finder and picker interfaces.
    picker = {
      enabled = true,
    },
    -- Enable notifications and stack them upward from the bottom.
    notifier = {
      enable = true,
      top_down = false,
    },
  },
}
