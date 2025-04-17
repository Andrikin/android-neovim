## Configuração INIT.LUA

Ainda precisa de ajustes...

- [ ] multithreads, coroutines... Instalação das dependências do neovim
- [ ] arrumar plugins customizados (refazer para lua)
- [x] comando customizado 'HexEditor' não funciona ('%!xxd') -> função requeria um terceiro argumento
- [x] mapeamento '&&' não funciona -> necessitou de da função pcall() como wrapper para suprimir erros
- [x] mapeamento '<c-l>' para vim-capslock em CommandMode não funciona -> modificado plugin para criar o mapeamento dentro do CommandMode
- [x] mapeamento '<leader>r' para abrir $MYVIMRC -> precisava da declaração do mapleader antes
- [x] lsp python com exit signal code 216 -> Erro ao setar o valor de NODE_SKIP_PLATFORM_CHECK
