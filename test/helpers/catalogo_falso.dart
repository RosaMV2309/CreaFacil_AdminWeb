import 'package:creafacil_admin/core/network/red.dart';
import 'package:creafacil_admin/features/catalogo/domain/entidades_catalogo.dart';
import 'package:creafacil_admin/features/catalogo/domain/precio.dart';
import 'package:creafacil_admin/features/catalogo/presentation/catalogo_providers.dart';
import 'package:flutter_riverpod/misc.dart';

final fechaPrueba = DateTime.utc(2026, 11, 20, 12);

Categoria categoriaPrueba({
  String id = 'c1',
  String nombre = 'Murales',
  String? descripcion = 'Murales a mano',
  bool activa = true,
  int orden = 0,
  int serviciosActivos = 0,
  int serviciosTotales = 0,
}) => Categoria(
  id: id,
  nombre: nombre,
  descripcion: descripcion,
  activa: activa,
  orden: orden,
  serviciosActivos: serviciosActivos,
  serviciosTotales: serviciosTotales,
  creadoEn: fechaPrueba,
  actualizadoEn: fechaPrueba,
);

MaterialCatalogo materialPrueba({
  String id = 'm1',
  String nombre = 'Pintura acrílica',
  String unidad = 'litro',
  String precio = '0.75',
  String? descripcion,
  bool activo = true,
}) => MaterialCatalogo(
  id: id,
  nombre: nombre,
  descripcion: descripcion,
  unidad: unidad,
  precioUnitario: Precio.intentar(precio)!,
  activo: activo,
  creadoEn: fechaPrueba,
  actualizadoEn: fechaPrueba,
);

Map<String, Object?> jsonCategoria({
  String id = 'c1',
  String nombre = 'Murales',
  bool activa = true,
  int serviciosActivos = 2,
}) => {
  'id': id,
  'nombre': nombre,
  'descripcion': null,
  'activa': activa,
  'orden': 1,
  'serviciosActivos': serviciosActivos,
  'serviciosTotales': 3,
  'creadoEn': '2026-11-20T12:00:00.000Z',
  'actualizadoEn': '2026-11-20T12:00:00.000Z',
};

Map<String, Object?> jsonMaterial({
  String id = 'm1',
  String nombre = 'Lienzo',
  Object? precio = '4.50',
  bool activo = true,
}) => {
  'id': id,
  'nombre': nombre,
  'descripcion': 'Algodón',
  'unidad': 'metro',
  'precioUnitario': precio,
  'activo': activo,
  'creadoEn': '2026-11-20T12:00:00.000Z',
  'actualizadoEn': '2026-11-20T12:00:00.000Z',
};

/// Error de la API con la forma real del backend.
ApiException errorCatalogo(
  int estado,
  String codigo,
  String mensaje, [
  List<Map<String, String>> detalles = const [],
]) => ConversorErrores.desdeRespuesta(estado, {
  'error': {'codigo': codigo, 'mensaje': mensaje, 'detalles': detalles},
});

/// Repositorio de categorías en memoria que filtra como el servidor.
class RepositorioCategoriasFalso implements CategoriasRepository {
  RepositorioCategoriasFalso([List<Categoria>? iniciales])
    : categorias = [...?iniciales];

  final List<Categoria> categorias;
  final llamadas = <String>[];
  ApiException? errorListar;
  ApiException? errorGuardar;
  Future<void>? espera;
  DatosCategoria? ultimoAlta;
  Map<String, Object?>? ultimosCambios;
  var _siguiente = 100;

  @override
  Future<List<Categoria>> listar({String q = '', bool? activa}) async {
    llamadas.add('listar:$q:$activa');
    if (espera != null) await espera;
    if (errorListar != null) throw errorListar!;
    return [
      for (final c in categorias)
        if (c.nombre.toLowerCase().contains(q.toLowerCase()) &&
            (activa == null || c.activa == activa))
          c,
    ];
  }

  @override
  Future<Categoria> crear(DatosCategoria datos) async {
    llamadas.add('crear:${datos.nombre}');
    ultimoAlta = datos;
    if (espera != null) await espera;
    if (errorGuardar != null) throw errorGuardar!;
    final nueva = categoriaPrueba(
      id: 'c${_siguiente++}',
      nombre: datos.nombre,
      descripcion: datos.descripcion,
      orden: datos.orden,
    );
    categorias.add(nueva);
    return nueva;
  }

