part of 'view_model.dart';

sealed class const CommandStatus<T>();

/// A action ainda não foi executada (ou foi resetada via [Command.reset]).
final class const CommandIdle<T>() extends CommandStatus<T>;

/// A action está em execução.
final class const CommandRunning<T>() extends CommandStatus<T>;

/// A action terminou com sucesso, carregando [value].
final class const CommandOk<T>(final T value) extends CommandStatus<T>;

/// A action terminou com falha, carregando [failure].
final class const CommandErr<T>(
  final Failure failure, [
  final StackTrace? stackTrace,
]) extends CommandStatus<T>;

abstract class Command<T>() extends ChangeNotifier {
  CommandStatus<T> _status = const CommandIdle();

  /// Status atual da action.
  CommandStatus<T> get status => _status;

  bool get isIdle => _status is CommandIdle<T>;

  /// `true` enquanto a action está executando.
  bool get isWaiting => _status is CommandRunning<T>;

  /// `true` se a última execução terminou com sucesso.
  bool get isDone => _status is CommandOk<T>;

  /// `true` se a última execução terminou em falha.
  bool get isError => _status is CommandErr<T>;

  /// Valor do último sucesso, ou `null` se a action não está em [CommandOk].
  T? get value => switch (_status) {
    CommandOk(:final value) => value,
    _ => null,
  };

  /// Falha do último erro, ou `null` se a action não está em [CommandErr].
  Failure? get failure => switch (_status) {
    CommandErr(:final failure) => failure,
    _ => null,
  };

  /// O último [Result] concluído, ou `null` enquanto idle/running.
  Result<T>? get result => switch (_status) {
    CommandOk(:final value) => Ok(value),
    CommandErr(:final failure, :final stackTrace) => Err(failure, stackTrace),
    _ => null,
  };

  /// Volta a action para [CommandIdle].
  void reset() {
    if (isWaiting) {
      return;
    }
    _setStatus(const CommandIdle());
  }

  /// Executa o runner protegendo contra reentrância (chamadas enquanto
  /// [isWaiting] são ignoradas).
  Future<void> _execute(FutureResult<T> Function() run) async {
    if (isWaiting) {
      return;
    }
    _setStatus(const CommandRunning());
    try {
      final res = await run();
      _setStatus(switch (res) {
        Ok(value: final v) => CommandOk<T>(v),
        Err(failure: final f, stackTrace: final s) => CommandErr<T>(f, s),
      });
    } on Object {
      _setStatus(const CommandIdle());
      rethrow;
    }
  }

  void _setStatus(CommandStatus<T> next) {
    _status = next;
    notifyListeners();
  }
}

typedef Action0fn<T> = FutureResult<T> Function();

/// [Command] sem argumentos. Chamável: `action()`.
final class Command0<T>(final Action0fn<T> _fn) extends Command<T> {
  Future<void> call() => _execute(_fn);
}

typedef Action1fn<T, A> = FutureResult<T> Function(A arg);

/// [Command] com 1 argumento. Chamável: `action(arg)`.
final class Command1<T, A>(final Action1fn<T, A> _fn) extends Command<T> {
  Future<void> call(A arg) => _execute(() => _fn(arg));
}

typedef Action2fn<T, A, B> = FutureResult<T> Function(A a, B b);

/// [Command] com 2 argumentos posicionais. Chamável: `action(a, b)`.
final class Command2<T, A, B>(final Action2fn<T, A, B> _fn) extends Command<T> {
  Future<void> call(A a, B b) => _execute(() => _fn(a, b));
}

typedef Action3fn<T, A, B, C> = FutureResult<T> Function(A a, B b, C c);

/// [Command] com 3 argumentos posicionais. Chamável: `action(a, b, c)`.
final class Command3<T, A, B, C>(final Action3fn<T, A, B, C> _fn)
    extends Command<T> {
  Future<void> call(A a, B b, C c) => _execute(() => _fn(a, b, c));
}
