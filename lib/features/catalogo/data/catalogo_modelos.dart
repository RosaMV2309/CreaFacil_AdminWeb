import '../domain/entidades_catalogo.dart';
import '../domain/precio.dart';
import '../domain/servicios.dart';

/// Conversión del JSON de la API del catálogo (subfase 2.1 del backend).
/// Cualquier forma inesperada lanza [FormatException].
abstract final class CatalogoModelos {
  static Categoria categoria(Object? json) {
    final m = _mapa(json);
    return Categoria(
      id: _texto(m, 'id'),
      nombre: _texto(m, 'nombre'),
      descripcion: _textoOpcional(m, 'descripcion'),
      activa: _booleano(m, 'activa'),
      orden: _entero(m, 'orden'),
      serviciosActivos: _entero(m, 'serviciosActivos'),
      serviciosTotales: _entero(m, 'serviciosTotales'),
      creadoEn: _fecha(m, 'creadoEn'),
      actualizadoEn: _fecha(m, 'actualizadoEn'),
    );
  }

  static MaterialCatalogo material(Object? json) {
    final m = _mapa(json);
    return MaterialCatalogo(
      id: _texto(m, 'id'),
      nombre: _texto(m, 'nombre'),
      descripcion: _textoOpcional(m, 'descripcion'),
      unidad: _texto(m, 'unidad'),
      // Siempre texto con 2 decimales ("0.75"): nunca double.
      precioUnitario: Precio.desdeApi(m['precioUnitario']),
      activo: _booleano(m, 'activo'),
      creadoEn: _fecha(m, 'creadoEn'),
      actualizadoEn: _fecha(m, 'actualizadoEn'),
    );
  }

  static FotoServicio foto(Object? json) {
    final m = _mapa(json);
    return FotoServicio(
      id: _texto(m, 'id'),
      url: _texto(m, 'url'),
      orden: _entero(m, 'orden'),
    );
  }

  /// `{fotos: [...]}` → fotos ordenadas (la primera es la portada).
  static List<FotoServicio> fotos(Object? cuerpo) {
    final lista = _mapa(cuerpo)['fotos'];
    if (lista is! List) {
      throw const FormatException('Falta la lista de fotos');
    }
    return [for (final f in lista) foto(f)]
      ..sort((a, b) => a.orden.compareTo(b.orden));
  }

  static ServicioResumen servicioResumen(Object? json) => _servicio(json);

  static ServicioDetalle servicioDetalle(Object? json) =>
      _servicio(json, detalle: true);

  static ServicioDetalle _servicio(Object? json, {bool detalle = false}) {
    final m = _mapa(json);
    final c = _mapa(m['categoria']);
    final precio = m['precioBaseReferencial'];
    final materiales = detalle ? m['materiales'] : const <Object?>[];
    if (materiales is! List) {
      throw const FormatException('Falta la lista de materiales');
    }
    return ServicioDetalle(
      id: _texto(m, 'id'),
      nombre: _texto(m, 'nombre'),
      categoria: CategoriaDeServicio(
        id: _texto(c, 'id'),
        nombre: _texto(c, 'nombre'),
        activa: _booleano(c, 'activa'),
      ),
      activo: _booleano(m, 'activo'),
      // Texto con 2 decimales ("120.50") o null; nunca double.
      precioBaseReferencial: precio == null ? null : Precio.desdeApi(precio),
      portadaUrl: _textoOpcional(m, 'portadaUrl'),
      numeroFotos: _entero(m, 'numeroFotos'),
      creadoEn: _fecha(m, 'creadoEn'),
      actualizadoEn: _fecha(m, 'actualizadoEn'),
      descripcion: detalle ? _textoOpcional(m, 'descripcion') : null,
      dimensionesOrientativas: detalle
          ? _textoOpcional(m, 'dimensionesOrientativas')
          : null,
      observaciones: detalle ? _textoOpcional(m, 'observaciones') : null,
      materiales: [
        for (final e in materiales)
          () {
            final mat = _mapa(e);
            return MaterialDeServicio(
              id: _texto(mat, 'id'),
              nombre: _texto(mat, 'nombre'),
              unidad: _texto(mat, 'unidad'),
              activo: _booleano(mat, 'activo'),
            );
          }(),
      ],
      fotos: detalle ? fotos(m) : const [],
    );
  }

  /// `{datos: [...]}` → lista convertida con [convertir].
  static List<T> lista<T>(Object? cuerpo, T Function(Object?) convertir) {
    final datos = _mapa(cuerpo)['datos'];
    if (datos is! List) {
      throw const FormatException('Falta la lista de datos');
    }
    return [for (final e in datos) convertir(e)];
  }

  /// `{datos: [...], paginacion: {...}}` → [Paginado].
  static Paginado<T> paginado<T>(
    Object? cuerpo,
    T Function(Object?) convertir,
  ) {
    final p = _mapa(_mapa(cuerpo)['paginacion']);
    return Paginado(
      datos: lista(cuerpo, convertir),
      pagina: _entero(p, 'pagina'),
      porPagina: _entero(p, 'porPagina'),
      total: _entero(p, 'total'),
      totalPaginas: _entero(p, 'totalPaginas'),
    );
  }

  /// Lee la clave [clave] de un cuerpo `{clave: {...}}`.
  static Object? campo(Object? cuerpo, String clave) => _mapa(cuerpo)[clave];

  static Map<String, Object?> _mapa(Object? json) {
    if (json is Map) {
      return json.cast<String, Object?>();
    }
    throw const FormatException('Se esperaba un objeto JSON');
  }

  static String _texto(Map<String, Object?> m, String clave) {
    final valor = m[clave];
    if (valor is String) {
      return valor;
    }
    throw FormatException('Falta el texto $clave');
  }

  static String? _textoOpcional(Map<String, Object?> m, String clave) {
    final valor = m[clave];
    if (valor == null || valor is String) {
      return valor as String?;
    }
    throw FormatException('$clave no es texto');
  }

  static int _entero(Map<String, Object?> m, String clave) {
    final valor = m[clave];
    if (valor is int) {
      return valor;
    }
    throw FormatException('Falta el número $clave');
  }

  static bool _booleano(Map<String, Object?> m, String clave) {
    final valor = m[clave];
    if (valor is bool) {
      return valor;
    }
    throw FormatException('Falta el valor $clave');
  }

  static DateTime _fecha(Map<String, Object?> m, String clave) =>
      DateTime.parse(_texto(m, clave));
}
