---
name: schematize-cpp
metadata:
  version: 0.3.0
description: >-
  Piso defensivo de C++ para manter código existente (*.cpp/*.hpp, CMakeLists.txt); componente novo nasce em Rust ou
  Zig, C++ só por ADR. Use em C++: sanitizers, clang-tidy, RAII sem new/delete cru. Traz gate e CI.
---
<!-- cross-skill: linguagens.md -> schematize-engineering -->

# O piso de C++ da casa (schematize-cpp)

Skill **defensiva**, irmã da `schematize-c`. Ela não abre a porta do C++: ela mantém em pé o C++ que
a casa **já tem** ou que é **inevitável**.

**Versão:** skill `schematize-cpp` v0.3.0. Changelog em `CHANGELOG.md`.

## Precedência e herança (leia antes de divergir)

<!-- herdado:engineering/precedencia:foraRol intro="Esta skill é o recorte **C++** das linguagens **sancionadas fora do rol de backend** (`schematize-engineering` → `references/linguagens.md` §2.2): **manutenção defensiva**. Componente novo de sistema nasce em Rust ou Zig, por ADR; C++ não recebe serviço backend novo." cmd="cpp" -->Esta skill é o recorte **C++** das linguagens **sancionadas fora do rol de backend** (`schematize-engineering` → `references/linguagens.md` §2.2): **manutenção defensiva**. Componente novo de sistema nasce em Rust ou Zig, por ADR; C++ não recebe serviço backend novo.

1. **Onde esta skill divergir da base, a BASE MANDA.** Aqui mora a especialização — a lib, o gate, a
   sintaxe da linguagem. Divergência de *piso* é defeito desta skill, não variante local.
2. **O que não está repetido aqui é HERDADO, não dispensado.** Valem integralmente, sem cópia local:
   - **§28 Archive** — `<projeto>/<projeto>_archive/` é **repositório git próprio, PRIVADO e
     obrigatório**, criticidade 0 (`schematize-archive`).
   - **§35 Definition of Done** e a lista de anti-padrões (citada por **título**, nunca por número).
   - **§39 Índice/MAPA** — enumeração exaustiva (uma entrada por unidade chamável, `M == N`) e grafo
     com arestas em ASCII (`A -> B`), nunca a seta unicode.
   - **IAM** (`schematize-engineering` → `references/iam.md`): identidade ≠ email, ≥2 fatores, ReBAC
     multi-tenant, argon2id-only para senha nova, sessão longa e logout irreversível.
   - **Efeito externo** nunca sai de não-produção (`schematize-engineering` →
     `references/efeitos-externos.md`).
   - **Orquestração** (`schematize-engineering` → `references/orquestracao.md` §9): o principal não
     desenvolve (é Claude Opus); executor mais barato que resolve — `haiku`/`sonnet` → Codex Terra → Cursor → `opus` só após falha; visual direto ao Codex; imagem nunca pelo Claude: detecta Codex/Gemini e pergunta ao usuário qual usar (Codex é a sugestão, não automática), nunca API paga.
3. **QA, ops, IAM e índice não têm comando próprio aqui:** vêm da base `/eng-*`. Para trabalho
   contínuo use `/eng-overdev`; para planejar `/eng-plan`; para varrer a base `/eng-scan`; para
   revisão geral `/eng-review` (e `/eng-ops`, `/eng-iam`, `/eng-index`). Os comandos
   `/cpp-*` cobrem só o piso da linguagem.<!-- /herdado -->

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

Assets prontos para copiar: `assets/ci/github-actions-ci.yml` (clang-tidy, clang-format, build C++20 sanitizado com `_GLIBCXX_ASSERTIONS`, ctest) · `assets/lint/.clang-tidy` · `assets/lint/.clang-format`.

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
11. <!-- herdado:engineering/orquestracao:curto -->**Orquestrador não desenvolve; subagent barato executa.** O agent principal só planeja, despacha e revisa; ação onerosa vira micro-tasks para o executor mais barato que resolve: `haiku` (mecânico) / `sonnet` (código; falhou → mesmo subagent corrige, até 2 rodadas) → Codex `gpt-5.6-terra` → Cursor → subagent `opus` (motivo) → `park`; **visual vai direto ao Codex**; **imagem nunca pelo Claude: detectar Codex/Gemini e perguntar ao usuário qual usar (Codex é a sugestão), nunca API de imagem paga**; papéis em `agentes.toml`. No overdev, cada item do checklist vai a um subagent e o principal revisa antes do `- [x]`. **Sem frota ociosa:** idle com pendência volta ao trabalho; dependente de outro agent → mata e enfileira com gatilho; terminou → mata (§9.6). Detalhe: `schematize-engineering` → `references/orquestracao.md` §9.<!-- /herdado -->

## Relação com as outras skills

- **`schematize-engineering`** — a base e o rol, que manda na escolha de linguagem.
- **`schematize-c`** — a irmã. **C++ não é "C com classes"**: escrever C++ com a mentalidade de C
  junta os riscos de um com a complexidade do outro.
- **`schematize-qa`** — a disciplina de teste; aqui ela roda **sanitizada**.
- **`schematize-pentest`** — o lado ofensivo (overflow, parser hostil, fuzzing dirigido).
