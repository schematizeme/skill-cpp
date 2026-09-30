---
name: schematize-cpp
metadata:
  version: 0.2.2
description: O piso de C++ da casa — DEFENSIVO, como o de C: componente novo de sistema nasce em **Rust ou Zig**, e C++ entra por **ADR de exceção** (ecossistema que só existe em C++, base grande já mantida, interop pesada, plataforma certificada). Para o C++ que existe, o piso é **C++ moderno de verdade** — porque "C com classes" junta os riscos do C com a complexidade do C++ e nenhuma das garantias: **RAII como mecanismo** (VETADO `new`/`delete` cru; regra do zero ou dos cinco), tempo de vida (`string_view`/lambda `[&]`/iterador invalidado), a lista curta de UB (e o fato de que **UB autoriza o compilador a assumir que aquilo não acontece** — é assim que a checagem de `nullptr` some do binário), **ASan/UBSan/TSan no CI** com `-fno-sanitize-recover`, `-Wold-style-cast`, `_GLIBCXX_ASSERTIONS`, `noexcept` no move, `catch (const X&)`, `std::jthread` e fuzzing de parser. Traz gate executável que também lê o build.
---
<!-- cross-skill: linguagens.md -> schematize-engineering -->

# O piso de C++ da casa (schematize-cpp)

Skill **defensiva**, irmã da `schematize-c`. Ela não abre a porta do C++: ela mantém em pé o C++ que
a casa **já tem** ou que é **inevitável**.

**Versão:** skill `schematize-cpp` v0.2.2. Changelog em `CHANGELOG.md`.

## A regra, antes de tudo

**Componente novo de sistema nasce em Rust ou Zig.** C++ entra por **ADR de exceção**, não por fit —
o nicho já está coberto por duas linguagens do rol que entregam o mesmo **com verificação**
(`references/escopo.md`).

## Comandos (Claude Code)

| Comando | O que faz |
|---|---|
| `/cpp-help` | lista os comandos |
| `/cpp-load` | carrega à força o corpo normativo (piso, escopo) |
| `/cpp-review` | revisa `.cpp`/`.hpp` e o build contra o piso: roda o gate e lê o que a máquina não lê |
| `/cpp-claude` | cria/mescla o `CLAUDE.md` sempre-on na raiz do repo |
| `/cpp-cc` · `/cpp-handoff` | context compact / handoff arquivado |

## Como usar

1. **Confirme que é caso de C++** (`references/escopo.md`).
2. **Rode o gate:** `bash scripts/check-cpp.sh .` — `0` passa · `1` reprova · `2` **nada para
   verificar**. Ele lê o código **e o build**.
3. **Rode a suíte sanitizada.** O gate não substitui isso — e diz isso na saída.

Mapa de references:

| Tarefa | Reference |
|---|---|
| RAII e ponteiro, tempo de vida, a lista curta de UB, sanitizers e flags, exceção e `noexcept`, concorrência, build e dependência, teste | `references/piso.md` |
| **Onde C++ entra e por que ele não é escolha de fit**; ADR de exceção; o limite honesto de "modernizar"; fronteira com C | `references/escopo.md` |
| Ferramental verificado, padrão declarado, checks do clang-tidy | `references/stack-versoes.md` |

## Pisos inegociáveis (vetam o atalho)

1. **Componente novo nasce Rust/Zig.** C++ é ADR de exceção.
2. **RAII é o mecanismo:** VETADO `new`/`delete` cru em código novo; `unique_ptr` por default;
   `shared_ptr` só com posse realmente compartilhada (e ciclo se quebra com `weak_ptr`).
3. **Regra do zero ou dos cinco.** Escrever só o destrutor é o caminho clássico para double-free na
   cópia implícita.
4. **`lock_guard`/`scoped_lock`**, nunca `mutex.lock()` manual.
5. **Tempo de vida:** `string_view`/`span`/referência que sobrevive ao dono é UB; lambda `[&]` em
   código assíncrono é a versão moderna do mesmo bug.
6. **A suíte roda sanitizada** (ASan/UBSan/TSan) **no CI**, com **`-fno-sanitize-recover=all`**.
7. **`-Wall -Wextra -Werror -Wconversion -Wold-style-cast`** e **`-D_GLIBCXX_ASSERTIONS`**.
8. **`catch (const X&)`** — nunca `catch (...)` vazio nem captura por valor (que fatia o objeto);
   **destrutor não lança**.
9. **`std::atomic`, não `volatile`**; `std::thread` sem `join`/`detach` chama `std::terminate` —
   prefira `std::jthread`.
10. **Parser tem fuzzing**, e **teste que passa sem sanitizer não prova ausência de UB**.
11. <!-- herdado:engineering/orquestracao:curto -->**Orquestrador não desenvolve; subagent barato executa.** O agent principal só planeja, despacha e revisa; ação onerosa vira micro-tasks para subagents em `sonnet` (falhou → o mesmo subagent corrige, até 2 rodadas → re-decompõe → só então `opus`, com motivo). No overdev, cada item do checklist vai a um subagent e o principal revisa antes do `- [x]`. **Sem frota ociosa:** idle com pendência volta ao trabalho; dependente de outro agent → mata e enfileira com gatilho; terminou → mata (§9.6). Detalhe: `schematize-engineering` → `references/orquestracao.md` §9.<!-- /herdado -->

## Relação com as outras skills

- **`schematize-engineering`** — a base e o rol, que manda na escolha de linguagem.
- **`schematize-c`** — a irmã. **C++ não é "C com classes"**: escrever C++ com a mentalidade de C
  junta os riscos de um com a complexidade do outro.
- **`schematize-qa`** — a disciplina de teste; aqui ela roda **sanitizada**.
- **`schematize-pentest`** — o lado ofensivo (overflow, parser hostil, fuzzing dirigido).
