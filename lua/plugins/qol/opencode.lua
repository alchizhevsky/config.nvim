return {
  'nickjvandyke/opencode.nvim',
  version = '*',
  dependencies = { 'folke/snacks.nvim' },
  config = function()
    local port = 10000 + vim.fn.getpid() % 50000
    local opencode_cmd = 'opencode --port ' .. port
    local terminal_opts = {
      cwd = vim.fn.getcwd(),
      interactive = false,
      win = {
        position = 'right',
        enter = false,
      },
    }

    local function get_terminal(create)
      return require('snacks.terminal').get(opencode_cmd, vim.tbl_extend('force', terminal_opts, { create = create ~= false }))
    end

    local function start_hidden()
      local terminal, created = get_terminal(true)
      if terminal and created then
        terminal:hide()
      end
    end

    local function show_terminal()
      local terminal = get_terminal(false)
      if terminal then
        terminal:show()
      end
    end

    vim.g.opencode_opts = {
      server = {
        url = 'http://127.0.0.1:' .. port,
        start = start_hidden,
      },
    }

    local function visual_range()
      local mode = vim.fn.mode()
      local kind = (mode == 'V' and 'line') or (mode == 'v' and 'char') or (mode == '\22' and 'block')
      if not kind then
        return nil
      end

      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', true)
      local from = vim.api.nvim_buf_get_mark(0, '<')
      local to = vim.api.nvim_buf_get_mark(0, '>')
      if from[1] > to[1] or (from[1] == to[1] and from[2] > to[2]) then
        from, to = to, from
      end

      return {
        from = { from[1], from[2] },
        to = { to[1], to[2] },
        kind = kind,
      }
    end

    local function with_context(callback)
      local source_win = vim.api.nvim_get_current_win()
      local range = visual_range()

      require('opencode.server.discovery')
        .get()
        :next(function(server)
          if not vim.api.nvim_win_is_valid(source_win) then
            return require('opencode.promise').reject 'Source window is no longer available'
          end

          local context
          vim.api.nvim_win_call(source_win, function()
            context = require('opencode.context').new(server, range)
          end)
          return callback(context)
        end)
        :next(function(result)
          show_terminal()
          return result
        end)
        :catch(function(err)
          if err then
            vim.notify(err, vim.log.levels.ERROR, { title = 'opencode' })
          end
        end)
    end

    local function ask()
      with_context(function(context)
        return require('opencode.ui.ask').ask('@this: ', context):next(function(input)
          return require('opencode.api.prompt').prompt(input, context)
        end)
      end)
    end

    local function select_action()
      with_context(function(context)
        return require('opencode.ui.select').select(context)
      end)
    end

    local function prompt(text)
      with_context(function(context)
        return require('opencode.api.prompt').prompt(text, context)
      end)
    end

    vim.schedule(start_hidden)

    vim.keymap.set('n', '<leader>ia', ask, { desc = '[I] AI ask OpenCode' })
    vim.keymap.set({ 'n', 'x' }, '<leader>is', select_action, { desc = '[I] AI select OpenCode action' })
    vim.keymap.set('n', '<leader>it', function()
      require('snacks.terminal').toggle(opencode_cmd, terminal_opts)
    end, { desc = '[I] AI toggle OpenCode' })
    vim.keymap.set('x', '<leader>id', function()
      prompt 'Add useful documentation comments to @this. Edit the file directly.'
    end, { desc = '[I] AI document selection' })
    vim.keymap.set('x', '<leader>ie', function()
      prompt 'Explain @this and its surrounding context. Do not edit the file.'
    end, { desc = '[I] AI explain selection' })
    vim.keymap.set('x', '<leader>ir', function()
      prompt 'Refactor @this for correctness, readability, and maintainability. Edit the file directly.'
    end, { desc = '[I] AI refactor selection' })
  end,
}
