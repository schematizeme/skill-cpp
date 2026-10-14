---
description: schematize-cpp — revisa C++ contra o piso: roda o gate (código + build) e depois lê o que a máquina não lê (RAII, tempo de vida, UB, escopo)
argument-hint: "[arquivo.cpp/.hpp ou diretório]"
---

# /cpp-review

## 0. A pergunta que vem antes

**Isto é mesmo caso de C++?** Componente novo de sistema **nasce em Rust ou Zig**
(`references/escopo.md`). Sem ADR de exceção, o review termina aqui, com o encaminhamento.

## 1. A máquina

```bash
bash .claude/skills/schematize-cpp/scripts/check-cpp.sh .   # lê o código E o build
cmake --build build --target test-asan     # a suíte sanitizada — o gate NÃO substitui isto
cmake --build build --target test-ubsan
clang-tidy -p build src/*.cpp
```

`0` passa · `1` reprova · `2` **nada para verificar** (não é aprovação).

## 2. O que a máquina não lê

- **RAII:** todo recurso tem **dono que é um tipo**? sobrou `new`/`delete` cru? o `shared_ptr` é
  posse **realmente** compartilhada — ou virou "ponteiro fácil" (com contagem atômica e risco de
  ciclo)?
- **Regra do zero ou dos cinco:** a classe que não gerencia recurso **não** declara destrutor/cópia/
  move? a que gerencia declara **os cinco** (ou os deleta)? *(Só o destrutor é o caminho clássico
  para double-free na cópia implícita.)*
- **Tempo de vida:** há `string_view`/`span`/referência sobrevivendo ao dono? lambda `[&]` em código
  assíncrono (thread, callback, corrotina)? iterador guardado enquanto o container cresce?
- **UB:** overflow com sinal, uso após `move`, `reinterpret_cast` fora de `bit_cast`/`memcpy`,
  leitura de não inicializado. Lembre: **UB autoriza o compilador a assumir que aquilo não
  acontece** — é assim que a checagem de `nullptr` some do binário otimizado.
- **Exceção:** a política do projeto está **escrita** (com ou sem exceção) e não misturada?
  `catch (const X&)` em toda parte, nenhum `catch (...)` vazio, destrutor que não lança, `noexcept`
  no move?
- **Concorrência:** `std::atomic` em vez de `volatile`? `scoped_lock` para múltiplos locks?
  `std::jthread` em vez de `std::thread` solto?
- **Build:** `-Werror`, `-Wold-style-cast`, `-D_GLIBCXX_ASSERTIONS`, `-std=c++20` **explícito**? o
  CMake usa *targets* (flag global vaza e produz "aqui compila, ali não")?

## 3. Feche

Achado vira correção no mesmo PR ou item de checklist com dono. Mexeu no gate? rode o vermelho:
`bash scripts/check-cpp.test.sh` (10 casos).
