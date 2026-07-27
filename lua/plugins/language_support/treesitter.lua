return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  main = 'nvim-treesitter',
  opts = {
    -- List every language parser you want installed ahead of time
    ensure_installed = {
      'bash',
      'c',
      'cpp',
      'diff',
      'fish',
      'go',
      'html',
      'lua',
      'luadoc',
      'markdown',
      'markdown_inline',
      'python',
      'rust',
    },
  },
  config = function(_, opts)
    require('nvim-treesitter').setup(opts)

    -- Auto-install missing parsers from the list above on startup
    if opts.ensure_installed then
      local installed = require('nvim-treesitter.config').get_installed()
      local to_install = vim
        .iter(opts.ensure_installed)
        :filter(function(p)
          return not vim.tbl_contains(installed, p)
        end)
        :totable()
      if #to_install > 0 then
        require('nvim-treesitter').install(to_install)
      end
    end

    -- Enable Treesitter highlighting on open files
    vim.api.nvim_create_autocmd('FileType', {
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
