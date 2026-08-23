return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  build = ':TSUpdate',
  opts = {
    ensure_installed = {
      'bash',
      'c',
      'cpp',
      'comment',
      'diff',
      'fish',
      'go',
      'html',
      'lua',
      'luadoc',
      'markdown',
      'markdown_inline',
      'python',
      'query',
      'rust',
    },
    auto_install = true,
    highlight = {
      enable = true,
    },
  },
}
