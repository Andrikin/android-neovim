return {
    cmd = { 'emmet-ls', '--stdio' },
    filetypes = {
        'astro',
        'css',
        'eruby',
        'html',
        'htmldjango',
        'javascriptreact',
        'less',
        'pug',
        'sass',
        'scss',
        'svelte',
        'typescriptreact',
        'vue',
        'htmlangular',
    },
    root_markers = function(fname)
        return vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
    end,
    single_file_support = true,
}
