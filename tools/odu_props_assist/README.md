# Odu Props Assist

Plugin local do Analysis Server que adiciona as ações **Generate props**,
**Generate toString** e **Generate copyWith** ao menu de ações rápidas do editor
(`Ctrl+.` / `Cmd+.`).

## Ações

### Generate props

Aparece dentro de classes que estendem `Equatable`, `Entity` ou
`ViewModelState`. Campos estáticos e sintéticos são ignorados. Se a classe já
possuir um getter `props`, ele será atualizado.

### Generate toString

Aparece dentro de classes resolvidas. Usa os campos de instância declarados e
gera uma representação rotulada, por exemplo:

```dart
@override
String toString() => 'User(id: $id, name: $name)';
```

### Generate copyWith

Aparece somente em classes concretas que tenham um construtor gerativo cujos
parâmetros possam ser lidos da própria instância. A prioridade é:

1. construtor primário;
2. construtor sem nome;
3. único construtor gerativo disponível.

O resultado preserva parâmetros nomeados e posicionais e usa dot shorthand:

```dart
User copyWith({GuidId? id, String? name}) =>
    .new(id: id ?? this.id, name: name ?? this.name);
```

Como a API gerada usa `??` para indicar “manter o valor atual”, ela não permite
trocar uma propriedade anulável para `null`. Para esse caso, ajuste manualmente
a assinatura conforme a semântica do modelo.

As três ações atualizam membros existentes em vez de gerar duplicatas.

O código gerado tem Dart 3.13.2 como versão mínima, reconhece todas as formas de
construtores primários e usa dot shorthand quando existe tipo contextual.

Após instalar ou alterar o plugin, reinicie o Dart Analysis Server pela paleta
de comandos do editor.

## Desenvolvimento

```bash
dart pub get
dart analyze
dart test
```

As regras para agentes e novos geradores estão em [GENERATION.md](GENERATION.md)
e no [`AGENTS.md`](../../AGENTS.md) da raiz.
