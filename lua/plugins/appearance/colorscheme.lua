return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  config = function()
    require('catppuccin').setup {
      flavour = 'mocha', -- latte, frappe, macchiato, mocha
      transparent_background = false,

      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        telescope = true,
        treesitter = true,
        overseer = true,
        notify = true,
        noice = true,
        which_key = true,
        illuminate = true,
        fidget = true,
        mini = true,
        lsp_trouble = true,
        dap = true,
        neotree = true,
        markdown = true,
        mason = true,
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { 'italic' },
            hints = { 'italic' },
            warnings = { 'italic' },
            information = { 'italic' },
          },
          underlines = {
            errors = { 'underline' },
            hints = { 'underline' },
            warnings = { 'underline' },
            information = { 'underline' },
          },
        },
      },
      custom_highlights = function(colors)
        return {
          WhichKeyGroup = { fg = colors.text },
          WhichKeyDesc = { fg = colors.text },
        }
      end,
    }

    vim.cmd.colorscheme 'catppuccin'
  end,
}
