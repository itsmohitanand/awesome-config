require('vim._core.ui2').enable({
  enable = true,
  msg = {
    targets = 'msg',
    msg = {
      timeout = 3000,
    },
  },
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'msg', 'dialog' },
  callback = function()
    vim.wo.winblend = 10
    vim.wo.winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder'
  end,
})
