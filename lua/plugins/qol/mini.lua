return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }

      require('mini.surround').setup()

      require('mini.comment').setup()

      require('mini.pairs').setup()

      -- require('mini.animate').setup()
      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
