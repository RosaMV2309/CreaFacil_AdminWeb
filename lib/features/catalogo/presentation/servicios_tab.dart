import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/cf_components.dart';
import '../../../core/network/red.dart';
import '../domain/entidades_catalogo.dart';
import '../domain/servicios.dart';
import 'catalogo_providers.dart';
import 'servicios_providers.dart';
import 'widgets/comunes_catalogo.dart';
import 'widgets/formulario_servicio.dart';
import 'widgets/fotos_servicio.dart';

/// Gestión de servicios: tabla paginada con portada, categoría, precio
/// referencial, fotos y estado; búsqueda, filtros, alta, edición, fotos y
/// activar o desactivar [RF-22][RF-05][RF-04].
class ServiciosTab extends ConsumerStatefulWidget {
  const ServiciosTab({super.key});

  static const claveNuevo = ValueKey('servicios-nuevo');
  static const claveFiltroCategoria = ValueKey('servicios-filtro-categoria');
  static const claveFiltroEstado = ValueKey('servicios-filtro-estado');
  static const claveAviso = ValueKey('servicios-aviso');

  static const avisoCategoriaInactiva =
      'Categoría inactiva: no se ve en el catálogo';

  static ValueKey<String> claveFila(String id) => ValueKey('servicio-$id');
  static ValueKey<String> claveEditar(String id) =>
      ValueKey('servicio-editar-$id');
  static ValueKey<String> claveFotos(String id) =>
      ValueKey('servicio-fotos-$id');
  static ValueKey<String> claveEstado(String id) =>
      ValueKey('servicio-estado-$id');

  /// «Desde $ 120,50» o «—» (RN-01: el precio es referencial).
  static String textoPrecio(ServicioResumen s) =>
      s.precioBaseReferencial == null
      ? '—'
      : 'Desde ${s.precioBaseReferencial!.formateado}';

  @override
  ConsumerState<ServiciosTab> createState() => _ServiciosTabState();
}

class _ServiciosTabState extends ConsumerState<ServiciosTab> {
  final _enCurso = <String>{};
  AvisoCatalogo? _aviso;

  ServiciosController get _controlador =>
      ref.read(serviciosControllerProvider.notifier);

  Future<void> _nuevo() async {
    final guardado = await FormularioServicio.abrir(context);
    if (guardado != null && mounted) {
      setState(
        () => _aviso = AvisoCatalogo(
          'Se creó el servicio «${guardado.nombre}». Ahora puedes subir sus '
          'fotos con «Fotos».',
        ),
      );
    }
  }

