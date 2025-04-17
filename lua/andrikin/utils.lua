---@class Utils
---@field Diretorio Diretorio
---@field SauceCodePro SauceCodePro
---@field Registrador Registrador
---@field Programa Programa
---@field Projetos Diretorio
---@field Ssh Ssh
---@field Git Git
---@field Ouvidoria Ouvidoria
---@field Opt Diretorio
---@field win7 string | nil
---@field notify nil
---@field echo nil
---@field remover_path nil
---@field npcall nil
---@field cursorline table
---@field autocmd function
---@field Andrikin number
---@field init function
local Utils = {}

--- Mostra notificação para usuário, registrando em :messages
---@param msg string
Utils.notify = function(msg)
    vim.api.nvim_echo({{msg, 'DiagnosticInfo'}}, true, {})
    vim.cmd.redraw({bang = true})
end

--- Mostra uma notificação para o usuário, mas sem registrar em :messages
---@param msg string
Utils.echo = function(msg)
    vim.api.nvim_echo({{msg, 'DiagnosticInfo'}}, false, {})
    vim.cmd.redraw({bang = true})
end

Utils.npcall = vim.F.npcall

---@type table
Utils.cursorline = {
    toggle = function(cursorlineopt)
        cursorlineopt = cursorlineopt or {'number', 'line'}
        vim.opt.cursorlineopt = cursorlineopt
        vim.wo.cursorline = not vim.wo.cursorline
    end,
    on = function(cursorlineopt)
        cursorlineopt = cursorlineopt or {'number', 'line'}
        vim.opt.cursorlineopt = cursorlineopt
        vim.wo.cursorline = true
    end,
    off = function()
        vim.wo.cursorline = false
    end
}

-- Recarregar configuração depois de atualizar o repositório git
Utils.reload = function()
    for name,_ in pairs(package.loaded) do
        if name:match('^andrikin') then
            package.loaded[name] = nil
        end
    end
    require('andrikin')
end

Utils.Andrikin = vim.api.nvim_create_augroup('Andrikin', {clear = true})

--- Wrap envolta do vim.fn.jobstart
---@class Job
---@field clear_env boolean
---@field cwd string
---@field detach boolean
---@field env table
---@field height number
---@field on_exit function
---@field on_stdout function
---@field on_stderr function
---@field overlapped boolean
---@field pty boolean
---@field rpc boolean
---@field stderr_buffered boolean
---@field stdout_buffered boolean
---@field stdin string
---@field width number
---@field new Job
---@field id number
---@field ids table
---@field start function
---@field wait function
---@field running function
local Job = {}

Job.__index = Job

---@param opts table
---@return Job
---@diagnostic disable-next-line: assign-type-mismatch
Job.new = function(opts)
    local job = {}
    opts = opts or {}
    if not vim.tbl_isempty(opts) then
        for k, v in pairs(opts) do
            job[k] = v
        end
    end
    job.env = {
        NVIM = vim.env.NVIM,
        NVIM_LISTEN_ADDRESS = vim.env.NVIM_LISTEN_ADDRESS,
        NVIM_LOG_FILE = vim.env.NVIM_LOG_FILE,
        VIM = vim.env.VIM,
        VIMRUNTIME = vim.env.VIMRUNTIME,
        PATH = vim.env.PATH,
        NVIM_OPT = vim.env.NVIM_OPT,
    }
    job.id = 0 -- last created job
    job.ids = {} -- list of ids jobs
    job = setmetatable(job, Job)
    return job
end

---@param cmd table
---@return Job
Job.start = function(self, cmd)
    local id = vim.fn.jobstart(cmd, self)
	self.id = id
    table.insert(self.ids, id)
    return self
end

--- Espera a execução do último job
Job.wait = function(self)
    if self.id == 0 then
        error('Job: argumentos inválidos', 2)
    elseif self.id == -1 then
        error('Job: comando não executável', 2)
    end
    vim.fn.jobwait({self.id})
end

Job.wait_all = function(self)
	local status_job = {}
	if not vim.tbl_isempty(self.ids) then
		status_job = vim.fn.jobwait(self.ids)
	end
	return status_job
end

---@return boolean
Job.running = function(self)
    return vim.fn.jobwait({self.id}, 0)[1] == -1
end

Utils.Job = Job

---@class Diretorio
---@field diretorio string Caminho completo do diretório
---@field add function
local Diretorio = {}

