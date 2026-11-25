import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/red.dart';
import '../data/catalogo_repositories_impl.dart';
import '../domain/entidades_catalogo.dart';
import '../domain/servicios.dart';
import 'catalogo_providers.dart';

final serviciosRepositoryProvider = Provider<ServiciosRepository>(
  (ref) => ServiciosRepositoryImpl(ref.watch(apiClientProvider)),
);

/// Búsqueda, filtros y página de la lista de servicios.
class FiltroServicios {
  const FiltroServicios({
    this.q = '',
    this.categoriaId = todas,
    this.estado = FiltroEstado.todos,
    this.pagina = 1,
  });

  /// Valor de «Todas las categorías» (el `CfSelect` no muestra `null`).
  static const todas = '';

  final String q;
  final String categoriaId;
  final FiltroEstado estado;
  final int pagina;

  FiltroServicios copiar({
    String? q,
    String? categoriaId,
    FiltroEstado? estado,
    int pagina = 1,
  }) => FiltroServicios(
    q: q ?? this.q,
    categoriaId: categoriaId ?? this.categoriaId,
    estado: estado ?? this.estado,
    pagina: pagina,
  );
}

class FiltroServiciosNotifier extends Notifier<FiltroServicios> {
  @override
  FiltroServicios build() => const FiltroServicios();

  /// Al cambiar la búsqueda o un filtro se vuelve a la página 1.
  void buscar(String q) {
    if (q.trim() != state.q) {
      state = state.copiar(q: q.trim());
    }
  }

  void filtrarPorCategoria(String categoriaId) =>
      state = state.copiar(categoriaId: categoriaId);

  void filtrarPorEstado(FiltroEstado estado) =>
      state = state.copiar(estado: estado);

  void irAPagina(int pagina) => state = state.copiar(pagina: pagina);
}

final filtroServiciosProvider =
    NotifierProvider<FiltroServiciosNotifier, FiltroServicios>(
      FiltroServiciosNotifier.new,
    );

/// Lista paginada de servicios [RF-22][RF-05]. Tras crear, editar o cambiar
/// el estado se vuelve a pedir la lista al servidor.
class ServiciosController extends AsyncNotifier<Paginado<ServicioResumen>> {
  static const porPagina = 20;

  ServiciosRepository get _repositorio => ref.read(serviciosRepositoryProvider);

  @override
  Future<Paginado<ServicioResumen>> build() {
    final filtro = ref.watch(filtroServiciosProvider);
    return ref
        .watch(serviciosRepositoryProvider)
        .listar(
          pagina: filtro.pagina,
          porPagina: porPagina,
          q: filtro.q,
          categoriaId: filtro.categoriaId,
          activo: filtro.estado.valor,
        );
  }

  /// Ficha completa (para editar); no recarga la lista.
  Future<ServicioDetalle> obtener(String id) => _repositorio.obtener(id);

  Future<ServicioDetalle> crear(DatosServicio datos) =>
      _recargarTras(_repositorio.crear(datos));

  Future<ServicioDetalle> actualizar(String id, Map<String, Object?> cambios) =>
      _recargarTras(_repositorio.actualizar(id, cambios));

  /// Activa o desactiva (no hay borrado: RF-05).
  Future<ServicioDetalle> cambiarEstado(
    ServicioResumen servicio, {
    required bool activo,
  }) => actualizar(servicio.id, {'activo': activo});

  Future<void> recargar() async => ref.invalidateSelf();

  Future<T> _recargarTras<T>(Future<T> peticion) async {
    final resultado = await peticion;
    ref.invalidateSelf();
    return resultado;
  }
}

final serviciosControllerProvider =
    AsyncNotifierProvider<ServiciosController, Paginado<ServicioResumen>>(
      ServiciosController.new,
      retry: (_, _) => null,
    );

/// Todas las categorías (activas e inactivas) para el filtro y el
/// formulario.
final opcionesCategoriasProvider = FutureProvider.autoDispose<List<Categoria>>(
  (ref) => ref.watch(categoriasRepositoryProvider).listar(),
  retry: (_, _) => null,
);

/// Materiales activos que se pueden añadir a un servicio (máximo 100, el
/// tope de `porPagina` del servidor).
final materialesActivosProvider =
    FutureProvider.autoDispose<List<MaterialCatalogo>>(
      (ref) async =>
          (await ref
                  .watch(materialesRepositoryProvider)
                  .listar(porPagina: 100, activo: true))
              .datos,
      retry: (_, _) => null,
    );

/// Fotos de un servicio [RF-04]. El orden y la portada los decide el
/// servidor: aquí solo se muestra lo que devuelve.
class FotosServicioController extends AsyncNotifier<List<FotoServicio>> {
  FotosServicioController(this.servicioId);

  final String servicioId;

  ServiciosRepository get _repositorio => ref.read(serviciosRepositoryProvider);

  @override
  Future<List<FotoServicio>> build() async =>
      (await ref.watch(serviciosRepositoryProvider).obtener(servicioId)).fotos;

  List<FotoServicio> get _actuales => state.value ?? const [];

  Future<FotoServicio> subir(
    ArchivoFoto archivo, {
    void Function(double progreso)? progreso,
  }) async {
    final foto = await _repositorio.subirFoto(
      servicioId,
      archivo,
      progreso: progreso,
    );
    state = AsyncData(
      [..._actuales, foto]..sort((a, b) => a.orden.compareTo(b.orden)),
    );
    return foto;
  }

  /// Mueve [foto] a la posición [destino] y envía el orden completo.
  Future<void> mover(FotoServicio foto, int destino) async {
    final ids = [for (final f in _actuales) f.id]..remove(foto.id);
    ids.insert(destino.clamp(0, ids.length), foto.id);
    state = AsyncData(await _repositorio.ordenarFotos(servicioId, ids));
  }

  Future<void> borrar(FotoServicio foto) async {
    state = AsyncData(await _repositorio.borrarFoto(servicioId, foto.id));
  }

  Future<void> recargar() async => ref.invalidateSelf();
}

final fotosServicioProvider = AsyncNotifierProvider.autoDispose
    .family<FotosServicioController, List<FotoServicio>, String>(
      FotosServicioController.new,
      retry: (_, _) => null,
    );
