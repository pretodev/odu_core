import 'package:uuid/uuid.dart';

/// Identificador de entidade baseado em UUID (RFC 4122).
extension type const GuidId._(String value) implements String {
  factory([String value = '']) {
    if (value.isEmpty) {
      return GuidId._(const Uuid().v4());
    }
    if (!Uuid.isValidUUID(fromString: value)) {
      throw ArgumentError.value(
        value,
        'value',
        'GuidId deve ser um UUID válido',
      );
    }
    return GuidId._(value);
  }

  /// Gera um id estável e determinístico a partir de [seed]: o mesmo seed
  /// sempre produz o mesmo id (UUID v5). Útil para entidades cuja identidade
  /// deriva de uma chave de negócio fixa (ex.: o `name` de um provedor).
  factory seeded(String seed) =>
      GuidId._(const Uuid().v5(Namespace.url.value, seed));
}
