return {
  'milanglacier/minuet-ai.nvim',
  config = function()
    require('minuet').setup({
      provider = 'openai_fim_compatible',
      n_completions = 1,
      context_window = 8192,
      throttle = 1500,
      debounce = 400,
      request_timeout = 10,
      notify = 'warn',
      provider_options = {
        openai_fim_compatible = {
          api_key = 'TERM',
          name = 'Ollama',
          end_point = 'http://localhost:11434/v1/completions',
          model = 'deepseek-coder-v2:lite',
          optional = {
            max_tokens = 256,
            top_p = 0.9,
          },
        },
      },
    })
  end,
}
