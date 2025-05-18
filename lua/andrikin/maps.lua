---@diagnostic disable: need-check-nil
local notify = require('andrikin.utils').notify

-- Remover <space> dos modos: NORMAL e VISUAL (em conjunto com mapleader)
vim.keymap.set({ 'n', 'v' }, '<space>', '<nop>', { silent = true })

-- CTRL-U in insert mode deletes a lot. Use CTRL-G u to first break undo,
-- so that you can undo CTRL-U after inserting a line break.
-- Revert with ":iunmap <C-U>". -> from defaults.vim
-- vim.keymap.set('i', '<c-u>', '<c-g>u<c-u>') -- default in neovim
-- vim.keymap.set('i', '<c-w>', '<c-g>u<c-w>') -- default in neovim
-- Fix & command. Redo :substitute command
-- vim.keymap.set( 'n', '&', function() vim.cmd('&&') end) -- default in neovim
vim.keymap.set('n', '<backspace>', 'X')
vim.keymap.set('n', '<c-h>', 'X')
vim.keymap.set('n', "'", '`')
-- Yank to end of sreen line. Make default in Neovim 0.6.0
-- g$ cursor after last character, g_ cursor at last character
vim.api.nvim_del_keymap('n', 'Y') -- removing default mapping
vim.keymap.set('n', 'Y', 'yg_') -- better than 'y$'
-- Disable <c-z> (:stop)
vim.keymap.set('n', '<c-z>', '<nop>')
-- Join lines in a better way - From a video of ThePrimeagen
vim.keymap.set('n', 'J', 'mzJ`z')
-- Undo better - inserting breaking points, thanks to ThePrimeagen
vim.keymap.set('i', ',', ',<c-g>u')
vim.keymap.set('i', '.', '.<c-g>u')

-- Using gk and gj (screen cursor up/down)
-- nnoremap <expr> k v:count == 0 ? 'gk' : 'k'
-- nnoremap <expr> j v:count == 0 ? 'gj' : 'j'
-- Adding jumps to jumplist - The Primeagen gold apple with gk and gj (screen cursor up/down)
vim.keymap.set( 'n', 'k',
	function()
		local count = vim.v.count
		local marcador = ''
		if count > 1 then
			marcador = 'm`' .. count
		end
		if count == 0 then
			return marcador .. 'gk'
		end
		return marcador .. 'k'
	end,
	{ expr = true, silent = true }
)
vim.keymap.set( 'n', 'j',
	function()
		local count = vim.v.count
		local marcador = ''
		if count > 1 then
			marcador = 'm`' .. count
		end
		if count == 0 then
			return marcador .. 'gj'
		end
		return marcador .. 'j'
	end,
	{ expr = true, silent = true }
)

-- Moving lines up and down - The Primeagen knowledge word
-- inoremap <c-j> <c-o>:m.+1<cr> -- utilizo muito <c-j> para newlines, seria inviável trocar para essa funcionalidade
-- inoremap <c-k> <c-o>:m.-2<cr>
-- nnoremap <leader>k <cmd>m.-2<cr>
-- nnoremap <leader>j <cmd>m.+1<cr>
vim.keymap.set('v', 'K', ":m'<-2<cr>gv", {silent = true})
vim.keymap.set('v', 'J', ":m'>+1<cr>gv", {silent = true})

-- Copy and paste from clipboard (* -> selection register/+ -> primary register)
vim.keymap.set('n', 'gP', '"+P')
vim.keymap.set('n', 'gp', '"+p')
vim.keymap.set({'n', 'v'}, 'gy', '"+y')
vim.keymap.set('n', 'gY', '"+Y')

-- Bracket maps
-- For buffers -- default neovim 0.11
-- vim.keymap.set('n', ']b', vim.cmd.bnext, {desc = 'Next buffer'})
-- vim.keymap.set('n', '[b', vim.cmd.bprevious, {desc = 'Previous buffer'})
-- For arglist -- default neovim 0.11, better my way
vim.keymap.set('n', ']a', function()
    local ok, erro = pcall(vim.cmd.next)
    if not ok then
        if erro:match('Vim:E165:') then
            vim.cmd.previous({range = {vim.fn.argc() - 1 }})
        end
    end
end, {desc = 'Next arglist file'})
vim.keymap.set('n', '[a', function()
    local ok, erro = pcall(vim.cmd.previous)
    if not ok then
        if erro:match('Vim:E164:') then
            vim.cmd.next({range = {vim.fn.argc() - 1 }})
        end
    end
end, {desc = 'Previous arglist file'})

