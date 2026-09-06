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

O plugin local `tools/odu_props_assist` adiciona estas ações ao menu
`Ctrl+.`/`Cmd+.`:

- **Generate props**: gera ou atualiza o getter de igualdade;
- **Generate toString**: gera ou atualiza uma representação com campos
  rotulados;
- **Generate copyWith**: gera ou atualiza o método usando um construtor
  gerativo compatível.

O gerador reconhece campos de construtores tradicionais e primários do Dart
3.13, parâmetros nomeados, posicionais, herdados e construtores nomeados ou
privados. Reinicie o Dart Analysis Server após alterar ou instalar o plugin.

Detalhes: [documentação dos geradores](tools/odu_props_assist/README.md).

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

cd tools/odu_props_assist
dart pub get
dart analyze
dart test
```

Todo código deve passar por análise estática e testes antes de ser entregue.
