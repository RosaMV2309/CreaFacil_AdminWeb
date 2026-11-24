import '../../../core/network/red.dart';
import '../domain/entidades_catalogo.dart';
import 'catalogo_modelos.dart';

/// Error si el servidor responde con una forma distinta a la del contrato.
const respuestaInvalidaCatalogo = ApiException(
  tipo: TipoErrorApi.desconocido,
  codigo: 'RESPUESTA_INVALIDA',
  mensaje:
      'El servidor envió una respuesta inesperada. Inténtalo de nuevo más '
      'tarde.',
);

T _leer<T>(T Function() conversion) {
  try {
    return conversion();
  } on FormatException {
    throw respuestaInvalidaCatalogo;
  }
}

/// Categorías contra `/admin/categorias` (Bearer de ADMIN) [RF-22][RF-05].
///
/// Errores (como [ApiException]): 400 VALIDACION con detalles por campo,
/// 404 «La categoría no existe.» y 409 «Ya existe una categoría con ese
/// nombre.». No hay DELETE: solo se desactiva con `activa: false`.
class CategoriasRepositoryImpl implements CategoriasRepository {
  CategoriasRepositoryImpl(this._api);

  final ApiClient _api;

  static const ruta = '/admin/categorias';

  @override
  Future<List<Categoria>> listar({String q = '', bool? activa}) async {
    final r = await _api.get(
      ruta,
      consulta: {
        if (q.trim().isNotEmpty) 'q': q.trim(),
        if (activa != null) 'activa': '$activa',
      },
    );
    return _leer(
      () => CatalogoModelos.lista(r.data, CatalogoModelos.categoria),
    );
  }

  @override
  Future<Categoria> crear(DatosCategoria datos) async {
    final r = await _api.post(ruta, datos: datos.aJson());
    return _categoria(r.data);
  }

  @override
  Future<Categoria> actualizar(String id, Map<String, Object?> cambios) async {
    final r = await _api.patch(
      '$ruta/${Uri.encodeComponent(id)}',
      datos: cambios,
    );
    return _categoria(r.data);
  }

  Categoria _categoria(Object? cuerpo) => _leer(
    () => CatalogoModelos.categoria(CatalogoModelos.campo(cuerpo, 'categoria')),
  );
}

/// Materiales contra `/admin/materiales` (Bearer de ADMIN) [RF-22][RF-08].
///
/// El precio unitario viaja siempre como texto (`"4.50"`).
class MaterialesRepositoryImpl implements MaterialesRepository {
  MaterialesRepositoryImpl(this._api);

  final ApiClient _api;

  static const ruta = '/admin/materiales';

  @override
  Future<Paginado<MaterialCatalogo>> listar({
    int pagina = 1,
    int porPagina = 20,
    String q = '',
    bool? activo,
  }) async {
    final r = await _api.get(
      ruta,
      consulta: {
        'pagina': '$pagina',
        'porPagina': '$porPagina',
        if (q.trim().isNotEmpty) 'q': q.trim(),
        if (activo != null) 'activo': '$activo',
      },
    );
    return _leer(
      () => CatalogoModelos.paginado(r.data, CatalogoModelos.material),
    );
  }

  @override
  Future<MaterialCatalogo> crear(DatosMaterial datos) async {
    final r = await _api.post(ruta, datos: datos.aJson());
    return _material(r.data);
  }

  @override
  Future<MaterialCatalogo> actualizar(
    String id,
    Map<String, Object?> cambios,
  ) async {
    final r = await _api.patch(
      '$ruta/${Uri.encodeComponent(id)}',
      datos: cambios,
    );
    return _material(r.data);
  }

  MaterialCatalogo _material(Object? cuerpo) => _leer(
    () => CatalogoModelos.material(CatalogoModelos.campo(cuerpo, 'material')),
  );
}
