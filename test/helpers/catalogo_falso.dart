import 'dart:async';
import 'dart:typed_data';

import 'package:creafacil_admin/core/archivos/selector_archivos.dart';
import 'package:creafacil_admin/core/network/red.dart';
import 'package:creafacil_admin/features/catalogo/domain/entidades_catalogo.dart';
import 'package:creafacil_admin/features/catalogo/domain/precio.dart';
import 'package:creafacil_admin/features/catalogo/domain/servicios.dart';
import 'package:creafacil_admin/features/catalogo/presentation/catalogo_providers.dart';
import 'package:creafacil_admin/features/catalogo/presentation/servicios_providers.dart';
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
  ServiciosRepository? servicios,
  SelectorArchivos? selector,
}) => [
  categoriasRepositoryProvider.overrideWithValue(
    categorias ?? RepositorioCategoriasFalso(),
  ),
  materialesRepositoryProvider.overrideWithValue(
    materiales ?? RepositorioMaterialesFalso(),
  ),
  serviciosRepositoryProvider.overrideWithValue(
    servicios ?? RepositorioServiciosFalso(),
  ),
  selectorArchivosProvider.overrideWithValue(
    selector ?? SelectorArchivosFalso(),
  ),
];

// ------------------------------------------------------------------ Servicios

const categoriaServicioPrueba = CategoriaDeServicio(
  id: 'c1',
  nombre: 'Murales',
  activa: true,
);

FotoServicio fotoPrueba(String id, int orden) =>
    FotoServicio(id: id, url: 'http://api.test/uploads/$id.png', orden: orden);

ServicioDetalle servicioPrueba({
  String id = 's1',
  String nombre = 'Mural infantil',
  CategoriaDeServicio categoria = categoriaServicioPrueba,
  bool activo = true,
  String? precio = '120.50',
  String? descripcion,
  String? dimensiones,
  String? observaciones,
  List<MaterialDeServicio> materiales = const [],
  List<FotoServicio> fotos = const [],
}) => ServicioDetalle(
  id: id,
  nombre: nombre,
  categoria: categoria,
  activo: activo,
  precioBaseReferencial: precio == null ? null : Precio.intentar(precio),
  portadaUrl: fotos.isEmpty ? null : fotos.first.url,
  numeroFotos: fotos.length,
  creadoEn: fechaPrueba,
  actualizadoEn: fechaPrueba,
  descripcion: descripcion,
  dimensionesOrientativas: dimensiones,
  observaciones: observaciones,
  materiales: materiales,
  fotos: fotos,
);

Map<String, Object?> jsonServicio({
  String id = 's1',
  Object? precio = '120.50',
  bool detalle = false,
  bool categoriaActiva = true,
}) => {
  'id': id,
  'nombre': 'Mural infantil',
  'categoria': {'id': 'c1', 'nombre': 'Murales', 'activa': categoriaActiva},
  'activo': true,
  'precioBaseReferencial': precio,
  'portadaUrl': 'http://api.test/uploads/f1.png',
  'numeroFotos': 2,
  'creadoEn': '2026-11-20T12:00:00.000Z',
  'actualizadoEn': '2026-11-20T12:00:00.000Z',
  if (detalle) ...{
    'descripcion': 'Mural pintado a mano',
    'dimensionesOrientativas': null,
    'observaciones': null,
    'materiales': [
      {'id': 'm1', 'nombre': 'Lienzo', 'unidad': 'metro', 'activo': false},
    ],
    'fotos': [
      {'id': 'f2', 'url': 'http://api.test/uploads/f2.png', 'orden': 1},
      {'id': 'f1', 'url': 'http://api.test/uploads/f1.png', 'orden': 0},
    ],
  },
};

/// Repositorio de servicios en memoria que filtra y ordena como el servidor.
class RepositorioServiciosFalso implements ServiciosRepository {
  RepositorioServiciosFalso([
    List<ServicioDetalle>? iniciales,
    this.categorias = const [],
  ]) : servicios = [...?iniciales];

  final List<ServicioDetalle> servicios;
  final List<Categoria> categorias;
  final llamadas = <String>[];
  ApiException? errorListar;
  ApiException? errorObtener;
  ApiException? errorGuardar;
  ApiException? errorFoto;
  Completer<void>? esperaFoto;
  DatosServicio? ultimoAlta;
  Map<String, Object?>? ultimosCambios;
  var _siguiente = 100;

  int _indice(String id) => servicios.indexWhere((s) => s.id == id);

