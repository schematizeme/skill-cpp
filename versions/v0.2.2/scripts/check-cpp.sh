#!/usr/bin/env bash
# schematize-cpp — o gate. Cobra o piso de `references/piso.md` sobre o C++ do repo.
#
# ALCANCE: textual + verificação do BUILD (quando há Makefile/CMake, ele confere se as flags e os
# sanitizers exigidos aparecem). Ele NÃO substitui rodar a suíte sanitizada — e diz isso.
#
# strict-ok: COLETOR — varre tudo e soma os achados (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail

raiz="${1:-.}"
erros=(); avisos=()

fontes=()
while IFS= read -r -d '' f; do fontes+=("$f"); done < <(
  find "$raiz" -type f \( -name '*.cpp' -o -name '*.cc' -o -name '*.cxx' -o -name '*.hpp' -o -name '*.hh' \) \
    -not -path '*/.git/*' -not -path '*/build/*' -not -path '*/vendor/*' \
    -not -path '*/third_party/*' -not -path '*/versions/*' -print0 2>/dev/null
)
builds=()
while IFS= read -r -d '' f; do builds+=("$f"); done < <(
  find "$raiz" -maxdepth 3 -type f \( -name 'CMakeLists.txt' -o -name 'Makefile' -o -name 'makefile' -o -name 'meson.build' \) \
    -not -path '*/.git/*' -print0 2>/dev/null
)

if [ "${#fontes[@]}" -eq 0 ]; then
  echo "✖ nenhum .cpp/.hpp em $raiz — nada para verificar (ausência de material não é aprovação)." >&2
  exit 2
fi

# ------------------------------------------------------------------ 1. o build
if [ "${#builds[@]}" -eq 0 ]; then
  avisos+=("sem Makefile/CMakeLists/meson no topo — não deu para conferir as flags do piso (piso.md secao 3)")
else
  todos="$(cat "${builds[@]}" 2>/dev/null)"
  grep -qE '\-Werror' <<< "$todos" \
    || erros+=("build sem \`-Werror\` — aviso que não quebra o build vira ruído em três semanas (piso.md secao 3)")
  grep -qE '\-Wall' <<< "$todos" || erros+=("build sem \`-Wall\`")
  grep -qE '\-Wextra' <<< "$todos" || avisos+=("build sem \`-Wextra\`")
  grep -qE '\-Wconversion' <<< "$todos" \
    || avisos+=("build sem \`-Wconversion\` — pega a conversão implícita silenciosa")
  grep -qE '\-Wold-style-cast' <<< "$todos" \
    || avisos+=("build sem \`-Wold-style-cast\` — é o que impede o cast em C voltar pela porta dos fundos")
  grep -qE '_GLIBCXX_ASSERTIONS|_LIBCPP_HARDENING' <<< "$todos" \
    || avisos+=("build sem \`-D_GLIBCXX_ASSERTIONS\` — liga a checagem de precondição da libstdc++ (custa pouco, pega muito)")
  grep -qE 'std=c\+\+(2[0-9]|1[7-9])' <<< "$todos" \
    || avisos+=("build sem \`-std=c++20\`+ explícito — nunca dependa do default do compilador")
  grep -qE 'fsanitize=address' <<< "$todos" \
    || erros+=("nenhum alvo com \`-fsanitize=address\` — a suíte tem de rodar sanitizada (piso.md secao 2)")
  grep -qE 'fsanitize=undefined' <<< "$todos" \
    || erros+=("nenhum alvo com \`-fsanitize=undefined\` — UB não estoura sozinho: ele funciona por dois anos e falha no dia errado")
  if grep -qE 'fsanitize=undefined' <<< "$todos" && ! grep -qE 'fno-sanitize-recover' <<< "$todos"; then
    erros+=("UBSan **sem** \`-fno-sanitize-recover=all\` — ele IMPRIME e CONTINUA, e o CI segue verde com o defeito no log (é o erro nº 1 de quem já usa UBSan)")
  fi
  if grep -qE '_FORTIFY_SOURCE' <<< "$todos" && ! grep -qE '\-O[123s]' <<< "$todos"; then
    avisos+=("\`_FORTIFY_SOURCE\` sem \`-O1\`+ — em \`-O0\` ele NÃO faz nada")
  fi
  grep -qE 'fsanitize=address' <<< "$todos" && grep -qE 'fsanitize=thread' <<< "$todos" \
    && grep -qE 'fsanitize=address.*fsanitize=thread|fsanitize=thread.*fsanitize=address' <<< "$todos" \
    && erros+=("ASan e TSan no MESMO alvo — eles não convivem; são dois jobs")
