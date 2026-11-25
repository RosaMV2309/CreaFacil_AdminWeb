import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/cf_components.dart';
import '../../../core/network/red.dart';
import '../domain/entidades_catalogo.dart';
import 'catalogo_providers.dart';
import 'widgets/comunes_catalogo.dart';
import 'widgets/formulario_categoria.dart';

/// Gestión de categorías: tabla, búsqueda, filtro, alta, edición y
/// activar o desactivar (sin borrado) [RF-22][RF-05].
class CategoriasTab extends ConsumerStatefulWidget {
  const CategoriasTab({super.key});

  static const claveNueva = ValueKey('categorias-nueva');
  static const claveFiltro = ValueKey('categorias-filtro');
  static const claveAviso = ValueKey('categorias-aviso');

  static ValueKey<String> claveFila(String id) => ValueKey('categoria-$id');
  static ValueKey<String> claveEditar(String id) =>
      ValueKey('categoria-editar-$id');
  static ValueKey<String> claveEstado(String id) =>
      ValueKey('categoria-estado-$id');

  /// Aviso al desactivar una categoría con servicios activos: la categoría
  /// los oculta del catálogo, pero no los desactiva.
  static String avisoServicios(int servicios) => servicios == 1
      ? 'Su servicio activo dejará de verse en el catálogo, pero no se '
            'desactiva.'
      : 'Sus $servicios servicios dejarán de verse en el catálogo, pero no '
            'se desactivan.';

  @override
  ConsumerState<CategoriasTab> createState() => _CategoriasTabState();
}

class _CategoriasTabState extends ConsumerState<CategoriasTab> {
  final _enCurso = <String>{};
  AvisoCatalogo? _aviso;

  Future<void> _abrirFormulario([Categoria? categoria]) async {
    final guardada = await FormularioCategoria.abrir(
      context,
      categoria: categoria,
    );
    if (guardada != null && mounted) {
      setState(
        () => _aviso = AvisoCatalogo(
          categoria == null
              ? 'Se creó la categoría «${guardada.nombre}».'
              : 'Se guardaron los cambios de «${guardada.nombre}».',
        ),
      );
    }
  }

  Future<void> _cambiarEstado(Categoria categoria) async {
    if (_enCurso.contains(categoria.id)) {
      return;
    }
    final activar = !categoria.activa;
    if (!activar && categoria.serviciosActivos > 0) {
      final confirmado = await CfConfirmDialog.mostrar(
        context,
        titulo: '¿Desactivar «${categoria.nombre}»?',
        mensaje: CategoriasTab.avisoServicios(categoria.serviciosActivos),
        textoConfirmar: 'Desactivar',
        peligro: true,
      );
      if (!confirmado || !mounted) {
        return;
      }
    }
    setState(() {
      _enCurso.add(categoria.id);
      _aviso = null;
    });
    try {
      final r = await ref
          .read(categoriasControllerProvider.notifier)
          .cambiarEstado(categoria, activa: activar);
      _avisar(
        AvisoCatalogo(
          r.activa
              ? 'La categoría «${r.nombre}» está activa.'
              : 'La categoría «${r.nombre}» está desactivada.',
        ),
      );
    } on ApiException catch (error) {
      _avisar(AvisoCatalogo.desdeError(error));
    } finally {
      if (mounted) {
        setState(() => _enCurso.remove(categoria.id));
      }
    }
  }

  void _avisar(AvisoCatalogo aviso) {
    if (mounted) {
      setState(() => _aviso = aviso);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final estado = ref.watch(categoriasControllerProvider);
    final filtro = ref.watch(filtroCategoriasProvider);
    final filtroNotifier = ref.read(filtroCategoriasProvider.notifier);
    final error = estado.error;

    return PaginaCatalogo(
      children: [
        EncabezadoCatalogo(
          titulo: 'Categorías',
          descripcion:
              'Organizan los servicios del catálogo. Una categoría '
              'desactivada oculta sus servicios a los clientes.',
          accion: CfButton(
            key: CategoriasTab.claveNueva,
            label: 'Nueva categoría',
            icon: Icons.add_rounded,
            onPressed: _abrirFormulario,
          ),
        ),
        SizedBox(height: tokens.espacioXl),
        BarraFiltros(
          etiquetaBusqueda: 'Buscar por nombre',
          textoInicial: filtro.q,
          onBuscar: filtroNotifier.buscar,
          filtro: CfSelect<FiltroEstado>(
            key: CategoriasTab.claveFiltro,
            label: 'Estado',
            valor: filtro.estado,
            opciones: opcionesEstado(femenino: true),
            onChanged: filtroNotifier.filtrarPorEstado,
          ),
        ),
        SizedBox(height: tokens.espacioLg),
        if (_aviso != null) ...[
          _aviso!.mostrar(
            key: CategoriasTab.claveAviso,
            onClose: () => setState(() => _aviso = null),
          ),
          SizedBox(height: tokens.espacioLg),
        ],
        CfDataTable<Categoria>(
          etiqueta: 'Tabla de categorías',
          filas: estado.value ?? const [],
          cargando: estado.isLoading,
          error: error == null
              ? null
              : (error is ApiException
                    ? error.mensaje
                    : 'No se pudo cargar la lista de categorías.'),
          onReintentar: () =>
              ref.read(categoriasControllerProvider.notifier).recargar(),
          tituloVacio: filtro.q.isEmpty && filtro.estado == FiltroEstado.todos
              ? 'Aún no hay categorías'
              : 'Ninguna categoría coincide',
          mensajeVacio: 'Crea una con «Nueva categoría» o cambia el filtro.',
          claveFila: (c) => CategoriasTab.claveFila(c.id),
          columnas: [
            CfColumna(
              titulo: 'Nombre',
              flex: 3,
              celda: (c) => Text(
                c.nombre,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            CfColumna(
              titulo: 'Descripción',
              flex: 4,
              celda: (c) => Text(
                c.descripcion ?? '—',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            CfColumna(
              titulo: 'Orden',
              numerica: true,
              celda: (c) => Text('${c.orden}'),
            ),
            CfColumna(
              titulo: 'Estado',
              flex: 2,
              celda: (c) => etiquetaEstado(activo: c.activa, femenino: true),
            ),
            CfColumna(
              titulo: 'Servicios activos',
              flex: 2,
              numerica: true,
              celda: (c) => Text(
                '${c.serviciosActivos} de ${c.serviciosTotales}',
                semanticsLabel:
                    '${c.serviciosActivos} servicios activos de '
                    '${c.serviciosTotales}',
              ),
            ),
          ],
          acciones: (c) => [
            CfAccionFila(
              clave: CategoriasTab.claveEditar(c.id),
              etiqueta: 'Editar',
              icono: Icons.edit_outlined,
              onPressed: _enCurso.contains(c.id)
                  ? null
                  : () => _abrirFormulario(c),
            ),
            CfAccionFila(
              clave: CategoriasTab.claveEstado(c.id),
              etiqueta: c.activa ? 'Desactivar' : 'Activar',
              icono: c.activa
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              peligro: c.activa,
              cargando: _enCurso.contains(c.id),
              onPressed: () => _cambiarEstado(c),
            ),
          ],
        ),
      ],
    );
  }
}
