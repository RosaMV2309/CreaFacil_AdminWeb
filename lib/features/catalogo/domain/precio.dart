/// Precio exacto de CreaFácil [RF-08].
///
/// La API envía y recibe los precios como **texto con dos decimales**
/// (`"0.75"`, `"12.50"`). Para no perder exactitud, aquí nunca se usa
/// `double`: el valor se guarda como un número entero de **céntimos** y se
/// convierte a texto con operaciones de enteros.
///
/// - [textoApi]: `"4.50"`, el formato que se envía al servidor.
/// - [formateado]: `"$ 4,50"` o `"$ 1.234,50"`, el formato que se muestra
///   (coma decimal y punto de miles, sin redondeos).
class Precio implements Comparable<Precio> {
  const Precio.centavos(this.centavos);

  /// Valor en céntimos (`4.50` → `450`).
  final int centavos;

  /// Máximo que admite el servidor: 99999.99.
  static const maximoCentavos = 9999999;

  /// Formato que admite el servidor: dígitos, punto decimal y como máximo
  /// dos decimales. No admite coma, signo ni exponente.
  static final formatoApi = RegExp(r'^\d+(\.\d{1,2})?$');

  static final _numeroDecimal = RegExp(r'^\d+(\.\d+)?$');

  /// Convierte un texto con [formatoApi] en céntimos. Devuelve `null` si el
  /// formato no es válido o si el número es demasiado largo.
  static Precio? intentar(String texto) {
    final limpio = texto.trim();
    if (!formatoApi.hasMatch(limpio)) {
      return null;
    }
    final partes = limpio.split('.');
    final entero = partes[0].replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (entero.length > 9) {
      return null;
    }
    final decimales = partes.length == 2 ? partes[1].padRight(2, '0') : '00';
    return Precio.centavos(int.parse(entero) * 100 + int.parse(decimales));
  }

  /// Lee el precio que envía la API (siempre texto). Lanza
  /// [FormatException] si no tiene el formato del contrato.
  static Precio desdeApi(Object? valor) {
    final precio = valor is String ? intentar(valor) : null;
    if (precio == null) {
      throw FormatException('Precio no válido: $valor');
    }
    return precio;
  }

  /// Valida lo que escribe la administradora con las mismas reglas que el
  /// servidor: mayor que 0, punto decimal, máximo 2 decimales y 99999.99.
  static String? validar(String? texto) {
    final valor = (texto ?? '').trim();
    if (valor.isEmpty) {
      return 'Escribe el precio unitario.';
    }
    if (valor.contains(',')) {
      return 'Usa el punto como separador decimal (por ejemplo, 4.50).';
    }
    if (!_numeroDecimal.hasMatch(valor)) {
      return 'Escribe un número válido, por ejemplo 4.50.';
    }
    if (!formatoApi.hasMatch(valor)) {
      return 'El precio admite como máximo 2 decimales.';
    }
    final precio = intentar(valor);
    if (precio == null || precio.centavos > maximoCentavos) {
      return 'El precio no puede superar 99999.99.';
    }
    if (precio.centavos <= 0) {
      return 'El precio debe ser mayor que 0.';
    }
    return null;
  }

  int get _entero => centavos ~/ 100;
  String get _decimales => (centavos % 100).toString().padLeft(2, '0');

  /// Texto para la API: `"4.50"`.
  String get textoApi => '$_entero.$_decimales';

  /// Texto para mostrar: `"$ 4,50"`, `"$ 1.234,50"`.
  String get formateado {
    final digitos = '$_entero';
    final miles = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) {
        miles.write('.');
      }
      miles.write(digitos[i]);
    }
    return '\$ $miles,$_decimales';
  }

  @override
  int compareTo(Precio otro) => centavos.compareTo(otro.centavos);

  @override
  bool operator ==(Object other) =>
      other is Precio && other.centavos == centavos;

  @override
  int get hashCode => centavos.hashCode;

  @override
  String toString() => textoApi;
}
