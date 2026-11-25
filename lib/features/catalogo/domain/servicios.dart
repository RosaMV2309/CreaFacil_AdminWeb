import 'dart:typed_data';

import 'entidades_catalogo.dart';
import 'precio.dart';

/// Categoría tal como llega dentro de un servicio.
class CategoriaDeServicio {
  const CategoriaDeServicio({
    required this.id,
    required this.nombre,
    required this.activa,
  });

  final String id;
  final String nombre;

  /// Si es `false`, el servicio no se ve en el catálogo público.
  final bool activa;
}

/// Material habitual de un servicio [RF-04].
class MaterialDeServicio {
  const MaterialDeServicio({
    required this.id,
    required this.nombre,
    required this.unidad,
    required this.activo,
  });

  final String id;
  final String nombre;
  final String unidad;
  final bool activo;
}

/// Foto de un servicio. La de orden 0 es la portada [RF-04].
class FotoServicio {
  const FotoServicio({
    required this.id,
    required this.url,
    required this.orden,
  });

  final String id;

  /// URL absoluta; se carga sin token.
  final String url;
  final int orden;

  bool get esPortada => orden == 0;
}

/// Fila de la tabla de servicios (`GET /admin/servicios`) [RF-22].
class ServicioResumen {
  const ServicioResumen({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.activo,
    required this.numeroFotos,
    required this.creadoEn,
    required this.actualizadoEn,
    this.precioBaseReferencial,
    this.portadaUrl,
  });

  final String id;
  final String nombre;
  final CategoriaDeServicio categoria;
  final bool activo;

  /// Precio «desde» opcional (RN-01: siempre referencial).
  final Precio? precioBaseReferencial;
  final String? portadaUrl;
  final int numeroFotos;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
}

/// Ficha completa de un servicio (`GET /admin/servicios/:id`) [RF-04].
class ServicioDetalle extends ServicioResumen {
  const ServicioDetalle({
    required super.id,
    required super.nombre,
    required super.categoria,
    required super.activo,
    required super.numeroFotos,
    required super.creadoEn,
    required super.actualizadoEn,
    super.precioBaseReferencial,
    super.portadaUrl,
    this.descripcion,
    this.dimensionesOrientativas,
    this.observaciones,
    this.materiales = const [],
    this.fotos = const [],
  });

  final String? descripcion;
  final String? dimensionesOrientativas;
  final String? observaciones;
  final List<MaterialDeServicio> materiales;
  final List<FotoServicio> fotos;
}

/// Datos del formulario de un servicio.
class DatosServicio {
  const DatosServicio({
    required this.categoriaId,
    required this.nombre,
    this.descripcion,
    this.dimensionesOrientativas,
    this.observaciones,
    this.precioBaseReferencial,
    this.materialIds = const [],
  });

  final String categoriaId;
  final String nombre;
  final String? descripcion;
  final String? dimensionesOrientativas;
  final String? observaciones;
  final Precio? precioBaseReferencial;
  final List<String> materialIds;

  /// Cuerpo de `POST /admin/servicios`: solo los campos con valor. El
  /// precio viaja como **texto** (`"120.50"`).
  Map<String, Object?> aJson() => {
    'categoriaId': categoriaId,
    'nombre': nombre,
    'descripcion': ?descripcion,
    'dimensionesOrientativas': ?dimensionesOrientativas,
    'observaciones': ?observaciones,
    'precioBaseReferencial': ?precioBaseReferencial?.textoApi,
    if (materialIds.isNotEmpty) 'materialIds': materialIds,
  };

  /// Solo lo que cambia respecto a [actual] (cuerpo del PATCH). `null`
  /// borra un texto o el precio; `materialIds` reemplaza la lista entera.
  Map<String, Object?> cambiosRespectoA(ServicioDetalle actual) {
    final actuales = {for (final m in actual.materiales) m.id};
    final nuevos = materialIds.toSet();
    final mismosMateriales =
        actuales.length == nuevos.length && actuales.containsAll(nuevos);
    return {
      if (categoriaId != actual.categoria.id) 'categoriaId': categoriaId,
      if (nombre != actual.nombre) 'nombre': nombre,
      if (descripcion != actual.descripcion) 'descripcion': descripcion,
      if (dimensionesOrientativas != actual.dimensionesOrientativas)
        'dimensionesOrientativas': dimensionesOrientativas,
      if (observaciones != actual.observaciones) 'observaciones': observaciones,
      if (precioBaseReferencial != actual.precioBaseReferencial)
        'precioBaseReferencial': precioBaseReferencial?.textoApi,
      if (!mismosMateriales) 'materialIds': materialIds,
    };
  }
}

