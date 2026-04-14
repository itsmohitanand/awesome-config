-- Sticky scroll: shows enclosing function / class in the winbar.
-- Pure built-in Neovim treesitter — no extra plugins required.

local M = {}

-- Node type → { icon, highlight group }
local SCOPES = {
  -- Functions / methods
  function_definition  = { icon = '󰊕', hl = 'Function' },
  function_declaration = { icon = '󰊕', hl = 'Function' },
  method_definition    = { icon = '󰊕', hl = 'Function' },
  method_declaration   = { icon = '󰊕', hl = 'Function' },
  function_item        = { icon = '󰊕', hl = 'Function' },
  ['function']         = { icon = '󰊕', hl = 'Function' },
  local_function       = { icon = '󰊕', hl = 'Function' },
  -- Classes / structs
  class_definition     = { icon = '󰆧', hl = 'Type' },
  class_declaration    = { icon = '󰆧', hl = 'Type' },
  struct_specifier     = { icon = '󰆧', hl = 'Type' },
  class_specifier      = { icon = '󰆧', hl = 'Type' },
  impl_item            = { icon = '󰆧', hl = 'Type' },
  struct_item          = { icon = '󰆧', hl = 'Type' },
}

local MAX_DEPTH = 3

-- Extract just the identifier name from a node (falls back to trimmed first line).
local function get_name(node, buf)
  local fields = node:field('name')
  if fields and fields[1] then
    return vim.treesitter.get_node_text(fields[1], buf)
  end
  local row = node:start()
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  return line and vim.trim(line) or '?'
end

function M.context()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= '' then return '' end

  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then return '' end

  local parts = {}
  local current = node
  while current and #parts < MAX_DEPTH do
    local cfg = SCOPES[current:type()]
    if cfg then
      local name = get_name(current, buf)
      table.insert(parts, 1, '%#' .. cfg.hl .. '#' .. cfg.icon .. ' ' .. name .. '%*')
    end
    current = current:parent()
  end

  if #parts == 0 then return '' end
  return ' ' .. table.concat(parts, ' %#NonText#›%* ')
end

vim.o.winbar = "%{%v:lua.require('core.sticky_scroll').context()%}"

return M