  ServicioDetalle _con(
    ServicioDetalle a, {
    Map<String, Object?> cambios = const {},
    List<FotoServicio>? fotos,
  }) {
    final categoriaId = cambios['categoriaId'] as String?;
    final c = categoriaId == null
        ? a.categoria
        : categorias
              .where((x) => x.id == categoriaId)
              .map(
                (x) => CategoriaDeServicio(
                  id: x.id,
                  nombre: x.nombre,
                  activa: x.activa,
                ),
              )
              .first;
    String? texto(String clave, String? actual) =>
        cambios.containsKey(clave) ? cambios[clave] as String? : actual;
    return servicioPrueba(
      id: a.id,
      nombre: (cambios['nombre'] as String?) ?? a.nombre,
      categoria: c,
      activo: (cambios['activo'] as bool?) ?? a.activo,
      precio: texto('precioBaseReferencial', a.precioBaseReferencial?.textoApi),
      descripcion: texto('descripcion', a.descripcion),
      dimensiones: texto('dimensionesOrientativas', a.dimensionesOrientativas),
      observaciones: texto('observaciones', a.observaciones),
      materiales: cambios.containsKey('materialIds')
          ? [
              for (final id in cambios['materialIds']! as List<String>)
                MaterialDeServicio(
                  id: id,
                  nombre: 'Material $id',
                  unidad: 'unidad',
                  activo: true,
                ),
            ]
          : a.materiales,
      fotos: fotos ?? a.fotos,
    );
  }

  @override
  Future<Paginado<ServicioResumen>> listar({
    int pagina = 1,
    int porPagina = 20,
    String q = '',
    String? categoriaId,
    bool? activo,
  }) async {
    llamadas.add('listar:$pagina:$q:${categoriaId ?? ''}:$activo');
    if (errorListar != null) throw errorListar!;
    final filtrados = [
      for (final s in servicios)
        if (s.nombre.toLowerCase().contains(q.toLowerCase()) &&
            (categoriaId == null ||
                categoriaId.isEmpty ||
                s.categoria.id == categoriaId) &&
            (activo == null || s.activo == activo))
          s,
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
  Future<ServicioDetalle> obtener(String id) async {
    llamadas.add('obtener:$id');
    if (errorObtener != null) throw errorObtener!;
    return servicios[_indice(id)];
  }

  @override
  Future<ServicioDetalle> crear(DatosServicio datos) async {
    llamadas.add('crear:${datos.nombre}');
    ultimoAlta = datos;
    if (errorGuardar != null) throw errorGuardar!;
    final nuevo = _con(
      servicioPrueba(id: 's${_siguiente++}', precio: null),
      cambios: datos.aJson(),
    );
    servicios.add(nuevo);
    return nuevo;
  }

  @override
  Future<ServicioDetalle> actualizar(
    String id,
    Map<String, Object?> cambios,
  ) async {
    llamadas.add('actualizar:$id:$cambios');
    ultimosCambios = cambios;
    if (errorGuardar != null) throw errorGuardar!;
    final i = _indice(id);
    return servicios[i] = _con(servicios[i], cambios: cambios);
  }

  @override
  Future<FotoServicio> subirFoto(
    String id,
    ArchivoFoto archivo, {
    void Function(double progreso)? progreso,
  }) async {
    llamadas.add('subir:$id:${archivo.nombre}:${archivo.tipoMime}');
    progreso?.call(0.5);
    if (esperaFoto != null) await esperaFoto!.future;
    if (errorFoto != null) throw errorFoto!;
    progreso?.call(1);
    final i = _indice(id);
    final foto = fotoPrueba('f${_siguiente++}', servicios[i].fotos.length);
    servicios[i] = _con(servicios[i], fotos: [...servicios[i].fotos, foto]);
    return foto;
  }

  List<FotoServicio> _renumerar(String id, List<FotoServicio> fotos) {
    final nuevas = [
      for (var i = 0; i < fotos.length; i++) fotoPrueba(fotos[i].id, i),
    ];
    final i = _indice(id);
    servicios[i] = _con(servicios[i], fotos: nuevas);
    return nuevas;
  }

  @override
  Future<List<FotoServicio>> ordenarFotos(
    String id,
    List<String> fotoIds,
  ) async {
    llamadas.add('ordenar:$id:${fotoIds.join(',')}');
    if (errorFoto != null) throw errorFoto!;
    final fotos = servicios[_indice(id)].fotos;
    return _renumerar(id, [
      for (final f in fotoIds) fotos.firstWhere((x) => x.id == f),
    ]);
  }

  @override
  Future<List<FotoServicio>> borrarFoto(String id, String fotoId) async {
    llamadas.add('borrar:$id:$fotoId');
    if (errorFoto != null) throw errorFoto!;
    return _renumerar(id, [
      for (final f in servicios[_indice(id)].fotos)
        if (f.id != fotoId) f,
    ]);
  }
}

/// Selector de archivos simulado: devuelve [siguiente].
class SelectorArchivosFalso implements SelectorArchivos {
  ArchivoElegido? siguiente;
  var llamadas = 0;

  /// Archivo de [tamano] bytes (los bytes reales se generan al leer).
  void elegir(String nombre, {int? tamano = 70, int bytes = 70}) {
    siguiente = ArchivoElegido(
      nombre: nombre,
      tamano: tamano,
      leer: () async => Uint8List(bytes),
    );
  }

  @override
  Future<ArchivoElegido?> elegirImagen({
    required List<String> extensiones,
  }) async {
    llamadas++;
    return siguiente;
  }
}
