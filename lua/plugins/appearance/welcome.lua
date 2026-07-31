return {
  'goolord/alpha-nvim',
  lazy = false,
  dependencies = {
    'echasnovski/mini.icons',
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('alpha').setup(require('alpha.themes.theta').config)
  end,
}
