# Anexo volátil — ferramental (C++)

> Parte da skill **schematize-cpp**. **Fonte volátil:** prazo de validade, atualizado à parte do
> corpo normativo (regra `anexo-volatil` do lint).
>
> **Verificado em: 2026-08-21** (ferramental, na máquina de referência, Debian, **g++ 14.2.0**); padrão verificado em 2026-10-14 por documentação.

## Padrão e compilador

- **Piso: `-std=c++20`** declarado (`CMAKE_CXX_STANDARD` + `CXX_STANDARD_REQUIRED ON`), nunca o
  default do compilador.
- **Piso `c++20`; `c++23` permitido** (e alvo recomendado) para código novo quando todos os
  compiladores do CI o suportam. **C++26** teve o trabalho técnico concluído pelo comitê em
  março/2026 (inclui contratos e reflexão); publicação ISO e suporte pleno dos compiladores ainda
  em curso — use por ADR, recurso a recurso. <!-- reverificar: publicação ISO do C++26 -->
- **Modo hardened das bibliotecas padrão:** libstdc++ `-D_GLIBCXX_ASSERTIONS`; libc++
  `-D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST` (ou `_EXTENSIVE`/`_DEBUG`). Barato e liga
  checagem de limites em `operator[]`, `front()` etc. — ligue em release.
- **Dois compiladores no CI** (gcc e clang) quando possível — cada um emite aviso que o outro não
  emite, e a diferença costuma ser UB real.

## Ferramental

| Ferramenta | Papel | Nota |
|---|---|---|
| **ASan/UBSan/TSan** | memória, UB, data race | UBSan **com `-fno-sanitize-recover=all`**; ASan e TSan em **jobs separados** |
| **`-D_GLIBCXX_ASSERTIONS`** / **`_LIBCPP_HARDENING_MODE`** | precondição da libstdc++ / hardening da libc++ (ex.: `operator[]` fora de faixa) | custa pouco, pega muito |
| **clang-tidy** | `cppcoreguidelines-*`, `bugprone-*`, `modernize-*` | lista de checks **no repo**, travando o CI |
| **clang-format** | formatação | `--dry-run --Werror` no CI |
| **libFuzzer / AFL++** | fuzzing de parser | corpus versionado |
| **GoogleTest / Catch2** | runner de teste | disciplina na `schematize-qa` |
| **vcpkg / Conan** | dependência com versão fixada | ou submódulo por SHA |
| **CMake moderno** | build por *targets* | flags globais vazam e produzem "aqui compila, ali não" |

## Regra que NÃO é volátil

`new`/`delete` cru em código novo, `catch (...) {}`, `volatile` como concorrência, UBSan sem
`-fno-sanitize-recover` e parser sem fuzzing são VETADOS **em qualquer versão** — e **componente
novo nasce Rust/Zig**.
