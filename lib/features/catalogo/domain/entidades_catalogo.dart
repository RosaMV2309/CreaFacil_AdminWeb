import 'precio.dart';

/// Categoría del catálogo tal como la ve la administradora [RF-22][RF-05].
class Categoria {
  const Categoria({
    required this.id,
    required this.nombre,
    required this.activa,
    required this.orden,
    required this.serviciosActivos,
    required this.serviciosTotales,
    required this.creadoEn,
    required this.actualizadoEn,
    this.descripcion,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final bool activa;
  final int orden;

  /// Servicios activos de la categoría (el servidor los cuenta).
  final int serviciosActivos;
  final int serviciosTotales;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
}

/// Material con su precio unitario exacto [RF-08].
class MaterialCatalogo {
  const MaterialCatalogo({
    required this.id,
    required this.nombre,
    required this.unidad,
    required this.precioUnitario,
    required this.activo,
    required this.creadoEn,
    required this.actualizadoEn,
    this.descripcion,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final String unidad;
  final Precio precioUnitario;
  final bool activo;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
}

/// Página de resultados con la paginación que devuelve el servidor.
class Paginado<T> {
  const Paginado({
    required this.datos,
    required this.pagina,
    required this.porPagina,
    required this.total,
    required this.totalPaginas,
  });

  final List<T> datos;
  final int pagina;
  final int porPagina;
  final int total;
  final int totalPaginas;
}

/// Datos del formulario de una categoría.
class DatosCategoria {
  const DatosCategoria({
    required this.nombre,
    this.descripcion,
    this.orden = 0,
  });

  final String nombre;

  /// `null` si se deja vacía.
  final String? descripcion;
  final int orden;

  /// Cuerpo de `POST /admin/categorias`.
  Map<String, Object?> aJson() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'orden': orden,
  };

  /// Solo los campos que cambian respecto a [actual] (cuerpo del PATCH).
  Map<String, Object?> cambiosRespectoA(Categoria actual) => {
    if (nombre != actual.nombre) 'nombre': nombre,
    if (descripcion != actual.descripcion) 'descripcion': descripcion,
    if (orden != actual.orden) 'orden': orden,
  };
}

/// Datos del formulario de un material.
class DatosMaterial {
  const DatosMaterial({
    required this.nombre,
    required this.unidad,
    required this.precioUnitario,
    this.descripcion,
  });

  final String nombre;
  final String unidad;
  final Precio precioUnitario;
  final String? descripcion;

  /// Cuerpo de `POST /admin/materiales`. El precio va como **texto**.
  Map<String, Object?> aJson() => {
    'nombre': nombre,
    'unidad': unidad,
    'precioUnitario': precioUnitario.textoApi,
    'descripcion': descripcion,
  };

  /// Solo los campos que cambian respecto a [actual] (cuerpo del PATCH).
  Map<String, Object?> cambiosRespectoA(MaterialCatalogo actual) => {
    if (nombre != actual.nombre) 'nombre': nombre,
    if (unidad != actual.unidad) 'unidad': unidad,
    if (precioUnitario != actual.precioUnitario)
      'precioUnitario': precioUnitario.textoApi,
    if (descripcion != actual.descripcion) 'descripcion': descripcion,
  };
}

/// Contrato de la gestión de categorías (`/admin/categorias`).
abstract interface class CategoriasRepository {
  Future<List<Categoria>> listar({String q = '', bool? activa});
  Future<Categoria> crear(DatosCategoria datos);

  /// PATCH con cualquier subconjunto de campos (al menos uno).
  Future<Categoria> actualizar(String id, Map<String, Object?> cambios);
}

/// Contrato de la gestión de materiales (`/admin/materiales`).
abstract interface class MaterialesRepository {
  Future<Paginado<MaterialCatalogo>> listar({
    int pagina = 1,
    int porPagina = 20,
    String q = '',
    bool? activo,
  });
  Future<MaterialCatalogo> crear(DatosMaterial datos);

  /// PATCH con cualquier subconjunto de campos (al menos uno).
  Future<MaterialCatalogo> actualizar(String id, Map<String, Object?> cambios);
}