fi

# ------------------------------------------------------------------ 2. o código
for f in "${fontes[@]}"; do
  nome="${f#"$raiz"/}"
  # strings fora, depois comentário de linha (ordem importa)
  codigo="$(sed -e 's/"[^"]*"/""/g' -e "s/'[^']*'/''/g" -e 's|//.*$||' "$f")"

  # --- RAII e ponteiro cru
  grep -qE '(^|[^_a-zA-Z])new\s+[A-Za-z_]' <<< "$codigo" \
    && ! grep -qE 'cpp-ok:' "$f" \
    && erros+=("$nome: \`new\` cru — use \`make_unique\`/container/tipo RAII. \`delete\` que não roda por um \`return\` antecipado é vazamento; o que roda duas vezes é corrupção")
  grep -qE '(^|[^_a-zA-Z])delete\s+[A-Za-z_\[]' <<< "$codigo" \
    && ! grep -qE 'cpp-ok:' "$f" \
    && erros+=("$nome: \`delete\` cru — o destrutor é quem libera (RAII)")
  grep -qE '\.lock\(\)' <<< "$codigo" && ! grep -qE 'lock_guard|scoped_lock|unique_lock' "$f" \
    && erros+=("$nome: \`mutex.lock()\` manual sem guard — com exceção no meio, o \`unlock\` não acontece")

  # --- casts e UB
  grep -qE 'reinterpret_cast' <<< "$codigo" \
    && avisos+=("$nome: \`reinterpret_cast\` — type punning fora de \`bit_cast\`/\`memcpy\` viola strict aliasing, e o otimizador USA essa regra")
  grep -qE '\(\s*(int|char|float|double|long|unsigned|size_t)\s*\)\s*[A-Za-z_(]' <<< "$codigo" \
    && avisos+=("$nome: cast no estilo C — use \`static_cast\` (e ligue \`-Wold-style-cast\`)")

  # --- exceção
  grep -qE 'catch\s*\(\s*\.\.\.\s*\)\s*\{\s*\}' <<< "$codigo" \
    && erros+=("$nome: \`catch (...) { }\` vazio — erro engolido, e sem tipo não há tratamento possível")
  grep -qE 'catch\s*\(\s*[A-Za-z_:<>]+\s+[a-z]' <<< "$codigo" \
    && ! grep -qE 'catch\s*\(\s*const\s' <<< "$codigo" \
    && avisos+=("$nome: \`catch\` por VALOR — fatia o objeto (perde o tipo derivado); use \`catch (const X&)\`")

  # --- concorrência
  grep -qE '\bvolatile\b' <<< "$codigo" && grep -qE 'thread|mutex|atomic' "$f" \
    && ! grep -qE 'std::atomic' "$f" \
    && erros+=("$nome: \`volatile\` em contexto de thread — não dá atomicidade nem ordem; o certo é \`std::atomic\`")
  grep -qE 'std::thread\b' <<< "$codigo" && ! grep -qE 'join\(\)|detach\(\)|jthread' "$f" \
    && erros+=("$nome: \`std::thread\` sem \`join()\`/\`detach()\` — o destrutor chama \`std::terminate\`; prefira \`std::jthread\`")

  # --- legado de C dentro de C++
  grep -qE '(^|[^_a-zA-Z])(strcpy|strcat|sprintf|gets)\s*\(' <<< "$codigo" \
    && erros+=("$nome: função de string do C sem limite dentro de C++ — use \`std::string\`/\`std::format\`")
  grep -qE '(^|[^_a-zA-Z])(malloc|free)\s*\(' <<< "$codigo" \
    && avisos+=("$nome: \`malloc\`/\`free\` em C++ — misturar com destrutor é o caminho para double-free")
done

for a in "${avisos[@]:-}"; do [ -n "$a" ] && echo "  ! $a" >&2; done
if [ "${#erros[@]}" -gt 0 ]; then
  echo "" >&2
  echo "✖ C++ REPROVADO — ${#erros[@]} problema(s) em ${#fontes[@]} arquivo(s):" >&2
  for e in "${erros[@]}"; do echo "  · $e" >&2; done
  echo "  Lembre: UB não dá erro — ele AUTORIZA o compilador a assumir que aquilo não acontece." >&2
  exit 1
fi
echo "✔ c++: ${#fontes[@]} arquivo(s) e ${#builds[@]} build(s) no piso — e isto NÃO substitui rodar a suíte sanitizada."
