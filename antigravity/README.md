# Pasta de troca com o Antigravity

> **PAUSADO (2026-10-04):** a cota de imagens do Gemini acabou e a arte passou a ser feita pela equipe Claude. Não há tarefas pendentes. Não execute nada até o usuário avisar que o Antigravity foi reativado.

Esta pasta conecta a equipe Claude (código) com o Gemini no Antigravity (arte). Os dois trabalham ao mesmo tempo e **só se comunicam por arquivos**.

## Como usar (usuário)

No Antigravity, abra a pasta do projeto e mande para o Gemini:

> Leia `antigravity/INSTRUCOES.md` e siga as regras. Depois execute as tarefas pendentes em `antigravity/tarefas/`.

Quando ele terminar, volte ao Claude Code e diga algo como "o Antigravity entregou, revisa". O Lead Project revisa e escreve `antigravity/revisoes/ART-NNN.md`. Se houver `AJUSTES`, mande o Gemini rodar de novo com a mesma frase acima.

## Quem escreve onde

| Pasta | Escrito por |
|---|---|
| `INSTRUCOES.md`, `tarefas/`, `revisoes/` | Claude |
| `entregas/`, `ferramentas/` | Gemini (Antigravity) |

O arquivo `.gdignore` impede o Godot de importar estas imagens. Artes aprovadas são copiadas e adaptadas para `assets/` pelo Developer.
