return {
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {
      indent = {
        char = '▏', -- for spaces
        tab_char = '▏', -- for tabs
      },
      whitespace = {
        highlight = { 'Whitespace' },
      },
    },
  },
}
