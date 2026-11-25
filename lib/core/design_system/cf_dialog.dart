import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/cf_tokens.dart';

/// Diálogo al estilo del Dialog de PrimeNG: encabezado con título y botón
/// «Cerrar», cuerpo desplazable y pie con las acciones [RNF-05].
///
/// En pantallas estrechas ocupa casi todo el ancho.
class CfDialog extends StatelessWidget {
  const CfDialog({
    required this.titulo,
    required this.child,
    this.subtitulo,
    this.acciones = const [],
    this.cerrable = true,
    this.anchoMaximo = 560,
    super.key,
  });

  final String titulo;
  final String? subtitulo;
  final Widget child;

  /// Botones del pie (normalmente `CfButton`), alineados a la derecha.
  final List<Widget> acciones;

  /// Si es `false`, el botón «Cerrar» queda deshabilitado (por ejemplo,
  /// mientras se guarda).
  final bool cerrable;
  final double anchoMaximo;

  static const claveCerrar = ValueKey('cf-dialog-cerrar');

  /// Abre un diálogo que solo se cierra con sus botones.
  static Future<R?> mostrar<R>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) => showDialog<R>(
    context: context,
    barrierDismissible: false,
    builder: builder,
  );

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    final estrecho = MediaQuery.sizeOf(context).width < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: estrecho ? tokens.espacioMd : tokens.espacioXl,
        vertical: tokens.espacioXl,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximo),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.espacioXl,
                tokens.espacioLg,
                tokens.espacioSm,
                tokens.espacioSm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: tokens.espacioSm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(titulo, style: textos.titleLarge),
                          ),
                          if (subtitulo != null)
                            Text(subtitulo!, style: textos.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    key: claveCerrar,
                    tooltip: 'Cerrar',
                    color: AppColors.texto,
                    onPressed: cerrable
                        ? () => Navigator.of(context).pop()
                        : null,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(tokens.espacioXl),
                child: child,
              ),
            ),
            if (acciones.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.all(tokens.espacioLg),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: tokens.espacioSm,
                  runSpacing: tokens.espacioSm,
                  children: acciones,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
