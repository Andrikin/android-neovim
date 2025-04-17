-- BufWritePost: compilar tex para gerar pdf assim que salvar o arquivo
-- TODO: comando somente para arquivos de comunicação que precisam ser 
-- compilados
local Andrikin = require('andrikin.utils').Andrikin
local buf = vim.api.nvim_get_current_buf()
local has_autocmd = false
local autocmds = vim.api.nvim_get_autocmds({
    group = Andrikin,
    event = 'BufWritePost',
    buffer = buf,
})
for _, au in ipairs(autocmds) do
    if au.group_name == "Andrikin" then
        has_autocmd = true
        break
    end
end
if not has_autocmd then
    vim.api.nvim_create_autocmd(
        'BufWritePost',
        {
            group = Andrikin,
            callback = function(env)
                if env.file:match('C%.I%. N°') then
                    vim.cmd.CompilarOuvidoria()
                end
            end,
            buffer = buf,
        }
    )
end
vim.bo[buf].textwidth = 80
