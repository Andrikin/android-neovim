local opts = { silent = true, buffer = vim.api.nvim_get_current_buf() }
local open = vim.ui.open or function(arquivo)
    -- If {cmd} is a String it runs in the 'shell'
    vim.fn.jobstart(vim.fn.shellescape(arquivo), {detach = true})
end
vim.keymap.set('n', 'go', function()
    local linha = vim.fn.getline('.')
    if not linha:match('^<#part') then
        print('Não foi possível obter arquivo de diretório para abrir o arquivo')
        do return end
    end
    local arquivo = linha:match('filename="(.*)"'):match('C:.*'):gsub('\\', '/')
    if arquivo then
        print(('Abrindo arquivo: %s'):format(arquivo))
        open(arquivo)
    end
end, opts)
-- precisa ter os templates no diretório, configurados
vim.keymap.set('n', 'gm', function()
    local inicio = 5
    local conta = vim.fn['himalaya#domain#account#current']()
    local txt = vim.api.nvim_buf_get_lines(
        vim.api.nvim_get_current_buf(),
        0, vim.fn.line('$'),
        false
    ) or {}
    -- obter início do e-mail
    if type(txt) == 'table' then
        for i, v in ipairs(txt) do
            if v == '' then
                inicio = i + 1
                break
            end
        end
    end
    if conta == '' then
        conta = 'ouvidoria'
    end
    local template = vim.g.himalaya_pandoc_template_email .. '/' .. conta .. '.html'
    if vim.fn.filereadable(template) == 0 then
        print('Pandoc: Arquivo template para e-mails não configurado!')
        do return end
    end
    vim.cmd['!']({
        'pandoc --template ' .. template .. ' -t html',
        range = {inicio, vim.fn.line('$')},
    })
end, opts)
vim.bo.textwidth = 80
