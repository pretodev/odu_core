# Arquitetura

## Superfície pública

`lib/odu_core.dart` é o único entrypoint público. Ele exporta cinco módulos:

| Módulo | Diretório | Responsabilidade |
| --- | --- | --- |
| Domain | `lib/src/domain` | identidade e regras de negócio |
| Equality | `lib/src/equality` | igualdade e hash por valor |
| FP | `lib/src/fp` | ausência, falhas e composição funcional |
| JSON | `lib/src/json` | conversão de payloads não tipados |
| State | `lib/src/state` | estado observável e execução de comandos |

Novas APIs destinadas aos consumidores devem ser exportadas pelo barrel do
módulo e, depois, por `lib/odu_core.dart`. Não exporte arquivos internos sem uma
decisão explícita de API.

## Dependências entre módulos

```text
domain ──────> equality
state ───────> equality + fp + Flutter foundation
json ────────> sem dependência dos demais módulos
fp ──────────> sem dependência dos demais módulos
equality ────> Flutter foundation
```

O pacote depende externamente de Flutter, `uuid` e `collection`. A igualdade é
implementada localmente; não existe dependência de `equatable`.

## Decisões importantes

### Dart 3.13

O SDK mínimo é `3.13.2`. Código novo pode usar construtores primários, declaring
parameters, super parameters e dot shorthand. Os geradores precisam entender
todas essas formas por meio do modelo resolvido do analyzer, sem interpretar
texto-fonte manualmente.

### Imutabilidade

Estados, resultados e valores de domínio favorecem classes `const`, `final` ou
`sealed`. Coleções expostas pelos leitores JSON são não modificáveis. Dados em
`Equatable.props` devem permanecer estáveis durante a vida do objeto.

### Erros esperados e inesperados

Falhas de domínio conhecidas usam `Failure` dentro de `Result`. Bugs e exceções
inesperadas não devem ser convertidos silenciosamente em `Failure`; eles sobem
para o boundary global.

### JSON como boundary dinâmico

`dynamic` é permitido no `JsonParser`, onde dados externos entram no sistema.
Após essa fronteira, prefira `Object?` e tipos concretos.

## Plugin de geração

`tools/odu_props_assist` é um pacote Dart separado carregado pelo Analysis
Server através de `analysis_options.yaml`. Cada ação é um
`ResolvedCorrectionProducer` independente e compartilha a descoberta de campos
em `class_fields.dart`.

O plugin não faz parte da API em runtime do `odu_core` e possui sua própria
análise, dependências e suíte de testes.

