return {
  'nvim-treesitter/nvim-treesitter-textobjects',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('nvim-treesitter-textobjects').setup {}
    local ts_select = require 'nvim-treesitter-textobjects.select'
    local ts_move = require 'nvim-treesitter-textobjects.move'

    -- Select textobjects
    vim.keymap.set({ 'x', 'o' }, 'af', function()
      ts_select.select_textobject '@function.outer'
    end, { desc = 'Select outer function' })
    vim.keymap.set({ 'x', 'o' }, 'if', function()
      ts_select.select_textobject '@function.inner'
    end, { desc = 'Select inner function' })
    vim.keymap.set({ 'x', 'o' }, 'ac', function()
      ts_select.select_textobject '@class.outer'
    end, { desc = 'Select outer class' })
    vim.keymap.set({ 'x', 'o' }, 'ic', function()
      ts_select.select_textobject '@class.inner'
    end, { desc = 'Select inner class' })
    vim.keymap.set({ 'x', 'o' }, 'aa', function()
      ts_select.select_textobject '@parameter.outer'
    end, { desc = 'Select outer parameter' })
    vim.keymap.set({ 'x', 'o' }, 'ia', function()
      ts_select.select_textobject '@parameter.inner'
    end, { desc = 'Select inner parameter' })
    vim.keymap.set({ 'x', 'o' }, 'ao', function()
      ts_select.select_textobject '@loop.outer'
    end, { desc = 'Select outer loop' })
    vim.keymap.set({ 'x', 'o' }, 'io', function()
      ts_select.select_textobject '@loop.inner'
    end, { desc = 'Select inner loop' })
    vim.keymap.set({ 'x', 'o' }, 'ab', function()
      ts_select.select_textobject '@block.outer'
    end, { desc = 'Select outer block' })
    vim.keymap.set({ 'x', 'o' }, 'ib', function()
      ts_select.select_textobject '@block.inner'
    end, { desc = 'Select inner block' })
    vim.keymap.set({ 'x', 'o' }, 'ai', function()
      ts_select.select_textobject '@conditional.outer'
    end, { desc = 'Select outer conditional' })
    vim.keymap.set({ 'x', 'o' }, 'ii', function()
      ts_select.select_textobject '@conditional.inner'
    end, { desc = 'Select inner conditional' })
    vim.keymap.set({ 'x', 'o' }, 'a/', function()
      ts_select.select_textobject '@comment.outer'
    end, { desc = 'Select outer comment' })
    vim.keymap.set({ 'x', 'o' }, 'i/', function()
      ts_select.select_textobject '@comment.inner'
    end, { desc = 'Select inner comment' })

    -- Move between textobjects
    vim.keymap.set({ 'n', 'x', 'o' }, ']f', function()
      ts_move.goto_next_start '@function.outer'
    end, { desc = 'Next function start' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']F', function()
      ts_move.goto_next_end '@function.outer'
    end, { desc = 'Next function end' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']c', function()
      ts_move.goto_next_start '@class.outer'
    end, { desc = 'Next class start' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']C', function()
      ts_move.goto_next_end '@class.outer'
    end, { desc = 'Next class end' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']a', function()
      ts_move.goto_next_start '@parameter.inner'
    end, { desc = 'Next parameter' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']A', function()
      ts_move.goto_next_end '@parameter.inner'
    end, { desc = 'Next parameter end' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']l', function()
      ts_move.goto_next_start '@loop.outer'
    end, { desc = 'Next loop start' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']L', function()
      ts_move.goto_next_end '@loop.outer'
    end, { desc = 'Next loop end' })

    vim.keymap.set({ 'n', 'x', 'o' }, '[f', function()
      ts_move.goto_previous_start '@function.outer'
    end, { desc = 'Prev function start' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[F', function()
      ts_move.goto_previous_end '@function.outer'
    end, { desc = 'Prev function end' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[c', function()
      ts_move.goto_previous_start '@class.outer'
    end, { desc = 'Prev class start' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[C', function()
      ts_move.goto_previous_end '@class.outer'
    end, { desc = 'Prev class end' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[a', function()
      ts_move.goto_previous_start '@parameter.inner'
    end, { desc = 'Prev parameter' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[A', function()
      ts_move.goto_previous_end '@parameter.inner'
    end, { desc = 'Prev parameter end' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[l', function()
      ts_move.goto_previous_start '@loop.outer'
    end, { desc = 'Prev loop start' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[L', function()
      ts_move.goto_previous_end '@loop.outer'
    end, { desc = 'Prev loop end' })

    -- NOTE: works poorly, but might be useful
    --
    -- Swap textobjects
    -- local ts_swap = require 'nvim-treesitter-textobjects.swap'
    -- vim.keymap.set('n', '<leader>sa', function() ts_swap.swap_next '@parameter.inner' end, { desc = 'Swap next parameter' })
    -- vim.keymap.set('n', '<leader>sA', function() ts_swap.swap_previous '@parameter.inner' end, { desc = 'Swap prev parameter' })
    -- vim.keymap.set('n', '<leader>sf', function() ts_swap.swap_next '@function.outer' end, { desc = 'Swap next function' })
    -- vim.keymap.set('n', '<leader>sF', function() ts_swap.swap_previous '@function.outer' end, { desc = 'Swap prev function' })
  end,
}
