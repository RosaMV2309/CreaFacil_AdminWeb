import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/red.dart';
import '../data/catalogo_repositories_impl.dart';
import '../domain/entidades_catalogo.dart';

/// Filtro por estado (activa/inactiva) de las listas del catálogo.
enum FiltroEstado {
  todos(null),
  activos(true),
  inactivos(false);

  const FiltroEstado(this.valor);

  /// Valor del parámetro `activa`/`activo` (`null` = sin filtro).
  final bool? valor;
}

final categoriasRepositoryProvider = Provider<CategoriasRepository>(
  (ref) => CategoriasRepositoryImpl(ref.watch(apiClientProvider)),
);

final materialesRepositoryProvider = Provider<MaterialesRepository>(
  (ref) => MaterialesRepositoryImpl(ref.watch(apiClientProvider)),
);

// ---------------------------------------------------------------- Categorías

/// Búsqueda y filtro de la lista de categorías.
class FiltroCategorias {
  const FiltroCategorias({this.q = '', this.estado = FiltroEstado.todos});

  final String q;
  final FiltroEstado estado;
}

class FiltroCategoriasNotifier extends Notifier<FiltroCategorias> {
  @override
  FiltroCategorias build() => const FiltroCategorias();

  void buscar(String q) {
    if (q.trim() != state.q) {
      state = FiltroCategorias(q: q.trim(), estado: state.estado);
    }
  }

  void filtrarPorEstado(FiltroEstado estado) {
    state = FiltroCategorias(q: state.q, estado: estado);
  }
}

final filtroCategoriasProvider =
    NotifierProvider<FiltroCategoriasNotifier, FiltroCategorias>(
      FiltroCategoriasNotifier.new,
    );

/// Lista de categorías del panel [RF-22][RF-05]. Tras crear, editar o
/// cambiar el estado se vuelve a pedir la lista al servidor.
class CategoriasController extends AsyncNotifier<List<Categoria>> {
  CategoriasRepository get _repositorio =>
      ref.read(categoriasRepositoryProvider);

  @override
  Future<List<Categoria>> build() {
    final filtro = ref.watch(filtroCategoriasProvider);
    return ref
        .watch(categoriasRepositoryProvider)
        .listar(q: filtro.q, activa: filtro.estado.valor);
  }

  Future<Categoria> crear(DatosCategoria datos) =>
      _recargarTras(_repositorio.crear(datos));

  Future<Categoria> actualizar(String id, Map<String, Object?> cambios) =>
      _recargarTras(_repositorio.actualizar(id, cambios));

  /// Activa o desactiva (no hay borrado: RF-05).
  Future<Categoria> cambiarEstado(
    Categoria categoria, {
    required bool activa,
  }) => actualizar(categoria.id, {'activa': activa});

  Future<void> recargar() async => ref.invalidateSelf();

  Future<T> _recargarTras<T>(Future<T> peticion) async {
    final resultado = await peticion;
    ref.invalidateSelf();
    return resultado;
  }
}

final categoriasControllerProvider =
    AsyncNotifierProvider<CategoriasController, List<Categoria>>(
      CategoriasController.new,
      retry: (_, _) => null,
    );

// ---------------------------------------------------------------- Materiales

/// Búsqueda, filtro y página de la lista de materiales.
class FiltroMateriales {
  const FiltroMateriales({
    this.q = '',
    this.estado = FiltroEstado.todos,
    this.pagina = 1,
  });

  final String q;
  final FiltroEstado estado;
  final int pagina;
}

class FiltroMaterialesNotifier extends Notifier<FiltroMateriales> {
  @override
  FiltroMateriales build() => const FiltroMateriales();

  /// Al cambiar la búsqueda o el filtro se vuelve a la página 1.
  void buscar(String q) {
    if (q.trim() != state.q) {
      state = FiltroMateriales(q: q.trim(), estado: state.estado);
    }
  }

  void filtrarPorEstado(FiltroEstado estado) {
    state = FiltroMateriales(q: state.q, estado: estado);
  }

  void irAPagina(int pagina) {
    state = FiltroMateriales(q: state.q, estado: state.estado, pagina: pagina);
  }
}

final filtroMaterialesProvider =
    NotifierProvider<FiltroMaterialesNotifier, FiltroMateriales>(
      FiltroMaterialesNotifier.new,
    );

/// Lista paginada de materiales [RF-22][RF-08].
class MaterialesController extends AsyncNotifier<Paginado<MaterialCatalogo>> {
  static const porPagina = 20;

  MaterialesRepository get _repositorio =>
      ref.read(materialesRepositoryProvider);

  @override
  Future<Paginado<MaterialCatalogo>> build() {
    final filtro = ref.watch(filtroMaterialesProvider);
    return ref
        .watch(materialesRepositoryProvider)
        .listar(
          pagina: filtro.pagina,
          porPagina: porPagina,
          q: filtro.q,
          activo: filtro.estado.valor,
        );
  }

  Future<MaterialCatalogo> crear(DatosMaterial datos) =>
      _recargarTras(_repositorio.crear(datos));

  Future<MaterialCatalogo> actualizar(
    String id,
    Map<String, Object?> cambios,
  ) => _recargarTras(_repositorio.actualizar(id, cambios));

  Future<MaterialCatalogo> cambiarEstado(
    MaterialCatalogo material, {
    required bool activo,
  }) => actualizar(material.id, {'activo': activo});

  Future<void> recargar() async => ref.invalidateSelf();

  Future<T> _recargarTras<T>(Future<T> peticion) async {
    final resultado = await peticion;
    ref.invalidateSelf();
    return resultado;
  }
}

final materialesControllerProvider =
    AsyncNotifierProvider<MaterialesController, Paginado<MaterialCatalogo>>(
      MaterialesController.new,
      retry: (_, _) => null,
    );
