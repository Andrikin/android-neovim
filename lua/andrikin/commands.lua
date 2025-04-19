-- CUSTOM COMMANDS

local command = vim.api.nvim_create_user_command
local Ouvidoria = require('andrikin.utils').Ouvidoria -- executar bootstrap
local Diretorio = require('andrikin.utils').Diretorio

command(
	'CompilarLatex',
    function()
---@diagnostic disable-next-line: param-type-mismatch, undefined-field
        local destino = Diretorio.new(vim.uv.os_homedir()) / 'downloads'
---@diagnostic disable-next-line: missing-parameter
        Ouvidoria.latex:compilar(destino)
    end,
	{}
)

command(
	'Projetos',
	function()
		vim.cmd.Dirvish(Ouvidoria.ci.diretorios.projetos.diretorio)
	end,
	{}
)

command(
	'Downloads',
	function()
		vim.cmd.Dirvish(
            vim.fs.joinpath(
                vim.env.HOME,
                'storage',
                'downloads'
            )
        )
	end,
	{}
)

command(
	'Reload',
    require('andrikin.utils').reload,
	{}
)

