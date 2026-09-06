# Desenvolvimento

## Requisitos

- Flutter com Dart `3.13.2` ou superior;
- dependências resolvidas com `flutter pub get`;
- para o plugin, dependências resolvidas separadamente em
  `tools/odu_props_assist`.

## Validação obrigatória

Na raiz:

```bash
flutter analyze
flutter test
```

No plugin:

```bash
cd tools/odu_props_assist
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
[`tools/odu_props_assist/GENERATION.md`](../tools/odu_props_assist/GENERATION.md).
Ao adicionar uma ação:

1. crie um producer independente em `lib/src`;
2. registre-o em `tools/odu_props_assist/lib/main.dart`;
3. use elementos resolvidos do analyzer;
4. atualize métodos existentes em vez de duplicá-los;
5. não ofereça a ação quando não for possível gerar código válido;
6. adicione testes para construtores tradicionais e primários relevantes.

