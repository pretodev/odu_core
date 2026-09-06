# AGENTS.md

Instruções canônicas para agentes que trabalham neste repositório.

## Objetivo do projeto

`odu_core` é um pacote Flutter de infraestrutura compartilhada. A API pública
inclui domínio, igualdade, tipos funcionais, JSON e estado. O plugin em
`tools/odu_props_assist` fornece assists do Analysis Server e é um pacote Dart
separado.

Leia antes de alterar código:

- `README.md` para uso do pacote;
- `docs/architecture.md` para limites e dependências;
- `docs/api.md` para o comportamento público;
- `docs/development.md` para validação;
- `tools/odu_props_assist/GENERATION.md` ao alterar geradores.

## Restrições

- SDK mínimo: Dart `3.13.2`.
- O projeto é Flutter, não Dart puro.
- Use `package:odu_core/odu_core.dart` como API pública para consumidores.
- Preserve `dynamic` apenas no boundary de parsing JSON.
- Não adicione `equatable`; a implementação local fica em
  `lib/src/equality`.
- Não use comentários `// ignore:`.
- Não edite arquivos gerados.
- Não quebre igualdade/hash com propriedades mutáveis.
- Falhas esperadas usam `Failure`/`Result`; exceções inesperadas são relançadas.

## Convenções

- Prefira tipos imutáveis, `const`, classes `final`/`sealed` e pattern matching.
- Use construtores primários, declaring parameters, super parameters e dot
  shorthand quando melhorarem o código.
- Imports internos seguem o formato `package:odu_core/...`.
- Toda API pública nova precisa de Dartdoc, export correto e teste.
- Preserve mudanças do usuário não relacionadas à tarefa.

## Comandos de conclusão

Para alterações na biblioteca:

```bash
flutter analyze
flutter test
```

Para alterações em `tools/odu_props_assist`:

```bash
cd tools/odu_props_assist
dart analyze
dart test
```

Uma tarefa não está concluída enquanto os comandos aplicáveis falharem. Relate
claramente qualquer validação que não pôde ser executada.

## Mapa rápido

```text
lib/odu_core.dart                 entrypoint público
lib/src/domain                    Entity, GuidId, Specification
lib/src/equality                  Equatable local
lib/src/fp                        Option, Result e variantes assíncronas
lib/src/json                      parser e leitores tipados
lib/src/state                     ViewModel e Command
test                              testes da biblioteca
tools/odu_props_assist            plugin e testes próprios
```