/// Imagen lista para enviar en `multipart/form-data`.
class ArchivoFoto {
  const ArchivoFoto({required this.nombre, required this.bytes});

  final String nombre;
  final Uint8List bytes;

  /// Tipo MIME según la extensión (el servidor comprueba el contenido real).
  String get tipoMime => ValidacionesServicio.tipoMime(nombre);
}

/// Validaciones de los servicios en el cliente, con los mismos límites que
/// el servidor (subfase 2.2). El servidor vuelve a validar siempre.
abstract final class ValidacionesServicio {
  static const nombreMin = 2;
  static const nombreMax = 120;
  static const descripcionMax = 2000;
  static const dimensionesMax = 200;
  static const observacionesMax = 1000;
  static const maxFotos = 8;
  static const maxBytesFoto = 5 * 1024 * 1024;
  static const extensiones = ['jpg', 'jpeg', 'png', 'webp'];

  static String? nombre(String? valor) {
    final texto = (valor ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
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

  /// Validador de un texto opcional con [maximo] caracteres.
  static String? Function(String?) textoMaximo(String sujeto, int maximo) =>
      (valor) => (valor ?? '').trim().length > maximo
      ? '$sujeto admite como máximo $maximo caracteres.'
      : null;

  static String? categoria(String? id) =>
      id == null || id.isEmpty ? 'Elige la categoría.' : null;

  /// Precio referencial opcional: vacío = sin precio; si hay texto, las
  /// mismas reglas que el precio de los materiales.
  static String? precioOpcional(String? valor) =>
      (valor ?? '').trim().isEmpty ? null : Precio.validar(valor);

  static String extension(String nombreArchivo) {
    final punto = nombreArchivo.lastIndexOf('.');
    return punto < 0 ? '' : nombreArchivo.substring(punto + 1).toLowerCase();
  }

  static String tipoMime(String nombreArchivo) =>
      switch (extension(nombreArchivo)) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  /// Comprueba la extensión y el tamaño antes de enviar la foto. El
  /// servidor valida además el contenido real del archivo.
  static String? archivo(String nombreArchivo, int tamano) {
    if (!extensiones.contains(extension(nombreArchivo))) {
      return 'Elige una imagen JPG, PNG o WebP.';
    }
    if (tamano <= 0) {
      return 'El archivo está vacío.';
    }
    if (tamano > maxBytesFoto) {
      final mb = (tamano / (1024 * 1024)).toStringAsFixed(1);
      return 'La foto pesa $mb MB y el máximo es 5 MB.';
    }
    return null;
  }
}

/// Contrato de la gestión de servicios (`/admin/servicios`) [RF-22][RF-05].
abstract interface class ServiciosRepository {
  Future<Paginado<ServicioResumen>> listar({
    int pagina = 1,
    int porPagina = 20,
    String q = '',
    String? categoriaId,
    bool? activo,
  });
  Future<ServicioDetalle> obtener(String id);
  Future<ServicioDetalle> crear(DatosServicio datos);

  /// PATCH con cualquier subconjunto de campos (al menos uno).
  Future<ServicioDetalle> actualizar(String id, Map<String, Object?> cambios);

  /// Sube una foto. [progreso] recibe valores de 0 a 1 [RF-04].
  Future<FotoServicio> subirFoto(
    String id,
    ArchivoFoto archivo, {
    void Function(double progreso)? progreso,
  });

  /// Nuevo orden con **todos** los ids de las fotos.
  Future<List<FotoServicio>> ordenarFotos(String id, List<String> fotoIds);

  /// Borra una foto y devuelve las restantes, renumeradas.
  Future<List<FotoServicio>> borrarFoto(String id, String fotoId);
}
