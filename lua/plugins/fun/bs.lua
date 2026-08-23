return {
  'seandewar/bad-apple.nvim',
  'Eandrju/cellular-automaton.nvim',
  'AndrewRadev/dealwithit.vim',
  {
    'giusgad/pets.nvim',
    dependencies = { 'MunifTanjim/nui.nvim', 'giusgad/hologram.nvim' },
    init = function()
      require('pets').setup {}
    end,
  },
}
