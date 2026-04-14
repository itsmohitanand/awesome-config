-- ~/.config/nvim/lua/keymaps.lua

-- A helper function to make keymaps easier to set
local function map(mode, lhs, rhs, opts)
  local options = {
    noremap = true,
    silent = true,
  }
  if opts then
    options = vim.tbl_extend('force', options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

---------------------
-- INSERT MODE
---------------------
map('i', 'jk', '<Esc>', { desc = 'Exit insert mode' })
map('i', '<C-BS>', '<C-w>', { desc = 'Delete previous word' })

---------------------
-- NORMAL MODE
---------------------
-- Window navigation
map('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
map('n', '<C-j>', '<C-w>j', { desc = 'Move to down window' })
map('n', '<C-k>', '<C-w>k', { desc = 'Move to up window' })
map('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- Buffer navigation
map('n', '<S-l>', ':bnext<CR>', { desc = 'Next buffer' })
map('n', '<S-h>', ':bprevious<CR>', { desc = 'Previous buffer' })
map('n', '<leader>bd', ':bdelete<CR>', { desc = 'Close current buffer' })

-- File saving
map('n', '<leader>s', ':w<CR>', { desc = 'Save file' })
map('n', '<leader>q', ':q<CR>', { desc = 'Quit' })

-- Move by visual lines (respects line wrapping)
map('n', 'j', 'gj')
map('n', 'k', 'gk')

-- Center screen on half-page jumps
map('n', '<C-d>', '<C-d>zz', { desc = 'Page down and center' })
map('n', '<C-u>', '<C-u>zz', { desc = 'Page up and center' })

-- Center screen on search results
map('n', 'n', 'nzz', { desc = 'Search next and center' })
map('n', 'N', 'Nzz', { desc = 'Search previous and center' })

-- Yank to system clipboard
map('n', '<leader>y', '"+y', { desc = 'Yank to system clipboard' })
map('n', '<leader>Y', '"+Y', { desc = 'Yank line to system clipboard' })

-- Paste from system clipboard
map('n', '<leader>p', '"+p', { desc = 'Paste from system clipboard (after)' })
map('n', '<leader>P', '"+P', { desc = 'Paste from system clipboard (before)' })
---------------------
-- VISUAL MODE
---------------------
-- Move selected lines up and down
map('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move line down' })
map('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move line up' })

-- Keep selection when indenting
map('v', '<', '<gv', { desc = 'Indent left' })
map('v', '>', '>gv', { desc = 'Indent right' })

-- Paste over selection without yanking it
map('v', 'p', '"_dP', { desc = 'Paste over selection' })
map('n', '<F5>', ':w | !python %<CR>', { silent = false, desc = 'Save and run Python' })

-- Yank selection to system clipboard
map('v', '<leader>y', '"+y', { desc = 'Yank selection to clipboard' })

-- Paste from system clipboard over selection
map('v', '<leader>p', '"+p', { desc = 'Paste from system clipboard' })


-- Disable diff commands that conflict with DAP <leader>d* keymaps
map('n', 'do', '<Nop>', { desc = 'Disabled: use :diffget explicitly' })
map('n', 'dp', '<Nop>', { desc = 'Disabled: use :diffput explicitly' })

---------------------
-- COMMENTING (vim-commentary)
---------------------
-- Ctrl+/ toggles comment (terminals often send <C-_> for Ctrl+/)
vim.keymap.set('n', '<C-/>', 'gcc', { remap = true, silent = true, desc = 'Toggle comment line' })
vim.keymap.set('v', '<C-/>', 'gc', { remap = true, silent = true, desc = 'Toggle comment selection' })
vim.keymap.set('n', '<C-_>', 'gcc', { remap = true, silent = true, desc = 'Toggle comment line' })
vim.keymap.set('v', '<C-_>', 'gc', { remap = true, silent = true, desc = 'Toggle comment selection' })

---------------------
-- DIAGNOSTICS
---------------------
map('n', ']d', vim.diagnostic.goto_next, { desc = 'Next Diagnostic' })
map('n', '[d', vim.diagnostic.goto_prev, { desc = 'Prev Diagnostic' })
map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Floating Diagnostic' })
map('n', '<leader>cx', function()
  local enabled = vim.diagnostic.is_enabled()
  vim.diagnostic.enable(not enabled)
  vim.notify(enabled and 'Diagnostics off' or 'Diagnostics on')
end, { desc = 'Toggle Diagnostics' })

---------------------
-- LSP MAPPINGS (Normal Mode)
---------------------
-- View documentation/args for function under cursor
map('n', 'K', vim.lsp.buf.hover, { desc = 'LSP: Show documentation/args' })

-- Jump to definition
map('n', 'gd', vim.lsp.buf.definition, { desc = 'LSP: Go to definition' })

-- Show code actions (fixing errors)
map('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'LSP: Code actions' })

---------------------
-- FILE PATH
---------------------
-- Copy absolute path to clipboard
vim.keymap.set('n', '<leader>fp', ":let @+ = expand('%:p')<CR>", { desc = 'Copy current file path' })

-- Copy relative path to clipboard
vim.keymap.set('n', '<leader>fr', ":let @+ = expand('%')<CR>", { desc = 'Copy current file relative path' })

-- Copy filename only to clipboard
vim.keymap.set('n', '<leader>fn', ":let @+ = expand('%:t')<CR>", { desc = 'Copy current file name' })

---------------------
-- LSP MAPPINGS (Insert Mode)
---------------------
-- Show arguments while you are typing inside brackets
map('i', '<C-k>', vim.lsp.buf.signature_help, { desc = 'LSP: Show signature help' })
