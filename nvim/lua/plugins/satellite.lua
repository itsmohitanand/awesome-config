-- satellite.nvim — scrollbar that shows where the changes are.
--
-- By the gitsigns author, so the git handler reads gitsigns' own hunk data
-- rather than reimplementing a diff: added/changed/removed lines appear as
-- green/amber/red marks down the scrollbar, giving a whole-file overview
-- without scrolling. Pairs with ]c / [c for jumping between them.
--
-- The bar is drawn as a floating window on the right edge, so it costs no
-- text columns — unlike putting diff info in the signcolumn or statuscolumn.
return {
  'lewis6991/satellite.nvim',
  event = 'BufReadPost',
  opts = {
    -- Bars in every window, not just the focused one: with niri tiling two
    -- files side by side, seeing both change-maps at once is the point.
    current_only = false,
    winblend = 50,
    zindex = 40,
    width = 2,
    excluded_filetypes = {
      'help',
      'lazy',
      'mason',
      'snacks_dashboard',
      'snacks_picker_list',
      'trouble',
      'dapui_scopes',
      'dapui_breakpoints',
      'dapui_stacks',
      'dapui_watches',
      'dap-repl',
    },
    handlers = {
      gitsigns = { enable = true },
      search = { enable = true },
      diagnostic = { enable = true },
      cursor = { enable = true },
      quickfix = { enable = true },
      -- ponytail: marks off. Nothing here sets marks deliberately, so the
      -- handler would only add noise from the automatic ones.
      marks = { enable = false },
    },
  },

  -- Colours come from the theme: satellite derives SatelliteGitSigns{Add,
  -- Change,Delete} from the gutter's GitSigns* groups, so the bar matches the
  -- signs and follows switch-theme for free. Note this theme colours "add"
  -- blue rather than green — intentional, left alone.
}