-- --- Mapleader Commands ---

-- open $MYVIMRC
vim.keymap.set(
	'n',
	'<leader>r',
	function()
		if vim.g.loaded_dirvish == 1 then -- plugin ativo
			vim.cmd.Dirvish(
				vim.fn.fnamemodify(vim.env.MYVIMRC, ':h') .. '/lua/andrikin'
			)
		else
			vim.cmd.edit(
				vim.fn.fnamemodify(vim.env.MYVIMRC, ':h') .. '/lua/andrikin/init.lua'
			)
		end
	end
)

local toggle_list = function(modo, comando, on_error)
    local aberto = false
    local windows = vim.fn.getwininfo()
    for _, win in ipairs(windows) do
        aberto = win[modo] == 1
        if aberto then
            if vim.fn.tabpagenr() ~= win.tabnr then
                vim.fn.win_gotoid(win.winid)
            end
            vim.cmd.windo({args = {'normal', 'ZQ'}, range = {win.winnr}})
            do return end
        end
    end
    if not aberto then
        if modo == 'terminal' then
            vim.cmd.split()
        end
        local ok, resultado = pcall(vim.cmd[comando])
        if not ok and on_error then
            on_error(resultado)
        end
    end
end

-- --- Terminal ---

vim.keymap.set('t', '<esc>', '<C-\\><C-n>')
-- Terminal Toggle
vim.keymap.set('n', '<leader>t',
	function()
        toggle_list('terminal', 'terminal',
            function(resposta)
				if resposta and vim.fn.has('win32') and resposta:match('E903:') then
					notify('Não foi possível abrir o terminal. Esta feature não está disponível para a sua versão de Windows, somente para Windows 10+.')
					vim.cmd.normal('ZQ')
				end
            end
        )
	end
)

-- Undotree plugin
vim.keymap.set(
	'n',
	'<leader>u',
	vim.cmd.UndotreeToggle
)

-- Fugitive maps
vim.keymap.set(
	'n',
	'<leader>g',
	vim.cmd.Git
)

-- --- Telescope ---
vim.keymap.set( -- telescope way to open buffers
	'n',
	'<leader><space>',
	function()
		vim.cmd.Telescope('buffers')
	end
)
vim.keymap.set( -- telescope way to check for help
	'n',
	'<leader>h',
	function()
		vim.cmd.Telescope('help_tags')
	end
)

-- The Primeagen Harpoon2
local harpoon2 = require('harpoon')
harpoon2:setup()
vim.keymap.set("n", "gha", function() harpoon2:list():add() end)
vim.keymap.set("n", "ghm", function() harpoon2.ui:toggle_quick_menu(harpoon2:list()) end)
-- LOL mapping style
vim.keymap.set("n", "ghq", function() harpoon2:list():select(1) end)
vim.keymap.set("n", "ghw", function() harpoon2:list():select(2) end)
vim.keymap.set("n", "ghe", function() harpoon2:list():select(3) end)
vim.keymap.set("n", "ghr", function() harpoon2:list():select(4) end)
-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set("n", "ghp", function() harpoon2:list():prev() end)
vim.keymap.set("n", "ghn", function() harpoon2:list():next() end)

-- autocompletion LSP neovim 0.11
vim.keymap.set('i', '<c-space>',
	vim.lsp.completion.get
)
vim.keymap.set('i', '<c-j>',
	'pumvisible() ? "<c-y>" : "<c-j>"',
	{expr = true}
)

-- Removendo cliques do mouse em todos os modos
vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
'<LeftMouse>',
'<Nop>', { silent = true })
vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
'<LeftDrag>',
'<Nop>', { silent = true })
vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
'<LeftRelease>',
'<Nop>', { silent = true })
vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
'<MiddleRelease>',
'<Nop>', { silent = true })
vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
'<RightRelease>',
'<Nop>', { silent = true })
vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
'<RightDrag>',
'<Nop>', { silent = true })
vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
'<RightMouse>',
'<Nop>', { silent = true })
vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
'<MiddleDrag>',
'<Nop>', { silent = true })
vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
'<MiddleMouse>',
'<Nop>', { silent = true })

