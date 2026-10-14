---
description: schematize-cpp — carrega à força TODO o corpo normativo do piso de C++ e passa a aplicá-lo nesta sessão.
---
Carregue **agora** o corpo normativo da skill `schematize-cpp`
(`.claude/skills/schematize-cpp/references/*.md`):

- `escopo.md` — **primeiro**: **componente novo de sistema nasce em Rust ou Zig**; C++ entra por
  **ADR de exceção** (ecossistema que só existe em C++, base grande já mantida, interop pesada,
  plataforma certificada). Traz também o **limite honesto de "modernizar"**: trocar `new`/`delete`
  por `unique_ptr` num módulo maduro paga; reescrever a hierarquia inteira troca bugs conhecidos por
  bugs novos.
- `piso.md` — **C++ moderno de verdade** (*"C com classes" junta os riscos do C com a complexidade
  do C++*): **RAII como mecanismo** (VETADO `new`/`delete` cru; **regra do zero ou dos cinco**),
  **tempo de vida** (`string_view` para temporário, lambda `[&]` em assíncrono, iterador
  invalidado), a **lista curta de UB** — com o ponto que quase ninguém escreve: **UB autoriza o
  compilador a assumir que aquilo não acontece**, e é assim que uma checagem de `nullptr` some do
  binário —, sanitizers e flags (`-Wold-style-cast`, `-D_GLIBCXX_ASSERTIONS`), exceção (`noexcept`
  no move, `catch (const X&)`, destrutor não lança), concorrência (`std::jthread`), CMake por
  *targets*.
- `stack-versoes.md` — ferramental **verificado rodando** nesta máquina (g++ 14.2).

Depois, rode o gate: `bash .claude/skills/schematize-cpp/scripts/check-cpp.sh .` — e **rode a suíte
sanitizada**, que o gate não substitui.