Diretorio.__index = Diretorio

---@param caminho string | table
---@return Diretorio
Diretorio.new = function(caminho)
    caminho = caminho or ''
    vim.validate({caminho = {caminho, {'table', 'string'}}})
    if type(caminho) == 'table' then
        for _, valor in ipairs(caminho) do
            if type(valor) ~= 'string' then
                error('Diretorio: new: Elemento de lista diferente de "string"!')
            end
        end
        caminho = table.concat(caminho, '/')
    end
    local diretorio = setmetatable({
        diretorio = Diretorio._sanitize(caminho),
    }, Diretorio)
    return diretorio
end

---@private
---@param str string
---@return string
---@return _
Diretorio._sanitize = function(str)
    vim.validate({ str = {str, 'string'} })
    return vim.fs.normalize(str):gsub('//+', '/')
end

---@param dir Diretorio | string
---@return boolean
Diretorio.validate = function(dir)
    local isdirectory = function(d)
        return vim.fn.isdirectory(d) == 1
    end
    local valido = false
    if type(dir) == 'Diretorio' then
        valido = isdirectory(dir.diretorio)
    elseif type(dir) == 'string' then
        valido = isdirectory((Diretorio.new(dir)).diretorio)
    else
        error('Diretorio: validate: variável não é do tipo "Diretorio" ou "string"')
    end
    return valido
end

---@return Diretorio
--- Realiza busca nas duas direções pelo 
Diretorio.buscar = function(dir, start)
    vim.validate({ dir = {dir,{'table', 'string'}} })
    vim.validate({ start = {start, 'string'} })
    if type(dir) == 'table' then
        dir = vim.fs.normalize(table.concat(dir, '/'))
    else
        dir = vim.fs.normalize(dir)
    end
    if dir:match('^' .. vim.env.HOMEDRIVE) then
        error('Diretorio: buscar: argumento deve ser um trecho de diretório, não deve conter "C:/" no seu início.')
    end
    start = start and Diretorio._sanitize(start) or Diretorio._sanitize(vim.env.HOMEPATH)
    local diretorio = ''
    local diretorios = vim.fs.dir(start, {depth = math.huge})
    for d, t in diretorios do
        if not t == 'directory' then
            goto continue
        end
        if d:match('.*' .. dir:gsub('-', '.')) then
            diretorio = d
            break
        end
        ::continue::
    end
    if diretorio == '' then
        error('Diretorio: buscar: não foi encontrado o caminho do diretório informado.')
    end
    diretorio = vim.fs.normalize(start .. '/' .. diretorio):gsub('//+', '/')
    return Diretorio.new(diretorio)-- valores de vim.fs.dir já são normalizados
end

---@private
---@param str string
---@return string
Diretorio._suffix = function(str)
    vim.validate({ str = {str, 'string'} })
    return (str:match('^[/\\]') or str == '') and str or vim.fs.normalize('/' .. str)
end

---@param caminho string | table
Diretorio.add = function(self, caminho)
    if type(caminho) == 'table' then
        local concatenar = ''
        for _, c in ipairs(caminho) do
            concatenar = concatenar .. Diretorio._suffix(c)
        end
        caminho = concatenar
    end
    self.diretorio = self.diretorio .. Diretorio._suffix(caminho)
end

---@param other Diretorio | string
---@return Diretorio
Diretorio.__div = function(self, other)
    local nome = self.diretorio
    if getmetatable(other) == Diretorio then
        other = other.diretorio
    elseif type(other) ~= 'string' then
        error('Diretorio: __div: Elementos precisam ser do tipo "string".')
    end
    return Diretorio.new(Diretorio._sanitize(nome .. Diretorio._suffix(other)))
end

---@param str string
---@return string
Diretorio.__concat = function(self, str)
    if getmetatable(self) ~= Diretorio then
        error('Diretorio: __concat: Objeto não é do tipo Diretorio.')
    end
    if type(str) ~= 'string' then
        error('Diretorio: __concat: Argumento precisa ser do tipo "string".')
    end
    return Diretorio._sanitize(self.diretorio .. Diretorio._suffix(str))
end

---@return string
Diretorio.__tostring = function(self)
    return self.diretorio
end

Utils.Diretorio = Diretorio

---@type Diretorio
Utils.Opt = Diretorio.new(vim.env.NVIM_OPT)

