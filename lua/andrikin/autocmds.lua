-- Autocmds goosebumps
local autocmd = vim.api.nvim_create_autocmd
local Andrikin = require('andrikin.utils').Andrikin
local cursorline = require('andrikin.utils').cursorline

-- Highlight linha quando entrar em INSERT MODE
autocmd(
    'InsertEnter',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            cursorline.on()
        end,
    }
)
autocmd(
    'InsertLeave',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            local dirvish = vim.o.ft == 'dirvish' -- não desativar quando for Dirvish
            if not dirvish then
                cursorline.off()
            end
        end,
    }
)

-- Resize windows automatically
-- Tim Pope goodness
autocmd(
    'VimResized',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            vim.cmd.wincmd('=')
        end,
    }
)

-- Highlight configuração
autocmd(
    'TextYankPost',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            vim.hl.on_yank({
                higroup = 'IncSearch',
                timeout = 300,
            })
        end,
    }
)

-- --- Builtin LSP commands ---
-- Only available in git projects (git init)
autocmd(
    'LspAttach',
    {
        group = Andrikin,
        callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client and client:supports_method('textDocument/completion') then
                vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = false })
            end
        end
    }
)

