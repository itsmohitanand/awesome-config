# Keymaps

Leader key: `Space`

## Insert Mode

| Key | Description | Source |
| --- | --- | --- |
| `jk` | Exit insert mode | keymaps.lua |
| `<C-BS>` | Delete previous word | keymaps.lua |
| `<C-k>` | LSP: Show signature help | keymaps.lua, lsp.lua |
| `<C-Space>` | Trigger completion | cmp.lua |
| `<C-n>` | Next completion item | cmp.lua |
| `<C-p>` | Previous completion item | cmp.lua |
| `<C-b>` | Scroll completion docs up | cmp.lua |
| `<C-f>` | Scroll completion docs down | cmp.lua |
| `<C-e>` | Abort completion | cmp.lua |
| `<CR>` | Confirm completion | cmp.lua |

## Normal Mode

### Window Navigation

| Key | Description | Source |
| --- | --- | --- |
| `<C-h>` | Move to left window | keymaps.lua |
| `<C-j>` | Move to down window | keymaps.lua |
| `<C-k>` | Move to up window | keymaps.lua |
| `<C-l>` | Move to right window | keymaps.lua |

### Buffer Navigation

| Key | Description | Source |
| --- | --- | --- |
| `<S-l>` | Next buffer | keymaps.lua |
| `<S-h>` | Previous buffer | keymaps.lua |
| `<leader>bd` | Close current buffer | keymaps.lua |

### File Operations

| Key | Description | Source |
| --- | --- | --- |
| `<leader>s` | Save file | keymaps.lua |
| `<leader>q` | Quit | keymaps.lua |
| `<F5>` | Save and run Python file | keymaps.lua |

### File Explorer (snacks)

| Key | Description | Source |
| --- | --- | --- |
| `<leader>e` | Toggle file explorer | snacks.lua |

### Cursor Movement

| Key | Description | Source |
| --- | --- | --- |
| `j` | Move down by visual line | keymaps.lua |
| `k` | Move up by visual line | keymaps.lua |
| `<C-d>` | Page down and center | keymaps.lua |
| `<C-u>` | Page up and center | keymaps.lua |
| `n` | Search next and center | keymaps.lua |
| `N` | Search previous and center | keymaps.lua |

### Clipboard

| Key | Description | Source |
| --- | --- | --- |
| `<leader>y` | Yank to system clipboard | keymaps.lua |
| `<leader>Y` | Yank line to system clipboard | keymaps.lua |
| `<leader>p` | Paste from system clipboard (after) | keymaps.lua |
| `<leader>P` | Paste from system clipboard (before) | keymaps.lua |

### LSP / Code (`<leader>c`)

| Key | Description | Source |
| --- | --- | --- |
| `K` | Show hover documentation | lsp.lua |
| `gd` | Go to definition | lsp.lua |
| `gr` | Show references | lsp.lua |
| `<leader>ca` | Code actions | lsp.lua |
| `<leader>cr` | Rename symbol | lsp.lua |
| `<leader>cd` | Floating diagnostic | keymaps.lua |
| `<leader>cl` | Diagnostics list (picker) | snacks.lua |
| `<leader>cx` | Toggle diagnostics | keymaps.lua |
| `]d` / `[d` | Next / prev diagnostic | keymaps.lua |

### File / Find (snacks)

| Key | Description | Source |
| --- | --- | --- |
| `<leader>ff` | Find files | snacks.lua |
| `<leader>fg` | Live grep | snacks.lua |
| `<leader>fb` | Find buffers | snacks.lua |
| `<leader>fs` | Find symbols (LSP) | snacks.lua |
| `<leader>fp` | Copy file path (absolute) | keymaps.lua |
| `<leader>fr` | Copy file relative path | keymaps.lua |
| `<leader>fn` | Copy file name | keymaps.lua |

### Debugging (DAP)

| Key | Description | Source |
| --- | --- | --- |
| `<leader>db` | Toggle breakpoint | dap.lua |
| `<leader>dc` | Start/continue debugging | dap.lua |
| `<leader>di` | Step into | dap.lua |
| `<leader>do` | Step over | dap.lua |
| `<leader>du` | Toggle debug UI | dap.lua |

### REPL (iron.nvim)

| Key | Description | Source |
| --- | --- | --- |
| `<leader>rr` | Toggle REPL | iron.lua |
| `<leader>rR` | Restart REPL | iron.lua |
| `<leader>rc` | Send motion to REPL | iron.lua |
| `<leader>rf` | Send file to REPL | iron.lua |
| `<leader>rl` | Send line to REPL | iron.lua |
| `<leader>rp` | Send paragraph to REPL | iron.lua |
| `<leader>ru` | Send until cursor to REPL | iron.lua |
| `<leader>rb` | Send code block to REPL | iron.lua |
| `<leader>rj` | Send code block and move | iron.lua |
| `<leader>ri` | Interrupt REPL | iron.lua |
| `<leader>rq` | Exit REPL | iron.lua |
| `<leader>rQ` | Force close REPL (kills process) | iron.lua |
| `<leader>rx` | Clear REPL | iron.lua |
| `<leader>rF` | Focus REPL window | iron.lua |
| `<leader>rh` | Hide REPL window | iron.lua |

### Git

| Key | Description | Source |
| --- | --- | --- |
| `<leader>gg` | Open LazyGit | lazygit.lua |

### Telekasten (Zettelkasten Notes)

| Key | Description | Source |
| --- | --- | --- |
| `<leader>tkp` | Open Telekasten panel | telekasten.lua |
| `<leader>tkf` | Find notes | telekasten.lua |
| `<leader>tkg` | Grep/search notes | telekasten.lua |
| `<leader>tkn` | New note | telekasten.lua |
| `<leader>tkd` | Daily note | telekasten.lua |
| `<leader>tkw` | Weekly note | telekasten.lua |
| `<leader>tkt` | New templated note | telekasten.lua |
| `<leader>tki` | Insert link | telekasten.lua |
| `<leader>tkb` | Show backlinks | telekasten.lua |
| `<leader>tkl` | Follow link | telekasten.lua |
| `<leader>tk#` | Show tags | telekasten.lua |
| `<leader>tkr` | Rename note | telekasten.lua |
| `<leader>tky` | Yank notelink | telekasten.lua |
| `[[` (insert) | Insert link | telekasten.lua |

### Neorg (Structured Notes)

| Key | Description | Source |
| --- | --- | --- |
| `<leader>nrw` | Switch workspace | neorg.lua |
| `<leader>nrn` | Notes workspace | neorg.lua |
| `<leader>nrp` | Personal workspace | neorg.lua |
| `<leader>nrj` | Journal today | neorg.lua |
| `<leader>nry` | Journal yesterday | neorg.lua |
| `<leader>nrt` | Journal tomorrow | neorg.lua |
| `<leader>nri` | Open index | neorg.lua |
| `<leader>nrc` | Table of contents | neorg.lua |
| `<leader>nrr` | Return to previous location | neorg.lua |
| `<leader>o` | Neorg leader (built-in commands) | neorg.lua |

## Visual Mode

| Key | Description | Source |
| --- | --- | --- |
| `J` | Move selected lines down | keymaps.lua |
| `K` | Move selected lines up | keymaps.lua |
| `<` | Indent left (keeps selection) | keymaps.lua |
| `>` | Indent right (keeps selection) | keymaps.lua |
| `p` | Paste over selection (no yank) | keymaps.lua |
| `<leader>y` | Yank selection to system clipboard | keymaps.lua |
| `<leader>p` | Paste from system clipboard | keymaps.lua |
| `<leader>rc` | Send selection to REPL | iron.lua |
