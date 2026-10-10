# Odu Core

Biblioteca Flutter com componentes pequenos para domínio, programação
funcional, leitura segura de JSON e gerenciamento de estado com
`ChangeNotifier`.

O pacote exige Dart `3.13.2` ou superior e utiliza recursos modernos da
linguagem, incluindo construtores primários e dot shorthand.

## Recursos

- igualdade por valor com suporte estrutural a listas, conjuntos e mapas;
- entidades identificadas por UUID;
- especificações de domínio combináveis com `and`, `or` e `not`;
- `Option`, `Result`, `FutureOption` e `FutureResult`;
- leitura tipada e imutável de payloads JSON dinâmicos;
- `ViewModel`, estados comparados por valor e comandos observáveis;
- ações de IDE para gerar `props`, `toString` e `copyWith`.

## Instalação

Adicione o pacote ao `pubspec.yaml` da aplicação:

```yaml
dependencies:
  odu_core:
    path: ../odu_core
```

Depois, importe a biblioteca pública:

```dart
import 'package:odu_core/odu_core.dart';
```

Arquivos em `lib/src` são detalhes de implementação. Consumidores devem usar
somente o entrypoint acima.

## Uso rápido

### Igualdade e entidades

```dart
class const User({
  required super.id,
  required final String name,
}) extends Entity {
  @override
  List<Object?> get props => .unmodifiable([id, name]);
}

final id = GuidId();
final first = User(id: id, name: 'Ada');
final second = User(id: id, name: 'Ada');

assert(first == second);
```

`Equatable` compara apenas instâncias do mesmo tipo e avalia coleções aninhadas
estruturalmente. Em uma `Entity`, inclua em `props` os valores que devem
participar da igualdade; a implementação base inclui `id`.

### Result e Option

```dart
final Option<String> nickname = Option.fromNullable(null);
final displayName = nickname.unwrapOr('Visitante');

final Result<int> parsed = const Ok(21);
final doubled = parsed.map((value) => value * 2);

switch (doubled) {
  case Ok(:final value):
    print(value);
  case Err(:final failure):
    print(failure.failureReason);
}
```

Use `Failure` para falhas esperadas e tratáveis. Exceções inesperadas devem
continuar subindo até o boundary global da aplicação.

### JSON

```dart
final data = DataJsonObject({
  'id': '42',
  'active': 'true',
  'roles': ['admin', 'editor'],
});

final id = data.integer('id');
final active = data.boolean('active');
final roles = data.list('roles', JsonParser.parseString);
```

Os métodos sem `OrNull` retornam valores padrão (`''`, `0`, `0.0`, `false` ou
coleção vazia). Os métodos `OrNull` preservam a ausência ou conversão inválida.
`dynamic` fica restrito à entrada do parser; o restante da API expõe `Object?`.

### ViewModel e comandos

```dart
class const CounterState(final int count) extends ViewModelState {
  @override
  List<Object?> get props => .unmodifiable([count]);
}

final class CounterViewModel extends ViewModel<CounterState> {
  CounterViewModel() : super(const CounterState(0));

  late final increment = _increment.asAction();

  Result<Unit> _increment() {
    emit(CounterState(state.count + 1));
    return ok;
  }
}
```

Um `ViewModel` não notifica os listeners quando o novo estado é igual ao
anterior. Um `Command` publica os estados `idle`, `running`, `ok` e `error`, e
ignora chamadas concorrentes enquanto estiver executando.

## Geradores no editor

O plugin local `tools/odu_core_lint/plugin` adiciona estas ações ao menu
`Ctrl+.`/`Cmd+.`:

- **Generate props**: gera ou atualiza o getter de igualdade;
- **Generate toString**: gera ou atualiza uma representação com campos
  rotulados;
- **Generate copyWith**: gera ou atualiza o método usando um construtor
  gerativo compatível.

O gerador reconhece campos de construtores tradicionais e primários do Dart
3.13, parâmetros nomeados, posicionais, herdados e construtores nomeados ou
privados. Reinicie o Dart Analysis Server após alterar ou instalar o plugin.

Detalhes: [documentação dos geradores](tools/odu_core_lint/README.md).

## Documentação

- [Guia da API](docs/api.md)
- [Arquitetura](docs/architecture.md)
- [Desenvolvimento e validação](docs/development.md)
- [Instruções para agentes](AGENTS.md)

## Desenvolvimento

```bash
flutter pub get
flutter analyze
flutter test

cd tools/odu_core_lint/plugin
dart pub get
dart analyze
dart test
```

Todo código deve passar por análise estática e testes antes de ser entregue.

## Analytics ao emitir estados

Configure uma vez na inicialização da aplicação:

```dart
final manager = AnalyticsManager([/* seus providers */]);
await manager.initialize();
ViewModel.defaultAnalytics = manager;
```

Todos os ViewModels passam a usar esse manager automaticamente. O parâmetro
`analytics: outroManager` continua disponível para sobrescrever o padrão em uma
instância. `ViewModel.defaultAnalytics = null` remove o padrão, sem descartar o
manager; seu ciclo de vida continua sob responsabilidade da aplicação.

Aplique o mixin apenas nos estados que devem gerar eventos. A base dos estados
deve estender `ViewModelState`:

```dart
sealed class const ProductSearchState() extends ViewModelState;

final class const ProductSearchLoading({required final String term})
    extends ProductSearchState with StateAnalyticsMixin {
  @override
  List<Object?> get props => [term];

  @override
  List<AnalyticsEvent> get analyticsEvents => [
    AnalyticsEvent(
      'product_search_loading',
      properties: {'term': term},
    ),
  ];
}
```

Estados sem o mixin continuam sendo emitidos normalmente, sem analytics.
Estados iguais e o estado inicial não geram eventos. Sem sobrescrever
`analyticsEvents`, o mixin gera um evento com o nome do tipo e sem propriedades.

Para personalizar apenas as propriedades do evento padrão, sobrescreva no estado:

```dart
@override
Map<String, Object?> get analyticsProperties => {
  'term': term,
  'source': 'product_search',
};
```

Nesse caso não é necessário sobrescrever `analyticsEvents`. Se sobrescrevê-lo,
configure as propriedades diretamente nos eventos retornados.

## Regras de análise e ferramentas de IDE

Use os dois pacotes separadamente (ajuste os caminhos para seu checkout):

```yaml
dependencies:
  odu_core:
    path: ../odu_core

dev_dependencies:
  odu_core_lint:
    path: ../odu_core/tools/odu_core_lint
```

No `analysis_options.yaml` do consumidor:

```yaml
include: package:odu_core_lint/analysis_options.yaml

plugins:
  odu_props_assist:
    path: ../odu_core/tools/odu_core_lint/plugin
```

`odu_core_lint` contém as regras, formatação e o subpacote do plugin com
**Generate props**, **Generate toString** e **Generate copyWith**. O plugin é
resolvido separadamente pelo Analysis Server; suas dependências de analyzer não
entram na aplicação. Reinicie o Dart Analysis Server após configurar o plugin.
Os pacotes de ferramentas ainda são locais (`publish_to: none`).
