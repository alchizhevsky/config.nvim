local state_file = vim.fn.stdpath 'state' .. '/minuet_enabled'

local function is_enabled()
  return vim.fn.filereadable(state_file) == 1
end

local function set_enabled(enable)
  if enable then
    vim.fn.writefile({}, state_file)
    vim.notify('Minuet AI Enabled', vim.log.levels.INFO)
  else
    vim.fn.delete(state_file)
    vim.notify('Minuet AI Disabled', vim.log.levels.WARN)
  end
end

return {
  'milanglacier/minuet-ai.nvim',
  branch = 'main',
  dependencies = { 'saghen/blink.cmp' },
  opts = {
    provider = 'openai_compatible',
    request_timeout = 8,
    throttle = 2000,
    debounce = 800,
    n_completions = 1,
    context_window = 16000,
    add_single_line_entry = false,
    -- Use predicate function instead of the deprecated `enabled` boolean flag
    enable_predicates = {
      function()
        return is_enabled()
      end,
    },
    blink = {
      enable_auto_complete = true,
    },
    provider_options = {
      openai_compatible = {
        name = 'qwen3',
        end_point = 'link',
        model = 'qwen3.6:35b',
        stream = true,
        api_key = function()
          return 'KEY'
        end,
        optional = {
          max_tokens = 512,
          top_p = 0.9,
        },
      },
    },
  },
  config = function(_, opts)
    require('minuet').setup(opts)

    -- Commands to toggle state persistently
    vim.api.nvim_create_user_command('MinuetToggle', function()
      set_enabled(not is_enabled())
    end, { desc = 'Toggle Minuet AI inline completion persistently' })

    vim.api.nvim_create_user_command('MinuetEnable', function()
      set_enabled(true)
    end, { desc = 'Enable Minuet AI' })

    vim.api.nvim_create_user_command('MinuetDisable', function()
      set_enabled(false)
    end, { desc = 'Disable Minuet AI' })
  end,
}
