part of 'fp.dart';

/// Classe base para todas as falhas conhecidas do app.
///
/// Toda falha **prevista** e **tratada** deve estender [Failure].
///
/// Erros inesperados (bugs, null dereferences, etc.) **NÃO** devem ser
/// modelados como [Failure] — eles devem borbulhar naturalmente e serem
/// capturados pelo boundary global (ex: Crashlytics).
///
/// [Failure] carrega duas perspectivas:
/// - [failureReason]: texto amigável exibido na UI para o usuário final.
/// - [debugDetails]: informações técnicas para o desenvolvedor/logs (nunca
///   exibidas na UI).
abstract class const Failure(
  final String failureReason, {
  final String? debugDetails,
  final StackTrace? stackTrace,
}) {
  @override
  String toString() =>
      '$runtimeType: $failureReason'
      '${debugDetails != null ? ' | $debugDetails' : ''}';
}
