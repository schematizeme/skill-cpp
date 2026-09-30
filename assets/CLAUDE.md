# Piso de C++ (schematize-cpp) — sempre-on

> **Componente novo de sistema nasce em Rust ou Zig.** C++ entra por **ADR de exceção**, não por
> fit. O que segue vale para o C++ que já existe ou que o ADR autorizou.

1. **RAII é o mecanismo:** VETADO `new`/`delete` cru; `unique_ptr` por default; `shared_ptr` só com
   posse realmente compartilhada (ciclo se quebra com `weak_ptr`).
2. **Regra do zero ou dos cinco** — só o destrutor é o caminho para double-free na cópia implícita.
3. **`lock_guard`/`scoped_lock`**, nunca `mutex.lock()` manual.
4. **Tempo de vida:** `string_view`/`span`/referência que sobrevive ao dono é UB; lambda `[&]` em
   assíncrono é o mesmo bug com roupa nova.
5. **Sanitizers no CI** (ASan/UBSan/TSan), UBSan **com `-fno-sanitize-recover=all`**.
6. **`-Wall -Wextra -Werror -Wconversion -Wold-style-cast -D_GLIBCXX_ASSERTIONS`**, `-std=c++20`
   explícito.
7. **`catch (const X&)`** — nunca `catch (...)` vazio nem por valor (que fatia); **destrutor não
   lança**; `noexcept` no move.
8. **`std::atomic`, não `volatile`**; `std::jthread` em vez de `std::thread` sem `join`.
9. **Parser tem fuzzing**; dependência com versão fixada.
10. **Teste que passa sem sanitizer não prova ausência de UB.**
11. **Orquestrador não desenvolve; subagent barato executa.** O agent principal só planeja, despacha e
    revisa; ação onerosa vira micro-tasks para subagents em `sonnet` (falhou → o mesmo subagent corrige →
    re-decompõe → só então `opus`, com motivo). Detalhe: `schematize-engineering` → `references/orquestracao.md` §9.

Gate: `bash .claude/skills/schematize-cpp/scripts/check-cpp.sh .`
