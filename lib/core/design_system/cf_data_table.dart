import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/cf_tokens.dart';
import 'cf_button.dart';
import 'cf_empty_state.dart';
import 'cf_error_state.dart';
import 'cf_spinner.dart';

/// Columna de [CfDataTable] (como `p-column` de PrimeNG).
class CfColumna<T> {
  const CfColumna({
    required this.titulo,
    required this.celda,
    this.flex = 1,
    this.numerica = false,
  });

  final String titulo;

  /// Contenido de la celda para una fila.
  final Widget Function(T fila) celda;

  /// Ancho relativo de la columna en la vista de tabla.
  final int flex;

  /// Alinea la celda a la derecha (números y precios).
  final bool numerica;
}

/// Acción de una fila: botón de ícono con tooltip en la tabla y botón con
/// texto en la vista de tarjetas.
class CfAccionFila {
  const CfAccionFila({
    required this.etiqueta,
    required this.icono,
    required this.onPressed,
    this.peligro = false,
    this.cargando = false,
    this.clave,
  });

  /// Texto del botón; en la tabla es el tooltip y la etiqueta accesible.
  final String etiqueta;
  final IconData icono;
  final VoidCallback? onPressed;
  final bool peligro;

  /// Muestra un indicador y bloquea el botón (sin envíos dobles).
  final bool cargando;
  final Key? clave;
}

/// Paginación de [CfDataTable] (como `p-paginator`).
class CfPaginacion {
  const CfPaginacion({
    required this.pagina,
    required this.totalPaginas,
    required this.total,
    required this.onCambiar,
  });

  final int pagina;
  final int totalPaginas;
  final int total;
  final ValueChanged<int> onCambiar;
}

/// Tabla de datos al estilo del DataTable de PrimeNG [RNF-05].
///
/// - Estados de carga, vacío y error con mensajes en español.
/// - Paginación opcional.
/// - Con menos de [anchoMinimoTabla] px disponibles se muestra como una
///   lista de tarjetas (una por fila) para que no haya desbordes en móvil.
class CfDataTable<T> extends StatelessWidget {
  const CfDataTable({
    required this.columnas,
    required this.filas,
    this.acciones,
    this.claveFila,
    this.cargando = false,
    this.error,
    this.onReintentar,
    this.tituloVacio = 'No hay registros',
    this.mensajeVacio,
    this.paginacion,
    this.etiqueta,
    this.anchoMinimoTabla = 600,
    this.anchoAcciones = 112,
    super.key,
  });

  final List<CfColumna<T>> columnas;
  final List<T> filas;

  /// Acciones de cada fila (editar, activar…).
  final List<CfAccionFila> Function(T fila)? acciones;

  /// Clave de cada fila o tarjeta (útil en pruebas).
  final Key Function(T fila)? claveFila;

  /// Muestra el indicador de carga (sobre las filas si ya había datos).
  final bool cargando;

  /// Mensaje de error; si se indica, sustituye a las filas.
  final String? error;
  final VoidCallback? onReintentar;
  final String tituloVacio;
  final String? mensajeVacio;
  final CfPaginacion? paginacion;

  /// Nombre accesible de la tabla.
  final String? etiqueta;
  final double anchoMinimoTabla;

  /// Ancho de la columna de acciones en la vista de tabla.
  final double anchoAcciones;

  static const claveCargando = ValueKey('cf-tabla-cargando');
  static const claveAnterior = ValueKey('cf-tabla-anterior');
  static const claveSiguiente = ValueKey('cf-tabla-siguiente');

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final Widget cuerpo;
    if (error != null) {
      cuerpo = CfErrorState(
        title: 'No se pudo cargar la información',
        message: error,
        onRetry: onReintentar,
      );
    } else if (filas.isEmpty && cargando) {
      cuerpo = Padding(
        padding: EdgeInsets.all(tokens.espacioXxl),
        child: const Center(child: CfSpinner(label: 'Cargando…')),
      );
    } else if (filas.isEmpty) {
      cuerpo = CfEmptyState(
        icon: Icons.search_off_rounded,
        title: tituloVacio,
        message: mensajeVacio,
      );
    } else {
      cuerpo = LayoutBuilder(
        builder: (context, restricciones) =>
            restricciones.maxWidth < anchoMinimoTabla
            ? _tarjetas(context)
            : _tabla(context),
      );
    }

