return {
  {
    'TabbyML/vim-tabby',
    lazy = false,
    dependencies = {
      'neovim/nvim-lspconfig',
    },
    init = function()
      -- Tells the plugin how to run the background agent via stdio
      vim.g.tabby_agent_start_command = { 'npx', 'tabby-agent', '--stdio' }
      -- Enables automatic ghost-text inline completions as you type
      vim.g.tabby_inline_completion_trigger = 'auto'
    end,
  },
}
