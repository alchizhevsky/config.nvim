return {
  'milanglacier/minuet-ai.nvim',
  branch = 'main',
  -- minuet uses blink.cmp as its frontend
  dependencies = { 'saghen/blink.cmp' },
  opts = {
    -- aktiv's qwen3.6:35b is reasonably fast for inline completion
    provider = 'openai_compatible',
    request_timeout = 8,
    throttle = 2000,
    debounce = 800,
    n_completions = 1,
    context_window = 16000,
    add_single_line_entry = false, -- to test function generation
    blink = {
      enable_auto_complete = true,
    },
    provider_options = {
      openai_compatible = {
        name = 'qwen3',
        end_point = 'https://ai.aktivco.ru/api/v1/chat/completions',
        model = 'qwen3.6:35b',
        stream = true,
        api_key = function()
          return 'sk-828081e451cc4366b6cf16004bb67dc0'
        end,
        optional = {
          max_tokens = 512,
          top_p = 0.9,
        },
      },
    },
  },
}
