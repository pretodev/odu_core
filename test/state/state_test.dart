import 'dart:async';

import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';

void main() {
  group('ViewModel', () {
    test('emits distinct states and notifies listeners', () {
      final viewModel = _StateViewModel(const _State(1));
      var calls = 0;
      viewModel.addListener(() => calls++);

      viewModel.update(const _State(2));

      expect(viewModel.state, const _State(2));
      expect(calls, 1);
    });

    test('does not notify for equivalent ViewModelState values', () {
      final viewModel = _StateViewModel(const _State(1));
      var calls = 0;
      viewModel.addListener(() => calls++);

      viewModel.update(const _State(1));
      viewModel.update(const _State(2));

      expect(viewModel.state, const _State(2));
      expect(calls, 1);
    });
  });

  group('Command', () {
    test('transitions from idle through running to success', () async {
      final completer = Completer<Result<int>>();
      final command = Command0(() => completer.future);
      final statuses = <CommandStatus<int>>[];
      command.addListener(() => statuses.add(command.status));

      final execution = command();
      expect(command.isWaiting, isTrue);
      expect(command.result, isNull);
      completer.complete(const Ok(2));
      await execution;

      expect(statuses, [isA<CommandRunning<int>>(), isA<CommandOk<int>>()]);
      expect(command.isDone, isTrue);
      expect(command.value, 2);
      expect(command.result?.unwrap(), 2);
    });

    test('retains failures and their stack traces', () async {
      const failure = _Failure('failed');
      final stackTrace = StackTrace.current;
      final command = Command0<int>(() async => Err(failure, stackTrace));

      await command();

      expect(command.isError, isTrue);
      expect(command.failure, same(failure));
      expect((command.status as CommandErr<int>).stackTrace, same(stackTrace));
      expect((command.result as Err<int>).stackTrace, same(stackTrace));
    });

    test('ignores reentrant execution and reset while running', () async {
      final completer = Completer<Result<int>>();
      var runs = 0;
      final command = Command0(() {
        runs++;
        return completer.future;
      });

      final first = command();
      await command();
      command.reset();

      expect(runs, 1);
      expect(command.isWaiting, isTrue);
      completer.complete(const Ok(1));
      await first;
      command.reset();
      expect(command.isIdle, isTrue);
    });

    test('returns to idle and rethrows unexpected exceptions', () async {
      final command = Command0<int>(() async => throw StateError('failed'));

      await expectLater(command(), throwsStateError);

      expect(command.isIdle, isTrue);
    });

    test(
      'passes arguments for commands with one, two, and three values',
      () async {
        final one = Command1<int, int>((value) async => Ok(value));
        final two = Command2<int, int, int>((a, b) async => Ok(a + b));
        final three = Command3<int, int, int, int>(
          (a, b, c) async => Ok(a + b + c),
        );

        await one(1);
        await two(1, 2);
        await three(1, 2, 3);

        expect(one.value, 1);
        expect(two.value, 3);
        expect(three.value, 6);
      },
    );
  });

  group('command bindings', () {
    test('bind synchronous and asynchronous functions', () async {
      Result<int> sync(int a, int b, int c) => Ok(a + b + c);
      FutureResult<int> async() async => const Ok(4);

      final syncCommand = sync.asAction();
      final asyncCommand = async.asAction();
      await syncCommand(1, 2, 3);
      await asyncCommand();

      expect(syncCommand.value, 6);
      expect(asyncCommand.value, 4);
    });
  });
}

final class _StateViewModel(super.state) extends ViewModel<_State> {
  void update(_State state) => emit(state);
}

final class const _State(final int count) extends ViewModelState {
  @override
  List<Object?> get props => [count];
}

final class const _Failure(super.failureReason) extends Failure {}
