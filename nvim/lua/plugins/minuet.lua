return {
  'milanglacier/minuet-ai.nvim',
  config = function()
    require('minuet').setup({
      provider = 'openai',
      n_completions = 1,
      context_window = 8192,
      throttle = 1500,
      debounce = 400,
      request_timeout = 10,
      notify = 'warn',
      provider_options = {
        openai = {
          -- name of the env var, not the key itself
          api_key = 'OPENAI_API_KEY',
          model = 'gpt-4.1-mini',
          optional = {
            max_tokens = 256,
            top_p = 0.9,
          },
        },
      },
    })
  end,
}