  @override
  Future<Categoria> actualizar(String id, Map<String, Object?> cambios) async {
    llamadas.add('actualizar:$id:$cambios');
    ultimosCambios = cambios;
    if (espera != null) await espera;
    if (errorGuardar != null) throw errorGuardar!;
    final i = categorias.indexWhere((c) => c.id == id);
    final a = categorias[i];
    final nueva = categoriaPrueba(
      id: a.id,
      nombre: (cambios['nombre'] as String?) ?? a.nombre,
      descripcion: cambios.containsKey('descripcion')
          ? cambios['descripcion'] as String?
          : a.descripcion,
      orden: (cambios['orden'] as int?) ?? a.orden,
      activa: (cambios['activa'] as bool?) ?? a.activa,
      serviciosActivos: a.serviciosActivos,
      serviciosTotales: a.serviciosTotales,
    );
    categorias[i] = nueva;
    return nueva;
  }
}

/// Repositorio de materiales en memoria con paginación.
class RepositorioMaterialesFalso implements MaterialesRepository {
  RepositorioMaterialesFalso([List<MaterialCatalogo>? iniciales])
    : materiales = [...?iniciales];

  final List<MaterialCatalogo> materiales;
  final llamadas = <String>[];
  ApiException? errorListar;
  ApiException? errorGuardar;
  DatosMaterial? ultimoAlta;
  Map<String, Object?>? ultimosCambios;
  var _siguiente = 100;

  @override
  Future<Paginado<MaterialCatalogo>> listar({
    int pagina = 1,
    int porPagina = 20,
    String q = '',
    bool? activo,
  }) async {
    llamadas.add('listar:$pagina:$q:$activo');
    if (errorListar != null) throw errorListar!;
    final filtrados = [
      for (final m in materiales)
        if (m.nombre.toLowerCase().contains(q.toLowerCase()) &&
            (activo == null || m.activo == activo))
          m,
    ];
    final total = filtrados.length;
    return Paginado(
      datos: filtrados.skip((pagina - 1) * porPagina).take(porPagina).toList(),
      pagina: pagina,
      porPagina: porPagina,
      total: total,
      totalPaginas: (total / porPagina).ceil(),
    );
  }

  @override
  Future<MaterialCatalogo> crear(DatosMaterial datos) async {
    llamadas.add('crear:${datos.nombre}');
    ultimoAlta = datos;
    if (errorGuardar != null) throw errorGuardar!;
    final nuevo = materialPrueba(
      id: 'm${_siguiente++}',
      nombre: datos.nombre,
      unidad: datos.unidad,
      precio: datos.precioUnitario.textoApi,
      descripcion: datos.descripcion,
    );
    materiales.add(nuevo);
    return nuevo;
  }

  @override
  Future<MaterialCatalogo> actualizar(
    String id,
    Map<String, Object?> cambios,
  ) async {
    llamadas.add('actualizar:$id:$cambios');
    ultimosCambios = cambios;
    if (errorGuardar != null) throw errorGuardar!;
    final i = materiales.indexWhere((m) => m.id == id);
    final a = materiales[i];
    final nuevo = materialPrueba(
      id: a.id,
      nombre: (cambios['nombre'] as String?) ?? a.nombre,
      unidad: (cambios['unidad'] as String?) ?? a.unidad,
      precio:
          (cambios['precioUnitario'] as String?) ?? a.precioUnitario.textoApi,
      descripcion: a.descripcion,
      activo: (cambios['activo'] as bool?) ?? a.activo,
    );
    materiales[i] = nuevo;
    return nuevo;
  }
}

/// Overrides del catálogo con repositorios en memoria.
List<Override> catalogoSimulado({
  CategoriasRepository? categorias,
  MaterialesRepository? materiales,
}) => [
  categoriasRepositoryProvider.overrideWithValue(
    categorias ?? RepositorioCategoriasFalso(),
  ),
  materialesRepositoryProvider.overrideWithValue(
    materiales ?? RepositorioMaterialesFalso(),
  ),
];
