local ls = require("luasnip")
local s = ls.snippet
-- local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
-- local c = ls.choice_node
-- local r = ls.restore_node
--local rep = require("luasnip.extras").rep
local fmta = require("luasnip.extras.fmt").fmta

return {
    -- Comandos padrão Latex
    s('href',
        {t("\\href{"), i(1, 'url_site'), t("}"), t("{"), i(2, 'inserir_texto'), t("}")}
    ),
    s('textbf', {t("\\textbf{"), i(1), t("}")}),
    s('textit', {t("\\textit{"), i(1), t("}")}),
    s('uline', {t("\\uline{"), i(1), t("}")}),
    s('noindent', t("{\\noindent}")),
    s('pagebreak', {t("\\pagebreak["), i(1, '4'), t("]")}),
    -- Comandos customizados Latex
    s({trig = 'Ocorrencia'},
        {t("\\Ocorrencia{"), i(1), t("}["), i(2, vim.fn.strftime('%Y')), t("]")}
    ),
    s({trig = 'Associados'},
        {t("{\\Associados}")}
    ),
    s({trig = 'Considerando'},
        {t("{\\Considerando}")}
    ),
    s({trig = 'Email'},
        {t("\\Email{"), i(1), t("}")}
    ),
    s({trig = 'Assinaturas'},
        fmta(
[[
\Assinaturas%
{<>,<>}%
[<>,<>]
]], {i(1), i(2), i(3), i(4)}
        )
    ),
    s({trig = 'DataProrrogacao'},
        {
            t("\\DataProrrogacao{"), i(1, 'data_cadastro'), t("}"),
            t("["), i(2, vim.fn.strftime('%Y')), t("]")
        }
    ),
    s({trig = 'Codigo'},
        {
            t("\\Codigo{"), i(1), t("}"),
            t("["), i(2, vim.fn.strftime('%Y')), t("]")
        }
    ),
    s({trig = 'Cabecalho'},
        fmta(
[[
\Cabecalho[<>]{<>}{<>}
]], {i(1, 'C.I.'), i(2), i(3)}
        )
    ),
    s({trig = 'figura'},
        {
            t("\\figura{"), i(1), t("}"), t("{"), i(2), t("}")
        }
    ),
    s({ trig = "modelo-basico" },
        fmta(
[[
\documentclass[
	12pt,
	oneside,
	a4paper,
]{article}

\usepackage{prefeitura/ci}

%%%DOCUMENTO%%%

\begin{document}

\Cabecalho{<>}{<>}% código da CI/destinatário

\Assunto{%
    {<>}% digite o assunto da CI aqui
}%

Prezados,

<>

\Cumprimento

\Atenciosamente

\Assinaturas
{André Alexandre Aguiar,Agente em Atividades Administrativas}%
[Ana Caroline Emilio Weidt,Diretora de Ouvidoria]

\end{document}
]], { i(1), i(2), i(3), i(4) }
        )
    ),
}
