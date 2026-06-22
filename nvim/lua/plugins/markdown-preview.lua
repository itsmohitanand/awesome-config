return {
  'iamcco/markdown-preview.nvim',
  cmd = { 'MarkdownPreview', 'MarkdownPreviewStop', 'MarkdownPreviewToggle' },
  ft = { 'markdown' },
  build = 'cd app && npm install',
  init = function()
    vim.g.mkdp_auto_open = 0
    vim.g.mkdp_open_to_the_world = 1  -- listen on 0.0.0.0 so browser can reach it
    vim.g.mkdp_echo_preview_url = 1   -- print the URL in the cmdline
    vim.g.mkdp_open_ip = '127.0.0.1'
  end,
  keys = {
    { '<leader>mp', '<cmd>MarkdownPreviewToggle<cr>', ft = 'markdown', desc = 'Toggle Markdown Preview' },
  },
}