--- Criar diretório 'opt' caso não exista
Utils.init = function()
    local projetos = (Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')) / 'projetos').diretorio
    if vim.fn.isdirectory(projetos) == 0 then
        vim.fn.mkdir(projetos, 'p', '0755')
    end
    if vim.fn.isdirectory(Utils.Opt.diretorio) == 0 then
        vim.fn.mkdir(Utils.Opt.diretorio, 'p', '0755')
    end
end

---WARNING: classe para instalar as credenciais .ssh
---TODO: como resolver esta questão de proteção
---@class Ssh
---@field destino Diretorio
---@field arquivos table
local Ssh = {}

Ssh.__index = Ssh

---@type Diretorio
Ssh.destino = Diretorio.new(vim.env.HOME) / '.ssh'

---@type table
Ssh.arquivos = {
    {
        nome = 'id_ed25519',
        valor = "LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzFyWlhrdGRqRUFBQUFBQkc1dmJtVUFBQUFFYm05dVpRQUFBQUFBQUFBQkFBQUFNd0FBQUF0emMyZ3RaVwpReU5UVXhPUUFBQUNCTTBXQTZXdWFsYzg0QkF0YTF2bHFFM2JDMHBrM3hkNzUxSm9HV01OcmFCUUFBQUtqdkYzZ2E3eGQ0CkdnQUFBQXR6YzJndFpXUXlOVFV4T1FBQUFDQk0wV0E2V3VhbGM4NEJBdGExdmxxRTNiQzBwazN4ZDc1MUpvR1dNTnJhQlEKQUFBRUFZVEtmSzBEZUFzOWFKbkdqMVRCaWhUMnV3MXQrTlZ2SzdrU3hQdEFHNTRFelJZRHBhNXFWenpnRUMxclcrV29UZApzTFNtVGZGM3ZuVW1nWll3MnRvRkFBQUFJV052Ym5SaGMyVmpjbVYwWVdGc2RHVnlibUYwYVhaaFFHZHRZV2xzTG1OdmJRCkVDQXdRPQotLS0tLUVORCBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0K",
    },
    {
        nome = 'id_ed25519.pub',
        valor = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUV6UllEcGE1cVZ6emdFQzFyVytXb1Rkc0xTbVRmRjN2blVtZ1pZdzJ0b0YgY29udGFzZWNyZXRhYWx0ZXJuYXRpdmFAZ21haWwuY29tCg==",
    },
    {
        nome = 'known_hosts',
        valor = "Z2l0aHViLmNvbSBzc2gtZWQyNTUxOSBBQUFBQzNOemFDMWxaREkxTlRFNUFBQUFJT01xcW5rVnpybTBTZEc2VU9vcUtMc2FiZ0g1Qzlva1dpMGRoMmw5R0tKbApnaXRodWIuY29tIHNzaC1yc2EgQUFBQUIzTnphQzF5YzJFQUFBQURBUUFCQUFBQmdRQ2o3bmROeFFvd2djUW5qc2hjTHJxUEVpaXBobnQrVlRUdkRQNm1IQkw5ajFhTlVrWTRVZTFndnduR0xWbE9oR2VZcm5aYU1nUks2K1BLQ1VYYURiQzdxdGJXOGdJa2hMN2FHQ3NPci9DNTZTSk15L0JDWmZ4ZDFuV3pBT3hTRFBnVnNtZXJPQllmTnFsdFY5L2hXQ3FCeXdJTklSKzVkSWc2SlRKNzJwY0VwRWpjWWdYa0UyWUVGWFYxSkhuc0tnYkxXTmxoU2NxYjJVbXlSa1F5eXRSTHRMKzM4VEd4a3hDZmxtTys1WjhDU1NOWTdHaWRqTUlaN1E0ek1qQTJuMW5HcmxURGt6d0RDc3crd3FGUEdRQTE3OWNuZkdXT1dSVnJ1ajE2ejZYeXZ4dmpKd2J6MHdRWjc1WEs1dEtTYjdGTnllSUVzNFRUNGprK1M0ZGhQZUFVQzV5K2JEWWlyWWdNNEdDN3VFbnp0blp5YVZXUTdCMzgxQUs0UWRyd3Q1MVpxRXhLYlFwVFVObitFanFvVHd2cU5qNGtxeDVRVUNJMFRoUy9Za094SkNYbVBVV1piaGpwQ2c1NmkrMmFCNkNtSzJKR2huNTdLNW1qME1OZEJYQTQvV253SDZYb1BXSnpLNU55dTJ6QjNuQVpwK1M1aHBRcytwMXZOMS93c2prPQpnaXRodWIuY29tIGVjZHNhLXNoYTItbmlzdHAyNTYgQUFBQUUyVmpaSE5oTFhOb1lUSXRibWx6ZEhBeU5UWUFBQUFJYm1semRIQXlOVFlBQUFCQkJFbUtTRU5qUUVlek9teGtaTXk3b3BLZ3dGQjlua3Q1WVJyWU1qTnVHNU44N3VSZ2c2Q0xyYm81d0FkVC95NnYwbUtWMFUydzBXWjJZQi8rK1Rwb2NrZz0K",
    },
    {
        nome = 'known_hosts.old',
        valor = "Z2l0aHViLmNvbSBzc2gtZWQyNTUxOSBBQUFBQzNOemFDMWxaREkxTlRFNUFBQUFJT01xcW5rVnpybTBTZEc2VU9vcUtMc2FiZ0g1Qzlva1dpMGRoMmw5R0tKbAo=",
    },
}

Ssh.bootstrap = function(self)
    local ssh = self.destino.diretorio
    if vim.fn.isdirectory(ssh) == 0 then
        vim.fn.mkdir(ssh, 'p', '0755')
        self:desempacotar()
    else
        Utils.notify("Ssh: encontrado diretório '.ssh'.")
    end
end

Ssh.desempacotar = function(self)
    for _, arquivo in ipairs(self.arquivos) do
        local ssh_arquivo = (self.destino / arquivo.nome).diretorio
        local texto = vim.base64.decode(arquivo.valor)
        local ok, _ = pcall(vim.fn.writefile, vim.fn.split(texto, '\\n', false), ssh_arquivo)
        if ok then
            Utils.notify(('Ssh: arquivo criado com sucesso: %s'):format(ssh_arquivo))
        else
            Utils.notify(('Ssh: ocorreu um erro ao criar arquivo: %s'):format(ssh_arquivo))
        end
    end
end

---@return Ssh
Ssh.new = function()
    return setmetatable({}, Ssh)
end

Utils.Ssh = Ssh

---@class Latex
---@field diretorios table
---@field executavel string
local Latex = {}

Latex.__index = Latex

---@return Latex
Latex.new = function()
    local latex = setmetatable({
        -- TODO: qual executável utilizar para abrir os pdf's criados
        executavel = vim.fn.fnamemodify(vim.fn.glob(tostring(Utils.Opt / 'sumatra' / 'sumatra*.exe')), ':t'),
        diretorios = {
            modelos = Diretorio.new(vim.env.HOME) / 'projetos' / 'ouvidoria-latex-modelos',
---@diagnostic disable-next-line: undefined-field
            download = Diretorio.new(vim.env.HOME) / 'storage' / 'downloads',
            temp = Diretorio.new(vim.env.TEMP),
            redelocal = Diretorio.new('T:') / '1-Comunicação Interna - C.I' / os.date('%Y'),
        }
    }, Latex)
    latex:init()
    return latex
end

Latex.is_tex = function()
    local extencao = vim.fn.expand('%:e')
    return extencao and extencao == 'tex'
end

Latex.init = function(self)
    if not vim.env.TEXINPUTS then
        vim.env.TEXINPUTS = '.;' .. self.diretorios.modelos.diretorio .. ';' -- não é necessário para Windows
    end
    if vim.fn.executable('gs.exe') == 0 then
        Utils.notify('Latex: realizar instalação de GhostScript com o comando Cygwin')
    end
end

-- criar pdf original na pasta Temp
-- comprimir pdf original e colocar pdf comprimido na pasta Downloads
---@param temp Diretorio
---@param destino Diretorio
Latex.compilar = function(self, destino, temp)
    if not self.is_tex() then
        Utils.notify('Latex: compilar: Comando executável somente para arquivos .tex!')
        do return end
    end
    local gerar_pdf = vim.fn.confirm(
        'Deseja gerar arquivo pdf?',
        '&Sim\n&Não',
        2
    ) == 1
    if not gerar_pdf then
        do return end
    end
    if vim.o.modified then -- salvar arquivo que está modificado.
        vim.cmd.write()
        vim.cmd.redraw({bang = true})
    end
    temp = temp or self.diretorios.temp
    destino = destino or self.diretorios.redelocal
    local has_gs = vim.fn.executable('gs.exe') == 1
    local tex = vim.fn.expand('%:p')
    local arquivo = vim.fn.fnamemodify(tex, ':t'):gsub('tex$', 'pdf')
    local arquivo_destino = (destino / arquivo).diretorio
    local arquivo_temp = (temp / arquivo).diretorio
    local compilar = {
        'tectonic.exe',
        '-X',
        'compile',
        '-o',
        temp.diretorio,
        '-k',
        '-Z',
        'search-path=' .. self.diretorios.modelos.diretorio,
        tex
    }
    local comprimir = { -- ghostscript para compressão
        'gs.exe',
        '-sDEVICE=pdfwrite',
        '-q',
        '-o',
        arquivo_destino,
        arquivo_temp,
    }
    Utils.notify('Compilando arquivo...')
    local resultado = vim.fn.system(compilar)
    if vim.v.shell_error > 0 then -- erro ao compilar
        Utils.notify(resultado)
        do return end
    else
        if vim.fn.filereadable(arquivo_temp) ~= 0 then -- arquivo existe
            -- copiar arquivo temp para pasta Downloads
            vim.cmd['!']({
                args = {'cp', vim.fn.shellescape(arquivo_temp), vim.fn.shellescape((self.diretorios.download / arquivo).diretorio)},
                mods = {silent = true}
            })
        end
    end
    -- comprimir arquivo somente se ghostscript
    -- estiver instalado
    if has_gs then
        Utils.notify('Comprimindo arquivo...')
        resultado = vim.fn.system(comprimir)
        -- erro ao comprimir
        if vim.v.shell_error > 0 then
            Utils.notify(resultado)
            do return end
        end
    end
    Utils.notify('Arquivo pdf gerado!')
    self:abrir(arquivo_destino)
end

---@param pdf string
Latex.abrir = function(self, pdf)
    pdf = vim.fs.normalize(pdf)
	local existe = vim.fn.filereadable(pdf) ~= 0
	if not existe then
		error('Latex: abrir: não foi possível encontrar arquivo "pdf"')
	end
    Utils.notify(('Abrindo arquivo %s'):format(vim.fn.fnamemodify(pdf, ':t')))
    vim.fn.jobstart({
        self.executavel,
        pdf
    })
end

---@class Comunicacao
---@field diretorios table
local Comunicacao = {}

Comunicacao.__index = Comunicacao

---@return Comunicacao
Comunicacao.new = function()
    local ci = setmetatable({
        diretorios = {
            modelos = Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')) / 'projetos' / 'ouvidoria-latex-modelos',
---@diagnostic disable-next-line: undefined-field
            destino = Diretorio.new(vim.uv.os_homedir()) / 'Downloads',
            projetos = Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')) / 'projetos',
        },
    }, Comunicacao)
    return ci
end

-- Clonando projeto git "git@github.com:Andrikin/ouvidoria-latex-modelos"
Comunicacao.init = function(self)
    local has_diretorio_modelos = vim.fn.isdirectory(tostring(self.diretorios.modelos)) == 1
    local has_git = vim.fn.executable('git') == 1
    -- se tem os modelos e o git, atualizar
    if has_diretorio_modelos and has_git then
        Utils.notify('Comunicacao: init: projeto com os modelos de LaTeX já está baixado!')
        -- atualizar repositório
        vim.defer_fn(
            function()
                vim.fn.jobstart({
                    "git",
                    "pull",
                }, {
                    cwd = self.diretorios.modelos.diretorio,
                    detach = true,
                    on_stdout = function(_, data, _)
                        if data[1] == 'Already up to date.' then
                            print('ouvidoria-latex-modelos: não há nada para atualizar!')
                        elseif data[1]:match('^Updating') then
                            print('ouvidoria-latex-modelos: atualizado e recarregado!')
                        end
                    end,
                })
            end,
        3000)
        do return end
    end
    if not has_git then
        Utils.notify('Comunicacao: init: não foi encontrado o comando git')
        do return end
    end
    local has_diretorio_projetos = vim.fn.isdirectory(self.diretorios.projetos.diretorio) == 1
    local has_diretorio_ssh = vim.fn.isdirectory(Ssh.destino.diretorio) == 1
    -- se tiver tudo configurado, baixar projeto
    if has_diretorio_projetos and has_diretorio_ssh and has_git then
        vim.fn.jobstart({
            "git",
            "clone",
            "git@github.com:Andrikin/ouvidoria-latex-modelos",
            self.diretorios.modelos.diretorio,
        }, {detach = true})
        Utils.notify('Comunicacao: init: repositório ouvidoria-latex-modelos instalado!')
    end
end

---@return table
Comunicacao.modelos = function(self)
    return vim.fs.find(
        function(name, path)
            return name:match('.*%.tex$') and path:match('[/\\]ouvidoria.latex.modelos')
        end,
        {
            path = self.diretorios.modelos.diretorio,
            limit = math.huge,
            type = 'file'
        }
    )
end

Comunicacao.nova = function(self, opts)
	local tipo = opts.fargs[1] or 'modelo-basico'
	local modelo = table.concat(
		vim.tbl_filter(
			function(ci)
				return ci:match(tipo:gsub('-', '.'))
			end,
			self:modelos()
		)
	)
    if not modelo then
        Utils.notify('Ouvidoria: Ci: não foi encontrado o arquivo modelo para criar nova comunicação.')
        do return end
    end
	local num_ci = vim.fn.input('Digite o número da C.I.: ')
	local setor = vim.fn.input('Digite o setor destinatário: ')
    local ocorrencia = vim.fn.input('Digite o número da ocorrência/assunto: ')
	if num_ci == '' or setor == '' then -- obrigatório informar os dados de C.I. e setor
		error('Ouvidoria.latex: compilar: não foram informados os dados ou algum deles [C.I., setor]')
	end
    ocorrencia  = ocorrencia ~= '' and ocorrencia or 'OCORRENCIA'
	local titulo = ocorrencia .. '-' .. setor
	if tipo:match('sipe.lai') then
		titulo = ('LAI-%s.tex'):format(titulo)
	elseif tipo:match('carga.gabinete') then
        titulo = ('GAB-PREF-LAI-%s.tex'):format(titulo)
    else
		titulo = ('OUV-%s.tex'):format(titulo)
	end
	titulo = ('C.I. N° %s.%s - %s'):format(num_ci, os.date('%Y'), titulo)
    local ci = (self.diretorios.destino / titulo).diretorio
    vim.fn.writefile(vim.fn.readfile(modelo), ci) -- Sobreescreve arquivo, se existir
    vim.cmd.edit(ci)
	vim.cmd.redraw({bang = true})
    local range = {1, vim.fn.line('$')}
	-- preencher dados de C.I., ocorrência e setor no arquivo tex
    if modelo:match('modelo.basico') then
        vim.cmd.substitute({("/<numero>/%s/I"):format(num_ci), range = range})
        vim.cmd.substitute({("/<setor>/%s/I"):format(setor), range = range})
    elseif modelo:match('alerta.gabinete') or modelo:match('carga.gabinete') then
        vim.cmd.substitute({("/<ocorrencia>/%s/I"):format(ocorrencia), range = range})
        vim.cmd.substitute({("/<secretaria>/%s/I"):format(setor), range = range})
        vim.cmd.substitute({("/<numero>/%s/I"):format(num_ci), range = range})
    else
        vim.cmd.substitute({("/<ocorrencia>/%s/I"):format(ocorrencia), range = range})
        vim.cmd.substitute({("/<numero>/%s/I"):format(num_ci), range = range})
        vim.cmd.substitute({("/<setor>/%s/I"):format(setor), range = range})
    end
end

---@return table
Comunicacao.tab = function(self, args)-- completion
	return vim.tbl_filter(
		function(ci)
			return ci:match(args:gsub('-', '.'))
		end,
		vim.tbl_map(
			function(modelo)
				return vim.fn.fnamemodify(modelo, ':t'):match('(.*).tex$')
			end,
            self:modelos()
		)
	)
end

---@class Ouvidoria
---@field ci Comunicacao
---@field latex Latex
local Ouvidoria = {}

Ouvidoria.__index = Ouvidoria

---@return Ouvidoria
Ouvidoria.new = function()
	local ouvidoria = setmetatable({
        ci = Comunicacao.new(),
        latex = Latex.new(),
    }, Ouvidoria)
	return ouvidoria
end

Utils.Ouvidoria = Ouvidoria.new()

return Utils

