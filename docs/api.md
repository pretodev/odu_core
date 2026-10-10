# Guia da API

Este documento resume a API exportada por `package:odu_core/odu_core.dart`.
Consulte os Dartdocs no código para detalhes de cada operação.

## Domínio

### `GuidId`

Extension type sobre `String` para UUIDs válidos.

- `GuidId()` cria um UUID v4;
- `GuidId(value)` valida um UUID existente e lança `ArgumentError` se inválido;
- `GuidId.seeded(seed)` cria um UUID v5 determinístico.

### `Entity`

Base abstrata para entidades identificadas por `GuidId`. Estende `Equatable` e
inclui o identificador em `props`. Subclasses podem sobrescrever `props` para
adicionar valores à comparação.

### `Specification<T>`

Contrato para regras de negócio com `isSatisfiedBy`. As extensões `and`, `or` e
`not` criam especificações compostas e preservam curto-circuito lógico.

## Igualdade

### `Equatable`

Base imutável cuja igualdade e `hashCode` são derivados de `props`.

- exige o mesmo `runtimeType`;
- compara iteráveis em ordem;
- compara mapas e conjuntos estruturalmente, sem depender da ordem;
- calcula hashes coerentes para coleções aninhadas.

Objetos mutáveis não devem participar de `props`, pois alterações posteriores
podem invalidar o `hashCode` usado por mapas e conjuntos.

## Programação funcional

### `Option<T>`

Representa presença (`Some<T>`) ou ausência (`None<T>`) sem usar `null` como
estado implícito.

Operações principais: `map`, `flatMap`, `unwrap`, `unwrapOr`, `unwrapOrElse`,
`toNullable`, `isSome` e `isNone`.

### `Result<T>`

Representa sucesso (`Ok<T>`) ou falha esperada (`Err<T>`). `Err` carrega uma
subclasse de `Failure` e pode preservar o `StackTrace`.

Operações principais: `map`, `mapErr`, `flatMap`, `unwrap`, `unwrapOr` e
`unwrapOrElse`. O getter de extensão `.ok` transforma qualquer valor em
`Result<T>`. A constante `ok` representa `Ok<Unit>`.

`ResultList.zipAccumulate` reúne todos os sucessos ou todas as falhas. Sem um
agregador customizado, retorna `AccumulatedFailure`.

### Tipos assíncronos

`FutureOption<T>` e `FutureResult<T>` são aliases com extensões que espelham as
operações síncronas e incluem variantes assíncronas, inspeção, recuperação e
timeout.

- `FutureOptionList`: `waitAll`, `waitAllOrNone`, `any`, `collectSome`;
- `FutureResultList.zipAccumulate`: aguarda os resultados e acumula falhas;
- `FutureOptionFactory` e `FutureResultFactory`: criam futures já concluídos.

## JSON

### `JsonParser`

Boundary de conversão para dados não tipados. Aceita `dynamic` deliberadamente
e converte para strings, inteiros, doubles, booleanos, datas, listas ou mapas.
Coleções retornadas são não modificáveis.

### `DataJsonObject` e `DataJsonList`

Extension types para navegar objetos e arrays JSON por chave ou índice.
Disponibilizam versões com fallback e versões anuláveis, além de leitura de
estruturas aninhadas.

### `JsonSerializable`

Contrato mínimo com `Map<String, Object?> toJson()`.

## Estado

### `ViewModelState`

Base imutável para estados comparados por valor. Subclasses implementam
`props`.

### `ViewModel<T>`

`ChangeNotifier` que expõe `state` e o método protegido `emit`. Emissões iguais
ao estado atual não notificam listeners.

### `Command<T>`

Encapsula uma ação síncrona ou assíncrona que retorna `Result<T>` e publica um
`CommandStatus<T>`:

- `CommandIdle` antes da execução ou após `reset`;
- `CommandRunning` durante a execução;
- `CommandOk` com o valor concluído;
- `CommandErr` com `Failure` e `StackTrace` opcional.

Há implementações `Command0` a `Command3`. A extensão `asAction()` converte
funções compatíveis nesses comandos. Chamadas feitas enquanto `isWaiting` são
ignoradas; erros inesperados restauram o estado idle e são relançados.

## Analytics de estados

Configure `ViewModel.defaultAnalytics = manager` uma vez na inicialização da
aplicação. O parâmetro opcional `analytics` do construtor sobrescreve esse padrão
por instância. Quando ele é nulo, cada emissão consulta o padrão atual, inclusive
em ViewModels já existentes. Atribuir `null` ao padrão desabilita esse fallback;
um manager explícito continua ativo. Para desabilitar analytics em uma instância,
passe `AnalyticsManager([])` explicitamente.

O dono do manager deve inicializá-lo e descartá-lo; o view model não controla
seu ciclo de vida. Trocar ou limpar o padrão não descarta managers nem cancela
eventos pendentes. Testes que alteram o padrão devem restaurá-lo no teardown.
Sem manager explícito ou padrão, o view model funciona normalmente.

`StateAnalyticsMixin on ViewModelState` habilita eventos para um estado.
Seu getter `analyticsEvents` permite criar vários eventos ou retornar uma lista
vazia. O padrão é um evento com o nome do tipo e sem propriedades; sobrescreva
com nomes estáveis para builds com ofuscação. `props` nunca é enviado
automaticamente e continua sendo usado apenas para igualdade.

`emit` envia eventos somente para estados distintos com o mixin. O estado
inicial não gera eventos. Estados sem mixin continuam atualizando o estado e
notificando listeners. Os eventos são criados antes da atualização, e enviados
após a notificação, sem aguardar providers. A criação dos eventos deve ser pura;
erros nessa criação são propagados. Falhas de providers são registradas pelo
manager e não interrompem os demais providers.

`AnalyticsEvent(name, properties: ..., hiddenProperties: {...})` remove as
chaves indicadas antes de armazenar o payload em um mapa não modificável.
A filtragem vale para chaves do primeiro nível: para ocultar dados aninhados,
remova a propriedade que os contém. Valores aninhados devem ser imutáveis.
A ocultação não altera o estado original nem sua igualdade e não se aplica ao
nome do evento ou ao identificador passado para `identify`.
