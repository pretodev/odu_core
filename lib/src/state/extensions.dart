part of 'view_model.dart';

extension Action0Binding<T> on FutureResult<T> Function() {
  Command0<T> asAction() => Command0<T>(this);
}

extension Action1Binding<T, A> on Action1fn<T, A> {
  Command1<T, A> asAction() => Command1<T, A>(this);
}

extension Action2Binding<T, A, B> on Action2fn<T, A, B> {
  Command2<T, A, B> asAction() => Command2<T, A, B>(this);
}

extension Action3Binding<T, A, B, C> on Action3fn<T, A, B, C> {
  Command3<T, A, B, C> asAction() => Command3<T, A, B, C>(this);
}

extension SyncAction0Binding<T> on Result<T> Function() {
  Command0<T> asAction() => Command0<T>(() async => this());
}

extension SyncAction1Binding<T, A> on Result<T> Function(A) {
  Command1<T, A> asAction() => Command1<T, A>((a) async => this(a));
}

extension SyncAction2Binding<T, A, B> on Result<T> Function(A, B) {
  Command2<T, A, B> asAction() => Command2<T, A, B>((a, b) async => this(a, b));
}

extension SyncAction3Binding<T, A, B, C> on Result<T> Function(A, B, C) {
  Command3<T, A, B, C> asAction() =>
      Command3<T, A, B, C>((a, b, c) async => this(a, b, c));
}