    return Semantics(
      container: true,
      label: etiqueta,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cargando && filas.isNotEmpty && error == null)
            ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radioSm),
              child: LinearProgressIndicator(
                key: claveCargando,
                minHeight: 3,
                color: AppColors.primario,
                backgroundColor: AppColors.secundario.withValues(alpha: 0.5),
                semanticsLabel: 'Actualizando',
              ),
            ),
          cuerpo,
          if (paginacion != null && error == null && filas.isNotEmpty)
            _Paginador(paginacion: paginacion!, deshabilitado: cargando),
        ],
      ),
    );
  }

  Widget _tabla(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    final hayAcciones = acciones != null;

    Widget fila(List<Widget> celdas, {Widget? extra, Color? fondo}) =>
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.espacioLg,
            vertical: tokens.espacioSm,
          ),
          decoration: BoxDecoration(
            color: fondo,
            border: const Border(bottom: BorderSide(color: AppColors.borde)),
          ),
          child: Row(
            children: [
              ...celdas,
              if (hayAcciones) SizedBox(width: anchoAcciones, child: extra),
            ],
          ),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(tokens.radioLg),
        border: Border.all(color: AppColors.borde),
        boxShadow: tokens.sombra,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radioLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: fila(
                [
                  for (final c in columnas)
                    Expanded(
                      flex: c.flex,
                      child: Padding(
                        padding: EdgeInsets.only(right: tokens.espacioMd),
                        child: Text(
                          c.titulo,
                          textAlign: c.numerica
                              ? TextAlign.right
                              : TextAlign.left,
                          style: textos.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.complementario,
                          ),
                        ),
                      ),
                    ),
                ],
                extra: Text(
                  'Acciones',
                  textAlign: TextAlign.right,
                  style: textos.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.complementario,
                  ),
                ),
                fondo: AppColors.fondo,
              ),
            ),
            for (final f in filas)
              KeyedSubtree(
                key: claveFila?.call(f),
                child: Semantics(
                  container: true,
                  child: fila(
                    [
                      for (final c in columnas)
                        Expanded(
                          flex: c.flex,
                          child: Padding(
                            padding: EdgeInsets.only(right: tokens.espacioMd),
                            child: Align(
                              alignment: c.numerica
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: DefaultTextStyle.merge(
                                style: textos.bodyMedium,
                                child: c.celda(f),
                              ),
                            ),
                          ),
                        ),
                    ],
                    extra: hayAcciones
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              for (final a in acciones!(f)) _BotonIcono(a),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetas(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in filas)
          Padding(
            key: claveFila?.call(f),
            padding: EdgeInsets.only(bottom: tokens.espacioMd),
            child: Semantics(
              container: true,
              child: Container(
                padding: EdgeInsets.all(tokens.espacioLg),
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(tokens.radioLg),
                  border: Border.all(color: AppColors.borde),
                  boxShadow: tokens.sombra,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DefaultTextStyle.merge(
                      style: textos.titleSmall,
                      child: columnas.first.celda(f),
                    ),
                    SizedBox(height: tokens.espacioSm),
                    for (final c in columnas.skip(1))
                      Padding(
                        padding: EdgeInsets.only(top: tokens.espacioXs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 128,
                              child: Text(
                                c.titulo,
                                style: textos.labelMedium?.copyWith(
                                  color: AppColors.complementario,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: DefaultTextStyle.merge(
                                  style: textos.bodyMedium,
                                  child: c.celda(f),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (acciones != null) ...[
                      SizedBox(height: tokens.espacioSm),
                      Wrap(
                        spacing: tokens.espacioSm,
                        runSpacing: tokens.espacioSm,
                        children: [
                          for (final a in acciones!(f))
                            CfButton(
                              key: a.clave,
                              label: a.etiqueta,
                              icon: a.icono,
                              loading: a.cargando,
                              variant: a.peligro
                                  ? CfButtonVariant.danger
                                  : CfButtonVariant.outlined,
                              onPressed: a.onPressed,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BotonIcono extends StatelessWidget {
  const _BotonIcono(this.accion);

  final CfAccionFila accion;

  @override
  Widget build(BuildContext context) {
    if (accion.cargando) {
      return Semantics(
        key: accion.clave,
        label: '${accion.etiqueta}: en curso',
        child: const SizedBox.square(
          dimension: 48,
          child: Center(child: CfSpinner(size: 20)),
        ),
      );
    }
    return IconButton(
      key: accion.clave,
      tooltip: accion.etiqueta,
      onPressed: accion.onPressed,
      icon: Icon(accion.icono),
      color: accion.peligro ? AppColors.primario : AppColors.complementario,
    );
  }
}

class _Paginador extends StatelessWidget {
  const _Paginador({required this.paginacion, required this.deshabilitado});

  final CfPaginacion paginacion;
  final bool deshabilitado;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final p = paginacion;
    final total = p.totalPaginas < 1 ? 1 : p.totalPaginas;
    return Padding(
      padding: EdgeInsets.only(top: tokens.espacioMd),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: tokens.espacioSm,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              'Página ${p.pagina} de $total · ${p.total} '
              '${p.total == 1 ? 'registro' : 'registros'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            key: CfDataTable.claveAnterior,
            tooltip: 'Página anterior',
            color: AppColors.complementario,
            onPressed: deshabilitado || p.pagina <= 1
                ? null
                : () => p.onCambiar(p.pagina - 1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            key: CfDataTable.claveSiguiente,
            tooltip: 'Página siguiente',
            color: AppColors.complementario,
            onPressed: deshabilitado || p.pagina >= total
                ? null
                : () => p.onCambiar(p.pagina + 1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