  Future<void> _editar(ServicioResumen servicio) async {
    if (_enCurso.contains(servicio.id)) {
      return;
    }
    setState(() {
      _enCurso.add(servicio.id);
      _aviso = null;
    });
    ServicioDetalle? detalle;
    AvisoCatalogo? aviso;
    try {
      detalle = await _controlador.obtener(servicio.id);
    } on ApiException catch (error) {
      aviso = AvisoCatalogo.desdeError(error);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _enCurso.remove(servicio.id);
      _aviso = aviso;
    });
    if (detalle == null) {
      return;
    }
    final guardado = await FormularioServicio.abrir(context, servicio: detalle);
    if (guardado != null && mounted) {
      setState(
        () => _aviso = AvisoCatalogo(
          'Se guardaron los cambios de «${guardado.nombre}».',
        ),
      );
    }
  }

  Future<void> _fotos(ServicioResumen servicio) async {
    setState(() => _aviso = null);
    await FotosServicio.abrir(context, servicio: servicio);
    // La portada y el número de fotos pueden haber cambiado.
    await _controlador.recargar();
  }

  Future<void> _cambiarEstado(ServicioResumen servicio) async {
    if (_enCurso.contains(servicio.id)) {
      return;
    }
    final activar = !servicio.activo;
    final confirmar = await CfConfirmDialog.mostrar(
      context,
      titulo: activar ? 'Activar el servicio' : 'Desactivar el servicio',
      mensaje: activar
          ? '«${servicio.nombre}» volverá a verse en el catálogo'
                '${servicio.categoria.activa ? '' : ' cuando actives su categoría'}.'
          : '«${servicio.nombre}» dejará de verse en el catálogo. No se borra: '
                'podrás activarlo de nuevo cuando quieras.',
      textoConfirmar: activar ? 'Activar' : 'Desactivar',
      peligro: !activar,
    );
    if (!confirmar || !mounted) {
      return;
    }
    setState(() {
      _enCurso.add(servicio.id);
      _aviso = null;
    });
    AvisoCatalogo aviso;
    try {
      final r = await _controlador.cambiarEstado(servicio, activo: activar);
      aviso = AvisoCatalogo(
        r.activo
            ? 'El servicio «${r.nombre}» está activo.'
            : 'El servicio «${r.nombre}» está desactivado.',
      );
    } on ApiException catch (error) {
      aviso = AvisoCatalogo.desdeError(error);
    }
    if (mounted) {
      setState(() {
        _enCurso.remove(servicio.id);
        _aviso = aviso;
      });
    }
  }

  List<CfOpcion<String>> _opcionesCategoria(
    List<Categoria> categorias,
    String seleccionada,
  ) => [
    const CfOpcion(FiltroServicios.todas, 'Todas las categorías'),
    for (final c in categorias)
      CfOpcion(c.id, c.activa ? c.nombre : '${c.nombre} (inactiva)'),
    // El valor elegido debe estar siempre entre las opciones.
    if (seleccionada != FiltroServicios.todas &&
        !categorias.any((c) => c.id == seleccionada))
      CfOpcion(seleccionada, 'Categoría elegida'),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final estado = ref.watch(serviciosControllerProvider);
    final filtro = ref.watch(filtroServiciosProvider);
    final filtroNotifier = ref.read(filtroServiciosProvider.notifier);
    final categorias = ref.watch(opcionesCategoriasProvider).value ?? const [];
    final pagina = estado.value;
    final error = estado.error;
    final sinFiltros =
        filtro.q.isEmpty &&
        filtro.categoriaId == FiltroServicios.todas &&
        filtro.estado == FiltroEstado.todos;

    return PaginaCatalogo(
      children: [
        EncabezadoCatalogo(
          titulo: 'Servicios',
          descripcion:
              'Lo que ve el cliente en el catálogo. Un servicio desactivado '
              '(o de una categoría inactiva) no aparece en el catálogo.',
          accion: CfButton(
            key: ServiciosTab.claveNuevo,
            label: 'Nuevo servicio',
            icon: Icons.add_rounded,
            onPressed: _nuevo,
          ),
        ),
        SizedBox(height: tokens.espacioXl),
        BarraFiltros(
          etiquetaBusqueda: 'Buscar por nombre',
          textoInicial: filtro.q,
          onBuscar: filtroNotifier.buscar,
          filtroExtra: CfSelect<String>(
            key: ServiciosTab.claveFiltroCategoria,
            label: 'Categoría',
            valor: filtro.categoriaId,
            opciones: _opcionesCategoria(categorias, filtro.categoriaId),
            onChanged: filtroNotifier.filtrarPorCategoria,
          ),
          filtro: CfSelect<FiltroEstado>(
            key: ServiciosTab.claveFiltroEstado,
            label: 'Estado',
            valor: filtro.estado,
            opciones: opcionesEstado(femenino: false),
            onChanged: filtroNotifier.filtrarPorEstado,
          ),
        ),
        SizedBox(height: tokens.espacioLg),
        if (_aviso != null) ...[
          _aviso!.mostrar(
            key: ServiciosTab.claveAviso,
            onClose: () => setState(() => _aviso = null),
          ),
          SizedBox(height: tokens.espacioLg),
        ],
        CfDataTable<ServicioResumen>(
          etiqueta: 'Tabla de servicios',
          filas: pagina?.datos ?? const [],
          cargando: estado.isLoading,
          error: error == null
              ? null
              : (error is ApiException
                    ? error.mensaje
                    : 'No se pudo cargar la lista de servicios.'),
          onReintentar: _controlador.recargar,
          tituloVacio: sinFiltros
              ? 'Aún no hay servicios'
              : 'Ningún servicio coincide',
          mensajeVacio: 'Crea uno con «Nuevo servicio» o cambia los filtros.',
          claveFila: (s) => ServiciosTab.claveFila(s.id),
          anchoAcciones: 156,
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
              titulo: 'Portada',
              flex: 2,
              celda: (s) => Align(
                alignment: Alignment.centerLeft,
                child: CfMiniatura(
                  url: s.portadaUrl,
                  descripcion: 'Portada de ${s.nombre}',
                  tamano: 48,
                ),
              ),
            ),
            CfColumna(
              titulo: 'Nombre',
              flex: 3,
              celda: (s) => Text(
                s.nombre,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            CfColumna(
              titulo: 'Categoría',
              flex: 3,
              celda: (s) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.categoria.nombre),
                  if (!s.categoria.activa) ...[
                    SizedBox(height: tokens.espacioXs),
                    const CfTag(
                      label: ServiciosTab.avisoCategoriaInactiva,
                      severity: CfTagSeverity.warning,
                    ),
                  ],
                ],
              ),
            ),
            CfColumna(
              titulo: 'Precio referencial',
              flex: 2,
              numerica: true,
              celda: (s) => Text(ServiciosTab.textoPrecio(s)),
            ),
            CfColumna(
              titulo: 'Fotos',
              numerica: true,
              celda: (s) =>
                  Text('${s.numeroFotos} de ${ValidacionesServicio.maxFotos}'),
            ),
            CfColumna(
              titulo: 'Estado',
              flex: 2,
              celda: (s) => etiquetaEstado(activo: s.activo, femenino: false),
            ),
          ],
          acciones: (s) => [
            CfAccionFila(
              clave: ServiciosTab.claveEditar(s.id),
              etiqueta: 'Editar',
              icono: Icons.edit_outlined,
              cargando: _enCurso.contains(s.id),
              onPressed: () => _editar(s),
            ),
            CfAccionFila(
              clave: ServiciosTab.claveFotos(s.id),
              etiqueta: 'Fotos',
              icono: Icons.photo_library_outlined,
              onPressed: _enCurso.contains(s.id) ? null : () => _fotos(s),
            ),
            CfAccionFila(
              clave: ServiciosTab.claveEstado(s.id),
              etiqueta: s.activo ? 'Desactivar' : 'Activar',
              icono: s.activo
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              peligro: s.activo,
              onPressed: _enCurso.contains(s.id)
                  ? null
                  : () => _cambiarEstado(s),
            ),
          ],
        ),
      ],
    );
  }
}
