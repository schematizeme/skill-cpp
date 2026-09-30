#!/usr/bin/env bash
# Vermelho primeiro do gate de C++.
#
# strict-ok: harness de teste — continua depois de um caso vermelho (`schematize-shell` -> `references/piso.md` secao 1)
set -u
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
G="$AQUI/check-cpp.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT INT TERM
ok=0; fail=0

CMAKE_BOM='cmake_minimum_required(VERSION 3.20)
project(exemplo CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_compile_options(-std=c++20 -Wall -Wextra -Werror -Wconversion -Wold-style-cast -D_GLIBCXX_ASSERTIONS)
add_library(san_asan INTERFACE)
target_compile_options(san_asan INTERFACE -fsanitize=address -fno-omit-frame-pointer)
add_library(san_ub INTERFACE)
target_compile_options(san_ub INTERFACE -fsanitize=undefined -fno-sanitize-recover=all)
'

caso() {
  local nome="$1" esp="$2" agulha="$3" cm="${4:-$CMAKE_BOM}"
  local d="$TMP/$nome"; mkdir -p "$d/src"; cat > "$d/src/alvo.cpp"
  printf '%s' "$cm" > "$d/CMakeLists.txt"
  local saida; saida="$(bash "$G" "$d" 2>&1)"; local rc=$?
  if [ "$rc" != "$esp" ]; then echo "  ✖ $nome: exit $rc, esperado $esp"; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); return; fi
  if [ -n "$agulha" ] && ! grep -qF -- "$agulha" <<<"$saida"; then echo "  ✖ $nome: exit certo, saída sem \"$agulha\""; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); return; fi
  echo "  ✔ $nome"; ok=$((ok+1))
}

echo "== verde de partida =="
caso verde 0 "no piso" <<'FIX'
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

class Repositorio {
public:
    void guardar(std::string item) {
        const std::scoped_lock trava{mutex_};
        itens_.push_back(std::move(item));
    }

private:
    std::mutex mutex_;
    std::vector<std::string> itens_;
};

int main() {
    auto repo = std::make_unique<Repositorio>();
    std::jthread trabalhador{[r = repo.get()] { r->guardar("ola"); }};
    return 0;
}
FIX

echo "== RAII =="
caso new-cru 1 "new\` cru" <<'FIX'
#include <string>
std::string* criar() { return new std::string("x"); }
FIX
caso lock-manual 1 "unlock\` não acontece" <<'FIX'
#include <mutex>
std::mutex m;
void trabalhar() {
    m.lock();
    fazer();
    m.unlock();
}
FIX

echo "== exceção =="
caso catch-tudo-vazio 1 "sem tipo não há tratamento" <<'FIX'
void salvar() {
    try { gravar(); } catch (...) {}
}
FIX

echo "== concorrência =="
caso volatile-thread 1 "não dá atomicidade" <<'FIX'
#include <thread>
volatile bool pronto = false;
void trabalhar() { pronto = true; }
FIX
caso thread-sem-join 1 "std::terminate" <<'FIX'
#include <thread>
void iniciar() {
    std::thread t{[] { trabalhar(); }};
}
FIX

echo "== legado de C =="
caso strcpy-em-cpp 1 "use \`std::string\`" <<'FIX'
#include <cstring>
void copiar(char* d, const char* o) { strcpy(d, o); }
FIX

echo "== o build =="
caso sem-sanitizer 1 "fsanitize=address" 'cmake_minimum_required(VERSION 3.20)
add_compile_options(-std=c++20 -Wall -Wextra -Werror)
' <<'FIX'
int main() { return 0; }
FIX
caso ubsan-que-continua 1 "IMPRIME e CONTINUA" 'cmake_minimum_required(VERSION 3.20)
add_compile_options(-std=c++20 -Wall -Wextra -Werror -fsanitize=address -fsanitize=undefined)
' <<'FIX'
int main() { return 0; }
FIX

echo "== nada para verificar =="
d="$TMP/vazio"; mkdir -p "$d"; echo "# prosa" > "$d/LEIA.md"
saida="$(bash "$G" "$d" 2>&1)"; rc=$?
if [ "$rc" = 2 ] && grep -q "não é aprovação" <<<"$saida"; then echo "  ✔ repo sem C++ sai 2 (não 0)"; ok=$((ok+1))
else echo "  ✖ repo sem C++: exit $rc"; fail=$((fail+1)); fi

echo; echo "check-cpp: $ok ok, $fail falha(s)"; [ "$fail" = 0 ]
