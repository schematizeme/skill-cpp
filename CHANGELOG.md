# Changelog — schematize-cpp

Todas as mudanças relevantes deste pacote, no formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
com versionamento [SemVer](https://semver.org/lang/pt-BR/).

## [0.2.1] — 2026-09-30
Pedido do dono: agents idle poluem a tela e seguram recurso.

### Adicionado
- Piso de orquestração ganha a regra de frota ociosa (idle com pendência volta ao trabalho; dependente de outro agent → mata e enfileira com gatilho; terminou → mata); detalhe na `schematize-engineering` §9.6.

## [0.2.0] — 2026-09-30

Pedido do dono, por **custo**: o orquestrador não desenvolve; ação onerosa vira micro-tasks baratas; `sonnet` é o default dos subagents e `opus` só entra após falha.

### Adicionado
- **Piso "Orquestrador não desenvolve; subagent barato executa"** no `assets/CLAUDE.md` e no `SKILL.md`: o agent principal só planeja, despacha e revisa; ação onerosa vira micro-tasks para subagents em `sonnet` (falhou → o mesmo subagent corrige → re-decompõe → só então `opus`, com motivo). Detalhe na base: `schematize-engineering` → `references/orquestracao.md` §9.

### Mantido (piso inalterado)
- Todos os pisos anteriores e o gate de `scripts/` seguem exatamente como estavam; a mudança é só de orquestração, não de código.

## [0.1.0] — 2026-08-21

Primeira versão, e **defensiva por decisão**: a vistoria de 2026-08-21 registrou que a casa tem **zero código em C++ hoje** e que o nicho **já está coberto por Rust e Zig no rol** — *o valor desta skill não é "mais opções de backend"*. Ela existe para que o C++ que a casa venha a manter (ou herdar) **não vire vulnerabilidade**.

### Adicionado
- **`references/escopo.md`** — **componente novo nasce em Rust ou Zig**; C++ entra por **ADR de exceção** (ecossistema que só existe em C++, base grande já mantida, interop pesada com API C++, plataforma certificada). Com o **limite honesto de "modernizar"**: trocar `new`/`delete` por `unique_ptr` num módulo maduro paga; reescrever a hierarquia inteira troca bugs conhecidos por bugs novos.
- **`references/piso.md`** — **C++ moderno de verdade**, porque *"C com classes" junta os riscos do C com a complexidade do C++ e nenhuma das garantias*: **RAII como mecanismo** (VETADO `new`/`delete` cru — *`delete` que não roda por um `return` antecipado é vazamento; o que roda duas vezes é corrupção*), **regra do zero ou dos cinco** (escrever só o destrutor é o caminho clássico para double-free na cópia implícita), **tempo de vida** (`string_view` para temporário é dangling imediato; lambda `[&]` em código assíncrono; iterador invalidado por `push_back`), a **lista curta de UB** com o ponto que quase ninguém escreve — **UB autoriza o compilador a assumir que aquilo não acontece**, e é assim que uma checagem de `nullptr` **depois** de um deref some do binário otimizado —, sanitizers e flags (`-Wold-style-cast`, **`-D_GLIBCXX_ASSERTIONS`**), exceção (`noexcept` no move é o que faz `vector` mover em vez de copiar; `catch (const X&)`; destrutor não lança), concorrência (`std::jthread`), build por *targets* no CMake.
- **`scripts/check-cpp.sh`** + **`check-cpp.test.sh`** (**10 casos**, 8 vermelhos): `new`/`delete` cru, `mutex.lock()` manual, `catch (...) {}`, `catch` por valor, `volatile` em thread, `std::thread` sem `join`, string do C dentro de C++, `reinterpret_cast`, cast estilo C; e no build: sem sanitizer, **UBSan sem `-fno-sanitize-recover`**, sem `-Wold-style-cast`, sem `_GLIBCXX_ASSERTIONS`, sem `-std=c++20`.

### Verificado rodando (g++ 14.2.0, nesta máquina)
- A mesma bateria da `schematize-c`: **ASan** pegou use-after-free, **UBSan** pegou overflow com sinal (e sem sanitizer o programa **saiu 0**), **`-Werror`** reprovou variável não inicializada.
