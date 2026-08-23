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

local function load_secret()
  local secret_file = vim.fn.stdpath 'config' .. '/minuet-secret.json'
  if vim.fn.filereadable(secret_file) == 1 then
    local content = vim.fn.readfile(secret_file)
    local ok, decoded = pcall(vim.json.decode, table.concat(content, '\n'))
    if ok then
      return decoded
    end
  end
  return {}
end

local secret = load_secret()

return {
  'milanglacier/minuet-ai.nvim',
  branch = 'main',
  dependencies = { 'saghen/blink.cmp' },
  opts = {
    provider = 'openai_compatible',
    notify = 'error',
    -- NOTE: keep this timeout in sync with blink.cmp
    request_timeout = 8,
    throttle = 2000,
    debounce = 800,
    n_completions = 1,
    context_window = 16000,
    add_single_line_entry = false,

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
        end_point = secret.end_point,
        model = 'qwen3.6:35b',
        stream = true,
        api_key = function()
          return secret.api_key
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

    vim.api.nvim_create_user_command('MinuetEnable', function()
      set_enabled(true)
    end, { desc = 'Enable Minuet AI' })

    vim.api.nvim_create_user_command('MinuetDisable', function()
      set_enabled(false)
    end, { desc = 'Disable Minuet AI' })
  end,
}
