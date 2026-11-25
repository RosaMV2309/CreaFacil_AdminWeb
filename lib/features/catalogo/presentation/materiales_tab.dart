import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/cf_components.dart';
import '../../../core/network/red.dart';
import '../domain/entidades_catalogo.dart';
import 'catalogo_providers.dart';
import 'widgets/comunes_catalogo.dart';
import 'widgets/formulario_material.dart';

/// Gestión de materiales: tabla paginada con el precio exacto, búsqueda,
/// filtro, alta, edición y activar o desactivar [RF-22][RF-08].
class MaterialesTab extends ConsumerStatefulWidget {
  const MaterialesTab({super.key});

  static const claveNuevo = ValueKey('materiales-nuevo');
  static const claveFiltro = ValueKey('materiales-filtro');
  static const claveAviso = ValueKey('materiales-aviso');

  static ValueKey<String> claveFila(String id) => ValueKey('material-$id');
  static ValueKey<String> claveEditar(String id) =>
      ValueKey('material-editar-$id');
  static ValueKey<String> claveEstado(String id) =>
      ValueKey('material-estado-$id');

  @override
  ConsumerState<MaterialesTab> createState() => _MaterialesTabState();
}

class _MaterialesTabState extends ConsumerState<MaterialesTab> {
  final _enCurso = <String>{};
  AvisoCatalogo? _aviso;

  Future<void> _abrirFormulario([MaterialCatalogo? material]) async {
    final guardado = await FormularioMaterial.abrir(
      context,
      material: material,
    );
    if (guardado != null && mounted) {
      setState(
        () => _aviso = AvisoCatalogo(
          material == null
              ? 'Se creó el material «${guardado.nombre}» '
                    '(${guardado.precioUnitario.formateado}).'
              : 'Se guardaron los cambios de «${guardado.nombre}» '
                    '(${guardado.precioUnitario.formateado}).',
        ),
      );
    }
  }

  Future<void> _cambiarEstado(MaterialCatalogo material) async {
    if (_enCurso.contains(material.id)) {
      return;
    }
    setState(() {
      _enCurso.add(material.id);
      _aviso = null;
    });
    AvisoCatalogo aviso;
    try {
      final r = await ref
          .read(materialesControllerProvider.notifier)
          .cambiarEstado(material, activo: !material.activo);
      aviso = AvisoCatalogo(
        r.activo
            ? 'El material «${r.nombre}» está activo.'
            : 'El material «${r.nombre}» está desactivado.',
      );
    } on ApiException catch (error) {
      aviso = AvisoCatalogo.desdeError(error);
    }
    if (mounted) {
      setState(() {
        _enCurso.remove(material.id);
        _aviso = aviso;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final estado = ref.watch(materialesControllerProvider);
    final filtro = ref.watch(filtroMaterialesProvider);
    final filtroNotifier = ref.read(filtroMaterialesProvider.notifier);
    final pagina = estado.value;
    final error = estado.error;

    return PaginaCatalogo(
      children: [
        EncabezadoCatalogo(
          titulo: 'Materiales',
          descripcion:
              'Precios unitarios que usa la cotización estimada. Un material '
              'desactivado no se puede añadir a servicios nuevos.',
          accion: CfButton(
            key: MaterialesTab.claveNuevo,
            label: 'Nuevo material',
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
            key: MaterialesTab.claveFiltro,
            label: 'Estado',
            valor: filtro.estado,
            opciones: opcionesEstado(femenino: false),
            onChanged: filtroNotifier.filtrarPorEstado,
          ),
        ),
        SizedBox(height: tokens.espacioLg),
        if (_aviso != null) ...[
          _aviso!.mostrar(
            key: MaterialesTab.claveAviso,
            onClose: () => setState(() => _aviso = null),
          ),
          SizedBox(height: tokens.espacioLg),
        ],
        CfDataTable<MaterialCatalogo>(
          etiqueta: 'Tabla de materiales',
          filas: pagina?.datos ?? const [],
          cargando: estado.isLoading,
          error: error == null
              ? null
              : (error is ApiException
                    ? error.mensaje
                    : 'No se pudo cargar la lista de materiales.'),
          onReintentar: () =>
              ref.read(materialesControllerProvider.notifier).recargar(),
          tituloVacio: filtro.q.isEmpty && filtro.estado == FiltroEstado.todos
              ? 'Aún no hay materiales'
              : 'Ningún material coincide',
          mensajeVacio: 'Crea uno con «Nuevo material» o cambia el filtro.',
          claveFila: (m) => MaterialesTab.claveFila(m.id),
          paginacion: pagina == null
              ? null
              : CfPaginacion(
                  pagina: pagina.pagina,
                  totalPaginas: pagina.totalPaginas,
                  total: pagina.total,
                  onCambiar: filtroNotifier.irAPagina,
                ),
          columnas: [
            CfColumna(
              titulo: 'Nombre',
              flex: 4,
              celda: (m) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (m.descripcion != null)
                    Text(
                      m.descripcion!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            CfColumna(titulo: 'Unidad', flex: 2, celda: (m) => Text(m.unidad)),
            CfColumna(
              titulo: 'Precio unitario',
              flex: 2,
              numerica: true,
              celda: (m) => Text(m.precioUnitario.formateado),
            ),
            CfColumna(
              titulo: 'Estado',
              flex: 2,
              celda: (m) => etiquetaEstado(activo: m.activo, femenino: false),
            ),
          ],
          acciones: (m) => [
            CfAccionFila(
              clave: MaterialesTab.claveEditar(m.id),
              etiqueta: 'Editar',
              icono: Icons.edit_outlined,
              onPressed: _enCurso.contains(m.id)
                  ? null
                  : () => _abrirFormulario(m),
            ),
            CfAccionFila(
              clave: MaterialesTab.claveEstado(m.id),
              etiqueta: m.activo ? 'Desactivar' : 'Activar',
              icono: m.activo
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              peligro: m.activo,
              cargando: _enCurso.contains(m.id),
              onPressed: () => _cambiarEstado(m),
            ),
          ],
        ),
      ],
    );
  }
}
