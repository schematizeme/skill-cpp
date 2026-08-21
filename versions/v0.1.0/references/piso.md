# O piso de C++ da casa — moderno, ou não vale a pena

> Parte da skill **schematize-cpp**. Ela é **defensiva**, como a `schematize-c`: componente novo de
> sistema nasce em **Rust ou Zig** (`escopo.md`). Para o C++ que existe ou é inevitável, o piso é
> **C++ moderno de verdade** — porque C++ escrito como "C com classes" tem os riscos do C **e** a
> complexidade do C++, sem nenhuma das garantias.

Convenção: **MUST** = o gate cobra · **VETADO** = piso.

---

## 1. RAII não é estilo — é o mecanismo

**Todo recurso tem dono, e o dono é um tipo.** Memória, arquivo, socket, lock, handle: adquiridos no
construtor, liberados no destrutor. É isso que faz o `return` no meio, a exceção e o `break`
liberarem tudo **sem você escrever nada**.

- **VETADO `new`/`delete` cru** em código novo. Use `std::make_unique`/`std::make_shared`, container,
  ou um tipo RAII próprio. `delete` que não roda por causa de um `return` antecipado é vazamento; o
  que roda duas vezes é corrupção.
- **`unique_ptr` por default; `shared_ptr` só quando a posse é REALMENTE compartilhada.** `shared_ptr`
  não é "ponteiro fácil": ele custa contagem atômica e cria **ciclo** (que vaza) — e o ciclo se quebra
  com `weak_ptr`, deliberadamente.
- **`std::lock_guard`/`scoped_lock`**, nunca `mutex.lock()` manual: com exceção no meio, o `unlock`
  não acontece.
- **Regra do zero:** se a sua classe não gerencia recurso, **não escreva** destrutor, cópia nem move.
  Se gerencia, escreva **os cinco** (ou delete-os). Escrever só o destrutor é o caminho clássico para
  double-free na cópia implícita.

## 2. Tempo de vida — o que o compilador não vê

- **Referência/ponteiro/`string_view`/`span` que sobrevive ao dono é UB.** `string_view` para
  temporário (`f(std::string("x"))` guardando a view) é dangling **imediatamente**.
- **Captura por referência em lambda que sai do escopo** (`[&]` num `std::thread`, num callback
  assíncrono, numa corrotina) é a versão moderna do mesmo bug. Em código assíncrono, capture **por
  valor**.
- **Iterador invalidado:** `push_back` num `vector` invalida iteradores e referências. Guardar
  referência para elemento e continuar inserindo é UB silencioso.
- **`std::thread` não `join`/`detach` ⇒ `std::terminate`** no destrutor. Use `std::jthread` (que faz
  o join sozinho e ainda carrega `stop_token`).

## 3. Comportamento indefinido — a lista curta que mais aparece

- **Overflow de inteiro com sinal**, shift ≥ largura do tipo, conversão que perde sinal.
- **Ler variável não inicializada**; usar objeto após `move` (o estado é *válido mas não
  especificado* — só `assign`/destruição são garantidos).
- **`reinterpret_cast` e type punning fora de `std::bit_cast`/`memcpy`** (a regra do *strict
  aliasing* é real: o otimizador usa-a).
- **Ordem de avaliação de argumentos não é definida** — efeito colateral duplo no mesmo `f(i++, i)`
  é UB.
- **UB não "dá erro": ele autoriza o compilador a assumir que aquilo não acontece** — e é assim que
  uma checagem de `nullptr` **depois** de um deref some do binário otimizado. É por isso que
  sanitizer é obrigatório (§4).

## 4. Sanitizers e flags — o piso é ferramenta

**MUST**, no CI:

```bash
# memória (não convive com TSan: são dois jobs)
-fsanitize=address -fno-omit-frame-pointer
# comportamento indefinido — com -fno-sanitize-recover, senão ele imprime e SEGUE
-fsanitize=undefined -fno-sanitize-recover=all
# concorrência
-fsanitize=thread
```

E o build:

```
-std=c++20 -Wall -Wextra -Werror -Wconversion -Wshadow -Wold-style-cast
-Wnon-virtual-dtor -Woverloaded-virtual -Wnull-dereference
-D_GLIBCXX_ASSERTIONS -D_FORTIFY_SOURCE=3 -fstack-protector-strong
```

- **`-D_GLIBCXX_ASSERTIONS`** liga a checagem de precondição da libstdc++ (`vector::operator[]` fora
  de faixa, por exemplo) — custa pouco e pega muito.
- **`-Wold-style-cast`** é o que impede o cast em C voltar pela porta dos fundos.
- **`clang-tidy` com `cppcoreguidelines-*`/`bugprone-*`** no CI, com a lista de checks **no repo**.

## 5. Exceção e erro

- **Decida a política do projeto e escreva-a:** com exceção (o default do C++ moderno) ou sem (com
  `expected`/`Result` e `-fno-exceptions`) — e **não misture** as duas no mesmo módulo.
- **`noexcept` é promessa com dente:** violar chama `std::terminate`. Marque **move** e destrutor
  como `noexcept` (é o que faz `vector` usar move em vez de cópia ao crescer), e nada mais sem
  pensar.
- **VETADO `catch (...) { }`** vazio e capturar por valor (que fatia o objeto): **`catch (const
  X&)`**.
- **Destrutor não lança.** Exceção durante desempilhamento = `std::terminate`.

## 6. Concorrência

- **`std::atomic`** para o que é compartilhado sem lock; `volatile` **não é** ferramenta de
  concorrência (nem em C++).
- **Ordem de aquisição de locks documentada**; `scoped_lock` para múltiplos (evita deadlock por
  ordem).
- **TSan no CI** onde há thread; **data race é UB**, não "resultado esquisito".

## 7. Build e dependência

- **CMake moderno (targets, não variáveis globais)**: `target_link_libraries`,
  `target_compile_options` — flags que vazam para o mundo são a origem de "aqui compila, ali não".
- **Dependência com versão fixada** (vcpkg/Conan com lock, ou submódulo por SHA) e licença
  verificada.
- **Um padrão de linguagem por projeto**, declarado (`CMAKE_CXX_STANDARD` + `CXX_STANDARD_REQUIRED`).

## 8. Teste

Disciplina da **`schematize-qa`** (GoogleTest/Catch2 como runner). A suíte roda **sanitizada** (§4),
e **parser tem fuzzing** (libFuzzer), com corpus versionado. Teste que passa sem sanitizer **não
prova ausência de UB**.
