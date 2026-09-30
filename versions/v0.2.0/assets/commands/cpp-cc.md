---
description: schematize-cpp — context compact: grava o handoff no archive e roda /compact.
---
Antes de compactar, grave o handoff em `<projeto>/<projeto>_archive/context/`, no par
context + checklist do padrão da `schematize-archive` (prefixo `AAAA-MM-DD-<slug>-`): o que foi
escrito/revisado, o que o `check-cpp.sh` acusou e ficou aberto, o que ficou com `new`/`delete` cru
**e por quê**, a política de exceção do módulo, o estado do fuzzing, e o **ADR de exceção** que
justifica o C++ existir aqui. Só então rode `/compact`.
