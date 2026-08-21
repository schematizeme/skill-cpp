# Onde C++ entra — e por que ele NÃO é escolha de fit

> Parte da skill **schematize-cpp**. Como a `schematize-c`, esta skill é **defensiva**.

---

## 1. A regra

**Componente novo de sistema nasce em Rust ou Zig.** C++ entra por **ADR de exceção**, não por fit.

O motivo não é gosto: o nicho (controle de memória, desempenho previsível, interop nativa) **já está
coberto** por duas linguagens do rol que entregam o mesmo **com verificação** — Rust com garantia em
compilação, Zig com controle explícito e sem as camadas de UB herdadas.

## 2. Quando o ADR de exceção é legítimo

- **Ecossistema que só existe em C++:** engine gráfica, CAD, simulação numérica, biblioteca de
  visão/áudio, SDK de fabricante.
- **Base existente grande** que a casa mantém (não se reescreve por decreto).
- **Interop pesada com API C++** (não apenas C ABI) — o wrapper em outra linguagem custaria mais que
  o módulo.
- **Plataforma/certificação** que exige um toolchain C++ específico.

O ADR registra: **por que não Rust/Zig**, **qual é a superfície**, **quem mantém**, **qual padrão**
(C++20/23) e **como se sai**.

## 3. C++ que já existe: mantém-se, com o piso ligado

Fica como está até ser tocado; o que for tocado passa a cumprir `piso.md` — e a prioridade de
saneamento é sempre a mesma ordem: **sanitizers no CI** → `-Werror` → eliminar `new`/`delete` cru do
que se toca → fuzzing do parser.

**Modernizar tem um limite honesto:** trocar `new`/`delete` por `unique_ptr` num módulo maduro é
barato e paga; reescrever a hierarquia de classes inteira "para ficar moderno" troca bugs conhecidos
por bugs novos.

## 4. O que esta skill NÃO é

- **Não é porta para "backend em C++"**: serviço novo nasce no rol.
- **Não é curso de C++.** É o piso para que o C++ que a casa toca não vire vulnerabilidade nem
  armadilha de manutenção.
- **Não cobre C.** Ver `schematize-c` — e **C++ não é "C com classes"**: escrever C++ com a
  mentalidade de C junta os riscos de um com a complexidade do outro, e é exatamente o modo mais
  caro de usar as duas linguagens.
