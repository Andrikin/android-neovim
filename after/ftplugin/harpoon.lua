vim.keymap.set('n', 'gq', function()
    vim.cmd.quit()
    vim.fn.feedkeys('\\<c-w>p', 'n')
end,
    { silent = true, buffer = vim.api.nvim_get_current_buf()}
)
