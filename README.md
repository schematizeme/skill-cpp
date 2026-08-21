# schematize-cpp

> **Skill defensiva.** Ela não abre a porta do C++: **componente novo de sistema nasce em Rust ou
> Zig**, e C++ entra por **ADR de exceção**. Ela existe para que o C++ que a casa mantém (ou
> herda) **não vire vulnerabilidade** — com o piso sendo **ferramenta, não disciplina**.

Pacote de **skill normativa para [Claude Code](https://claude.com/claude-code)**.
Parte do catálogo **schematize skills**.

## Instalar

```bash
schematize install cpp
# ou
git clone https://github.com/schematizeme/skill-cpp.git /tmp/skill-cpp
bash /tmp/skill-cpp/install.sh .
```

## O que tem dentro

- **SKILL.md** — o contrato: 10 pisos inegociáveis + mapa de references.
- **references/** — `escopo` (onde C++ entra e por que **não** é escolha de fit),
  `piso` (sanitizers, flags, memória, retorno, fuzzing, concorrência), `stack-versoes`
  (ferramental **verificado rodando** nesta máquina).
- **scripts/** — `check-cpp.sh` (o gate: lê **o código e o build**) e `check-cpp.test.sh`
  (10 casos, 8 vermelhos).
- **assets/commands/** — `/cpp-help`, `/cpp-load`, `/cpp-review`, `/cpp-claude`, `/cpp-cc`,
  `/cpp-handoff`.
- **assets/CLAUDE.md** — regra sempre-on.

## Versão

**v0.1.0** — changelog em `CHANGELOG.md`.

## Regra de ouro

**UB não dá erro — ele autoriza o compilador a assumir que aquilo não acontece.** É por isso que o
piso é sanitizer no CI, e não boa vontade na revisão.

MIT.
