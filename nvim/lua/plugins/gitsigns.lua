return {
  'lewis6991/gitsigns.nvim',
  event = 'BufReadPost',
  opts = {
    signs = {
      add          = { text = '▎' },
      change       = { text = '▎' },
      delete       = { text = '' },
      topdelete    = { text = '' },
      changedelete = { text = '▎' },
    },
    current_line_blame = true,
    current_line_blame_opts = {
      delay = 300,
      virt_text_pos = 'eol',
    },
  },

  -- The themes set fg only on the diff groups and leave bg equal to Normal, so
  -- linehl produced coloured text on no background — not the GitHub look — and
  -- GitSignsDeleteLn was undefined outright, i.e. invisible. Give the line and
  -- word-diff groups real background tints.
  --
  -- ponytail: one fixed set of tints, because all three themes are dark
  -- (#141b1e / #1B1E28 / #16181a). Needs a per-theme table only if a light one
  -- ever shows up. Re-applied on ColorScheme so switch-theme doesn't drop them.
  config = function(_, opts)
    require('gitsigns').setup(opts)

    local function tint()
      local hl = vim.api.nvim_set_hl
      hl(0, 'GitSignsAddLn', { bg = '#16301f' })
      hl(0, 'GitSignsChangeLn', { bg = '#2b2a16' })
      hl(0, 'GitSignsDeleteLn', { bg = '#3a1d20' })
      hl(0, 'GitSignsDeleteVirtLn', { bg = '#2a1618', fg = '#c25b62' })
      -- Word-level, shown inside the line when word_diff is on. Brighter than
      -- the line tints so they read as "this bit specifically".
      hl(0, 'GitSignsAddInline', { bg = '#24512f' })
      hl(0, 'GitSignsChangeInline', { bg = '#4a4620' })
      hl(0, 'GitSignsDeleteInline', { bg = '#5c2b30' })
      hl(0, 'GitSignsDeleteVirtLnInLine', { bg = '#5c2b30', fg = '#f0a0a5' })
    end

    tint()
    vim.api.nvim_create_autocmd('ColorScheme', { callback = tint })
  end,
  keys = {
    -- nav_hunk, not the older next_hunk/prev_hunk, because it takes options:
    -- wrap so the last hunk cycles to the first instead of dead-ending, and
    -- preview so the change shows inline the moment you land on it — no
    -- separate keypress to see what you jumped to.
    -- target='all' matters once the base is HEAD: staged hunks still count.
    {
      ']c',
      function() require('gitsigns').nav_hunk('next', { wrap = true, preview = true, target = 'all' }) end,
      desc = 'Next hunk',
    },
    {
      '[c',
      function() require('gitsigns').nav_hunk('prev', { wrap = true, preview = true, target = 'all' }) end,
      desc = 'Prev hunk',
    },
    { '<leader>gb', function() require('gitsigns').blame_line({ full = true }) end, desc = 'Blame line' },
    { '<leader>gp', function() require('gitsigns').preview_hunk() end,             desc = 'Preview hunk' },
    { '<leader>gs', function() require('gitsigns').stage_hunk() end,               desc = 'Stage hunk' },
    { '<leader>gr', function() require('gitsigns').reset_hunk() end,               desc = 'Reset hunk' },

    -- Inline diff, in the buffer you're editing — no second window, no
    -- side-by-side. diffview (<leader>gd) is the split view when you want it.
    --
    -- gi renders one hunk inline where it sits; gv shows every deletion in the
    -- file as virtual lines and stays on while you edit, which is the closest
    -- thing to "see the changes and fix them in place".
    { '<leader>gi', function() require('gitsigns').preview_hunk_inline() end,      desc = 'Preview hunk inline' },
    { '<leader>gv', function() require('gitsigns').toggle_deleted() end,           desc = 'Toggle deleted lines inline' },
    { '<leader>gw', function() require('gitsigns').toggle_word_diff() end,         desc = 'Toggle word diff' },

    -- The GitHub/GitLab unified view, in the buffer you're editing. Three
    -- gitsigns toggles do it together:
    --   deleted   -> removed lines reappear as red virtual lines
    --   linehl    -> added/changed lines get a green/amber background
    --   word_diff -> the changed words inside a line are picked out
    --
    -- It also switches the diff base to HEAD. gitsigns compares against the
    -- INDEX by default, so anything already staged stops showing as changed —
    -- which is why the gutter can look clean on a file you've clearly edited.
    -- "What changed since the last commit" means HEAD, not index.
    {
      '<leader>gu',
      function()
        local gs = require('gitsigns')
        local on = not vim.g.gitsigns_unified
        vim.g.gitsigns_unified = on
        gs.toggle_deleted(on)
        gs.toggle_linehl(on)
        gs.toggle_word_diff(on)
        gs.change_base(on and 'HEAD' or nil, true)
        vim.notify('unified diff vs ' .. (on and 'HEAD (on)' or 'index (off)'))
      end,
      desc = 'Unified diff in buffer (GitHub style)',
    },
  },
}
