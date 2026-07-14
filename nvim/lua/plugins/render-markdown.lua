return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  ft = { 'markdown' },
  opts = {
    render_modes = { 'n', 'v', 'V', 'i', 'c' },
    anti_conceal = { enabled = true },
    heading = {
      enabled     = true,
      sign        = false,
      position    = 'overlay',
      width       = 'block',
      left_pad    = 1,
      right_pad   = 2,
      icons       = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
      backgrounds = {
        'RenderMarkdownH1Bg', 'RenderMarkdownH2Bg', 'RenderMarkdownH3Bg',
        'RenderMarkdownH4Bg', 'RenderMarkdownH5Bg', 'RenderMarkdownH6Bg',
      },
      foregrounds = {
        'RenderMarkdownH1', 'RenderMarkdownH2', 'RenderMarkdownH3',
        'RenderMarkdownH4', 'RenderMarkdownH5', 'RenderMarkdownH6',
      },
    },
    code = {
      enabled          = true,
      sign             = false,
      style            = 'full',
      width            = 'block',
      left_pad         = 1,
      right_pad        = 1,
      border           = 'thin',
      language_pad     = 1,
      highlight        = 'RenderMarkdownCode',
      highlight_inline = 'RenderMarkdownCodeInline',
      highlight_border = 'RenderMarkdownCodeBorder',
    },
    dash = {
      enabled   = true,
      icon      = '─',
      width     = 'full',
      highlight = 'RenderMarkdownDash',
    },
    bullet = {
      enabled   = true,
      icons     = { '◆ ', '◇ ', '◈ ', '◉ ' },
      highlight = 'RenderMarkdownBullet',
    },
    checkbox = {
      enabled   = true,
      position  = 'inline',
      unchecked = { icon = '󰄱 ', highlight = 'RenderMarkdownUnchecked' },
      checked   = { icon = '󰱒 ', highlight = 'RenderMarkdownChecked' },
      custom    = {
        todo = { raw = '[-]', rendered = '󰥔 ', highlight = 'RenderMarkdownTodo' },
      },
    },
    quote = {
      enabled   = true,
      icon      = '▋',
      highlight = 'RenderMarkdownQuote',
    },
    pipe_table = {
      enabled             = true,
      preset              = 'round',
      alignment_indicator = '━',
      head                = 'RenderMarkdownTableHead',
      row                 = 'RenderMarkdownTableRow',
      filler              = 'RenderMarkdownTableFill',
    },
    link = {
      enabled   = true,
      image     = '󰥶 ',
      email     = '󰀓 ',
      hyperlink = '󰌹 ',
      highlight = 'RenderMarkdownLink',
    },
  },
  config = function(_, opts)
    require('render-markdown').setup(opts)

    -- Vibrant Custom accents (electric blue / purple / neon green / orange),
    -- but backgrounds are the accent blended 15% into everblush's actual
    -- Normal bg (#141b1e) so heading bands sit on the theme instead of
    -- floating a mismatched slate-blue patch on top of it.
    local hl = vim.api.nvim_set_hl
    hl(0, 'RenderMarkdownH1',   { fg = '#0EA5E9', bold = true })
    hl(0, 'RenderMarkdownH1Bg', { bg = '#13303c' })
    hl(0, 'RenderMarkdownH2',   { fg = '#8B5CF6', bold = true })
    hl(0, 'RenderMarkdownH2Bg', { bg = '#26253e' })
    hl(0, 'RenderMarkdownH3',   { fg = '#10B981', bold = true })
    hl(0, 'RenderMarkdownH3Bg', { bg = '#13332d' })
    hl(0, 'RenderMarkdownH4',   { fg = '#F59E0B', bold = true })
    hl(0, 'RenderMarkdownH4Bg', { bg = '#362f1b' })
    hl(0, 'RenderMarkdownH5',   { fg = '#38BDF8', bold = true })
    hl(0, 'RenderMarkdownH5Bg', { bg = '#19333f' })
    hl(0, 'RenderMarkdownH6',   { fg = '#A78BFA', bold = true })
    hl(0, 'RenderMarkdownH6Bg', { bg = '#2a2c3f' })

    -- Everblush's own elevated surface (matches selection_background),
    -- not a foreign slate tone — this is what actually makes code blocks
    -- read as "lifted" rather than "wrong hue".
    hl(0, 'RenderMarkdownCode',       { bg = '#2d3437' })
    hl(0, 'RenderMarkdownCodeInline', { bg = '#232a2d', fg = '#10B981' })
    hl(0, 'RenderMarkdownCodeBorder', { fg = '#2d3437', bg = '#2d3437' })

    hl(0, 'RenderMarkdownDash',      { fg = '#2d3437' })
    hl(0, 'RenderMarkdownBullet',    { fg = '#0EA5E9' })
    hl(0, 'RenderMarkdownQuote',     { fg = '#8B5CF6' })
    hl(0, 'RenderMarkdownUnchecked', { fg = '#767a7c' })
    hl(0, 'RenderMarkdownChecked',   { fg = '#10B981' })
    hl(0, 'RenderMarkdownTodo',      { fg = '#F59E0B' })

    hl(0, 'RenderMarkdownTableHead', { fg = '#0EA5E9', bold = true })
    hl(0, 'RenderMarkdownTableRow',  { fg = '#dadada' })
    hl(0, 'RenderMarkdownTableFill', { fg = '#2d3437' })

    hl(0, 'RenderMarkdownLink', { fg = '#0EA5E9', underline = true })
  end,
}
