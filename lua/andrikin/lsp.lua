-- Configuração de LSP servers

local notify = require('andrikin.utils').notify

-- colorizer.lua
require('colorizer').setup(nil, { css = true })

-- Lazydev -- Neovim 0.11
require('lazydev').setup()

vim.defer_fn( -- kickstart.nvim
    function()
        require('nvim-treesitter.install').compilers = {'gcc', 'cc', 'clang'}
        require('nvim-treesitter.configs').setup({
            modules = {}, -- padrao
            ignore_install = {}, -- padrao
            auto_install = false, -- padrao
            sync_install = false, -- padrao
            ensure_installed = { -- parsers para highlight - treesitter
                'css', 'html', 'javascript', 'vue',
                'diff',
                'git_config', 'git_rebase', 'gitattributes', 'gitcommit', 'gitignore',
                'jsdoc', 'json', 'json5', 'java',
                'lua', 'luadoc',
                -- 'luap', 'luau',
                'markdown',
                'markdown_inline',
                'regex',
                'xml',
                'python',
                'vim', 'vimdoc',
                'latex',
                -- https://github.com/folke/dot/blob/master/nvim/lua/plugins/treesitter.lua -- folke saying that comment slow TS
                -- 'comment',
            },
            highlight = {
                ---@diagnostic disable-next-line: unused-local
                disable = function(lang, buf)
                    local max_filesize = 100 * 1024 -- 100 KB
                    ---@diagnostic disable-next-line: undefined-field
                    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
                    if ok and stats and stats.size > max_filesize then
                        return true
                    end
                end,
                enable = true,
                additional_vim_regex_highlighting = true,
            },
            indent = { enable = true },
        })
    end,
    0
)

local telescope_tema = 'dropdown'
local telescope_actions = require('telescope.actions')
require('telescope').setup({
    -- Playground configuration, extracted from github https://github.com/nvim-treesitter/playground
    playground = {
        enable = true,
        disable = {},
        updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
        persist_queries = false, -- Whether the query persists across vim sessions
        keybindings = {
            toggle_query_editor = 'o',
            toggle_hl_groups = 'i',
            toggle_injected_languages = 't',
            toggle_anonymous_nodes = 'a',
            toggle_language_display = 'I',
            focus_language = 'f',
            unfocus_language = 'F',
            update = 'R',
            goto_node = '<cr>',
            show_help = '?',
        },
    },
    pickers = {
        buffers = {
            previewer = false,
            theme = telescope_tema,
            mappings = {
                n = {
                    ['dd'] = telescope_actions.delete_buffer,
                },
            },
        },
        find_files = {
            previewer = false,
            theme = telescope_tema,
        },
        help_tags = {
            previewer = false,
            theme = telescope_tema,
        },
        file_browser = {
            previewer = false,
            theme = telescope_tema,
        },
    },
    defaults = {
        layout_config = {
            width = 0.5,
            height = 0.70,
        },
        path_display = {
            tail = true,
        },
        mappings = {
            i = {
                ['<NL>'] = telescope_actions.select_default + telescope_actions.center,
                ['gq'] = telescope_actions.close, -- ruim para as buscas que precisarem de "gq"
                ['<c-u>'] = {'<c-u>', type = 'command'},
                ['<esc>'] = {'<esc>', type = 'command'},
            },
            n = {
                ['<NL>'] = telescope_actions.select_default + telescope_actions.center,
                ['gq'] = telescope_actions.close,
            },
        },
    }
})
local ok, _ = pcall(require('telescope').load_extension, 'fzf')
if not ok then
---@diagnostic disable-next-line: need-check-nil
    notify('Telescope: não foi possível carregar a extenção fzf.')
else
---@diagnostic disable-next-line: need-check-nil
    notify('Telescope: extenção fzf carregada com sucesso')
end

local luasnip = require('luasnip')
require('luasnip.loaders.from_vscode').lazy_load() -- carregar snippets (templates)
require("luasnip.loaders.from_lua").load({
    ---@diagnostic disable-next-line: assign-type-mismatch
    paths = vim.fs.joinpath( -- carregar snippets customizadas
        vim.fn.fnamemodify(vim.env.MYVIMRC, ':h'),
        'snippets'
    )
})
luasnip.config.setup({})

-- Ativar LSP nos buffers, automaticamente -- Neovim 0.11
vim.lsp.enable({
    'luals',
    'texlab',
    'emmetls',
    'pyright',
    'tsls',
    -- 'denols',
    'vimls',
    'html',
    'jsonls',
    'cssls',
})
-- vim.lsp.set_log_level("debug")
