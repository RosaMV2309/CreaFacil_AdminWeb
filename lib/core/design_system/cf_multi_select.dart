import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/cf_tokens.dart';
import 'cf_tag.dart';

/// Opción de [CfMultiSelect].
class CfOpcionMultiple<T> {
  const CfOpcionMultiple(this.valor, this.etiqueta, {this.nota});

  final T valor;
  final String etiqueta;

  /// Etiqueta secundaria (por ejemplo, «inactivo»).
  final String? nota;
}

/// Selección múltiple al estilo del MultiSelect de PrimeNG [RNF-05].
///
/// Se muestra como una lista de casillas siempre visible (con un alto
/// máximo y desplazamiento): dentro de un diálogo es más accesible con el
/// teclado y el lector de pantalla que un desplegable superpuesto.
class CfMultiSelect<T> extends StatelessWidget {
  const CfMultiSelect({
    required this.label,
    required this.opciones,
    required this.seleccionados,
    required this.onChanged,
    this.ayuda,
    this.errorText,
    this.textoVacio = 'No hay opciones disponibles.',
    this.alturaMaxima = 240,
    super.key,
  });

  final String label;
  final List<CfOpcionMultiple<T>> opciones;
  final Set<T> seleccionados;

  /// Si es `null`, la lista queda deshabilitada.
  final ValueChanged<Set<T>>? onChanged;
  final String? ayuda;
  final String? errorText;
  final String textoVacio;
  final double alturaMaxima;

  static ValueKey<String> claveOpcion(Object? valor) =>
      ValueKey('cf-multi-$valor');

  void _alternar(T valor, bool marcado) {
    final nuevos = {...seleccionados};
    marcado ? nuevos.add(valor) : nuevos.remove(valor);
    onChanged?.call(nuevos);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    final n = seleccionados.length;
    final error = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: textos.titleSmall)),
            Text(
              n == 1 ? '1 seleccionado' : '$n seleccionados',
              style: textos.bodySmall,
            ),
          ],
        ),
        SizedBox(height: tokens.espacioSm),
        // Material propio para que las casillas pinten su efecto de toque.
        Material(
          color: AppColors.blanco,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radioSm),
            side: BorderSide(
              color: error ? AppColors.primario : AppColors.borde,
              width: error ? 1.5 : 1,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: alturaMaxima),
            child: opciones.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(tokens.espacioLg),
                    child: Text(textoVacio, style: textos.bodyMedium),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: tokens.espacioXs),
                    children: [
                      for (final o in opciones)
                        CheckboxListTile(
                          key: claveOpcion(o.valor),
                          value: seleccionados.contains(o.valor),
                          onChanged: onChanged == null
                              ? null
                              : (v) => _alternar(o.valor, v ?? false),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.primario,
                          checkColor: AppColors.blanco,
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  o.etiqueta,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (o.nota != null) ...[
                                SizedBox(width: tokens.espacioSm),
                                CfTag(label: o.nota!, rounded: true),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        if (errorText != null || ayuda != null) ...[
          SizedBox(height: tokens.espacioXs),
          Text(
            errorText ?? ayuda!,
            // El error usa el mismo estilo que los campos de texto del tema.
            style: error
                ? Theme.of(context).inputDecorationTheme.errorStyle
                : textos.bodySmall,
          ),
        ],
      ],
    );
  }
}
