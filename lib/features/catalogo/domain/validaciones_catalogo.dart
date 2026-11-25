/// Validaciones del catálogo en el cliente, iguales a las del servidor
/// (subfase 2.1). El servidor vuelve a validar siempre [RF-22].
abstract final class ValidacionesCatalogo {
  static const nombreMin = 2;
  static const nombreMax = 80;
  static const descripcionMax = 500;
  static const ordenMax = 9999;
  static const unidadMax = 30;

  /// Quita los espacios de los extremos y deja uno solo entre palabras,
  /// como hace el servidor.
  static String normalizar(String? texto) =>
      (texto ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Texto opcional: `null` si queda vacío.
  static String? opcional(String? texto) {
    final limpio = (texto ?? '').trim();
    return limpio.isEmpty ? null : limpio;
  }

  static String? nombre(String? valor) {
    final texto = normalizar(valor);
    if (texto.isEmpty) {
      return 'Escribe el nombre.';
    }
    if (texto.length < nombreMin) {
      return 'El nombre debe tener al menos $nombreMin caracteres.';
    }
    if (texto.length > nombreMax) {
      return 'El nombre admite como máximo $nombreMax caracteres.';
    }
    return null;
  }

  static String? descripcion(String? valor) =>
      (valor ?? '').trim().length > descripcionMax
      ? 'La descripción admite como máximo $descripcionMax caracteres.'
      : null;

  /// Orden opcional (por defecto 0): entero entre 0 y 9999.
  static String? orden(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return null;
    }
    if (!RegExp(r'^\d+$').hasMatch(texto)) {
      return 'El orden debe ser un número entero.';
    }
    if (texto.length > 4 || int.parse(texto) > ordenMax) {
      return 'El orden debe estar entre 0 y $ordenMax.';
    }
    return null;
  }

  static int ordenDe(String? valor) => int.tryParse((valor ?? '').trim()) ?? 0;

  static String? unidad(String? valor) {
    final texto = normalizar(valor);
    if (texto.isEmpty) {
      return 'Escribe la unidad (por ejemplo, metro, litro o unidad).';
    }
    if (texto.length > unidadMax) {
      return 'La unidad admite como máximo $unidadMax caracteres.';
    }
    return null;
  }
}
