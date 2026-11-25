import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/cf_tokens.dart';
import 'cf_data_table.dart';
import 'cf_empty_state.dart';
import 'cf_tag.dart';

/// Imagen remota con un marcador mientras carga o si falla [RNF-05].
///
/// Si [url] es `null`, muestra el marcador «sin imagen».
class CfMiniatura extends StatelessWidget {
  const CfMiniatura({
    required this.url,
    required this.descripcion,
    this.tamano,
    this.radio,
    super.key,
  });

  final String? url;

  /// Texto alternativo de la imagen.
  final String descripcion;

  /// Lado del cuadrado; si es `null`, ocupa el espacio disponible.
  final double? tamano;
  final double? radio;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    Widget marcador(IconData icono) => Container(
      color: AppColors.secundario.withValues(alpha: 0.35),
      alignment: Alignment.center,
      child: Icon(
        icono,
        size: tamano == null ? 32 : tamano! * 0.45,
        color: AppColors.texto.withValues(alpha: 0.6),
      ),
    );

    final Widget contenido = url == null
        ? Semantics(
            label: '$descripcion: sin imagen',
            child: marcador(Icons.image_outlined),
          )
        : Image.network(
            url!,
            fit: BoxFit.cover,
            semanticLabel: descripcion,
            // Si el navegador no permite leer la imagen por CORS, se usa un
            // elemento <img>.
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            loadingBuilder: (context, hijo, progreso) =>
                progreso == null ? hijo : marcador(Icons.image_outlined),
            errorBuilder: (context, error, pila) => Semantics(
              label: '$descripcion: no se pudo cargar',
              child: marcador(Icons.broken_image_outlined),
            ),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radio ?? tokens.radioSm),
      child: SizedBox(width: tamano, height: tamano, child: contenido),
    );
  }
}

/// Elemento de [CfGalleria].
class CfGaleriaItem {
  const CfGaleriaItem({
    required this.url,
    required this.descripcion,
    this.insignia,
    this.acciones = const [],
    this.clave,
  });

  final String url;
  final String descripcion;

  /// Etiqueta destacada sobre la imagen (por ejemplo, «Portada»).
  final String? insignia;

  /// Botones de ícono bajo la imagen (mover, borrar…).
  final List<CfAccionFila> acciones;
  final Key? clave;
}

/// Cuadrícula de imágenes al estilo de Galleria/DataView de PrimeNG
/// [RNF-05][RF-04]. Calcula las columnas según el ancho disponible.
class CfGalleria extends StatelessWidget {
  const CfGalleria({
    required this.items,
    this.textoVacio = 'Aún no hay imágenes',
    this.mensajeVacio,
    this.anchoMinimo = 200,
    super.key,
  });

  final List<CfGaleriaItem> items;
  final String textoVacio;
  final String? mensajeVacio;

  /// Ancho mínimo de cada miniatura.
  final double anchoMinimo;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    if (items.isEmpty) {
      return CfEmptyState(
        icon: Icons.photo_library_outlined,
        title: textoVacio,
        message: mensajeVacio,
      );
    }
    return LayoutBuilder(
      builder: (context, restricciones) {
        final separacion = tokens.espacioMd;
        final columnas = math.max(
          1,
          ((restricciones.maxWidth + separacion) / (anchoMinimo + separacion))
              .floor(),
        );
        final ancho =
            (restricciones.maxWidth - separacion * (columnas - 1)) / columnas;
        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                key: items[i].clave,
                width: ancho,
                child: _Elemento(
                  item: items[i],
                  posicion: i + 1,
                  total: items.length,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Elemento extends StatelessWidget {
  const _Elemento({
    required this.item,
    required this.posicion,
    required this.total,
  });

  final CfGaleriaItem item;
  final int posicion;
  final int total;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    return Semantics(
      container: true,
      label: '${item.descripcion}, $posicion de $total',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blanco,
          borderRadius: BorderRadius.circular(tokens.radioLg),
          border: Border.all(
            color: item.insignia != null ? AppColors.primario : AppColors.borde,
            width: item.insignia != null ? 2 : 1,
          ),
          boxShadow: tokens.sombra,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CfMiniatura(
                      url: item.url,
                      descripcion: item.descripcion,
                      radio: 0,
                    ),
                  ),
                  if (item.insignia != null)
                    Positioned(
                      top: tokens.espacioSm,
                      left: tokens.espacioSm,
                      child: CfTag(
                        label: item.insignia!,
                        severity: CfTagSeverity.primary,
                        icon: Icons.star_rounded,
                        rounded: true,
                      ),
                    ),
                ],
              ),
            ),
            if (item.acciones.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(tokens.espacioXs),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    for (final a in item.acciones)
                      IconButton(
                        key: a.clave,
                        tooltip: a.etiqueta,
                        color: a.peligro
                            ? AppColors.primario
                            : AppColors.complementario,
                        onPressed: a.cargando ? null : a.onPressed,
                        icon: a.cargando
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(a.icono),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
