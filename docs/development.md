# Desenvolvimento

## Requisitos

- Flutter com Dart `3.13.2` ou superior;
- dependências resolvidas com `flutter pub get`;
- para o plugin, dependências resolvidas separadamente em
  `tools/odu_core_lint/plugin`.

## Validação obrigatória

Na raiz:

```bash
flutter analyze
flutter test
```

No plugin:

```bash
cd tools/odu_core_lint/plugin
dart analyze
dart test
```

Execute `dart format` nos arquivos Dart alterados. Não suprima problemas com
comentários `// ignore:`; corrija a causa ou ajuste a configuração somente com
justificativa de projeto.

## Organização de testes

Os testes espelham os módulos de `lib/src`:

```text
test/domain
test/equality
test/fp
test/json
test/state
```

Mudanças de comportamento precisam de um teste de regressão no módulo
correspondente. Mudanças nos geradores devem cobrir o código produzido e as
formas sintáticas do Dart 3.13 consumidas pela ação.

## Checklist de mudança

1. Confirme se a alteração pertence à API pública ou à implementação interna.
2. Preserve compatibilidade com Dart 3.13.2 e as regras de
   `analysis_options.yaml`.
3. Atualize exports apenas quando houver uma nova API pública.
4. Adicione ou ajuste testes.
5. Atualize README, documentação de módulo e changelog quando houver mudança
   observável para consumidores.
6. Rode análise e testes da raiz e, quando aplicável, do plugin.

## Geradores

As convenções específicas estão em
[`tools/odu_core_lint/plugin/GENERATION.md`](../tools/odu_core_lint/plugin/GENERATION.md).
Ao adicionar uma ação:

1. crie um producer independente em `lib/src`;
2. registre-o em `tools/odu_core_lint/plugin/lib/main.dart`;
3. use elementos resolvidos do analyzer;
4. atualize métodos existentes em vez de duplicá-los;
5. não ofereça a ação quando não for possível gerar código válido;
6. adicione testes para construtores tradicionais e primários relevantes.


## Configuração compartilhada de análise

As regras ficam em `tools/odu_core_lint/lib/analysis_options.yaml`, acessíveis
por `include: package:odu_core_lint/analysis_options.yaml`. O pacote é uma
dependência de desenvolvimento. O plugin incluído em `tools/odu_core_lint/plugin`
é um pacote separado, resolvido pelo Analysis Server, evitando conflitos entre
as dependências do analyzer e as do Flutter. Valide o plugin com `dart analyze`
e `dart test` nesse diretório. `lints` não é dependência de runtime de `odu_core`.
