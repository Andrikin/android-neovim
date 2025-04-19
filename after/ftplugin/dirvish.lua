local buf = vim.api.nvim_get_current_buf()
-- local open = vim.ui.open or function(arquivo)
local open = function(arquivo)
    vim.fn.jobstart({
            'termux-open',
             arquivo
            -- vim.fn.shellescape(arquivo)
        },
        {detach = true}
    )
end
vim.keymap.set('n', 'go', function()
    -- open = vim.ui.open or open
    local arquivo = vim.fn.getline('.')
    local extencao = vim.fn.fnamemodify(arquivo, ':e')
    if extencao ~= '' and vim.fn.isdirectory(arquivo) == 0 then
        open(arquivo)
    else
        print('dirvish: não foi encontrado arquivo para abrir')
        do return end
    end
end, {silent = true, buffer = buf})
