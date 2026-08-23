return {
  'sindrets/diffview.nvim',
  opts = {
    -- TODO: check if necessary
    default_args = {
      DiffviewOpen = { '--imply-local' },
    },

    -- TODO: make floating
    file_panel = {
      listing_style = 'tree',
      win_config = {
        position = 'bottom',
        height = 10,
      },
    },

    file_history_panel = {
      win_config = {
        position = 'bottom',
        height = 10,
      },
    },

    keymaps = {
      -- TODO: check if <leader b> is the same not only in cpp
      file_panel = {
        {
          'n',
          '<leader>e',
          function()
            require('diffview.actions').toggle_files()
          end,
          { desc = 'Toggle file panel' },
        },
        {
          'n',
          'q',
          function()
            require('diffview.actions').toggle_files()
          end,
          { desc = 'Close file panel' },
        },
      },
    },
  },
}
