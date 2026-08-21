# Anexo volátil — ferramental (C++)

> Parte da skill **schematize-cpp**. **Fonte volátil:** prazo de validade, atualizado à parte do
> corpo normativo (regra `anexo-volatil` do lint).
>
> **Verificado em: 2026-08-21**, na máquina de referência (Debian, **g++ 14.2.0**).

## Padrão e compilador

- **Piso: `-std=c++20`** declarado (`CMAKE_CXX_STANDARD` + `CXX_STANDARD_REQUIRED ON`), nunca o
  default do compilador.
- **Dois compiladores no CI** (gcc e clang) quando possível — cada um emite aviso que o outro não
  emite, e a diferença costuma ser UB real.

## Ferramental

| Ferramenta | Papel | Nota |
|---|---|---|
| **ASan/UBSan/TSan** | memória, UB, data race | UBSan **com `-fno-sanitize-recover=all`**; ASan e TSan em **jobs separados** |
| **`-D_GLIBCXX_ASSERTIONS`** | precondição da libstdc++ (ex.: `operator[]` fora de faixa) | custa pouco, pega muito |
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
