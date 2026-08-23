return {
  'CRAG666/code_runner.nvim',
  config = function()
    local ok, runner = pcall(require, 'code_runner')
    if not ok then
      return
    end

    runner.setup {
      mode = 'float',
      float = {
        border = 'rounded',
        height = 0.8,
        width = 0.8,
        x = 0.5,
        y = 0.5,
        border_hl = 'FloatBorder',
        blend = 5,
      },
      focus = true,
      startinsert = false,
      filetype = {
        python = 'python3 -u $file',
        cpp = 'clang++ $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt',
        c = 'gcc $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt',
        go = 'go run $file',
        rust = 'cargo run',
        sh = 'bash $file',
        lua = 'lua $file',
      },
    }

    local function run_and_focus()
      vim.cmd 'RunCode'
      vim.defer_fn(function()
        -- Look for the latest floating terminal window
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.bo[buf].filetype
          if ft == 'terminal' then
            vim.api.nvim_set_current_win(win)
            vim.cmd 'startinsert' -- optional: auto into insert mode

            -- Move cursor to bottom of buffer
            local line_count = vim.api.nvim_buf_line_count(buf)
            vim.api.nvim_win_set_cursor(win, { line_count, 0 })
            break
          end
        end
      end, 200) -- wait a bit for the float to open
    end

    vim.keymap.set('n', '<leader>os', run_and_focus, { desc = 'Run current file and focus float' })
    vim.keymap.set('v', '<leader>os', run_and_focus, { desc = 'Run selected code in float' })
  end,
}
