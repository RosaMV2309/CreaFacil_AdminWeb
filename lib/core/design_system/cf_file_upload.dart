import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/cf_tokens.dart';
import 'cf_button.dart';

/// Zona de carga de archivos al estilo del FileUpload de PrimeNG
/// [RNF-05][RF-04].
///
/// Solo es la interfaz: el archivo lo elige quien recibe [onElegir]. Muestra
/// la ayuda (formatos y tamaño), el motivo si está deshabilitado y una barra
/// de progreso mientras se envía.
class CfFileUpload extends StatelessWidget {
  const CfFileUpload({
    required this.onElegir,
    this.titulo = 'Subir una imagen',
    this.textoBoton = 'Elegir imagen',
    this.ayuda,
    this.motivoDeshabilitado,
    this.progreso,
    super.key,
  });

  /// Abre el selector. Si es `null`, el botón queda deshabilitado.
  final VoidCallback? onElegir;
  final String titulo;
  final String textoBoton;
  final String? ayuda;

  /// Explica por qué no se puede subir (por ejemplo, el límite de fotos).
  final String? motivoDeshabilitado;

  /// Progreso del envío entre 0 y 1; `null` si no se está enviando nada.
  final double? progreso;

  static const claveBoton = ValueKey('cf-file-upload-boton');
  static const claveProgreso = ValueKey('cf-file-upload-progreso');
  static const claveMotivo = ValueKey('cf-file-upload-motivo');

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    final valor = progreso?.clamp(0.0, 1.0);
    final enviando = valor != null;
    final porcentaje = enviando ? (valor * 100).round() : 0;

    return Container(
      padding: EdgeInsets.all(tokens.espacioXl),
      decoration: BoxDecoration(
        color: AppColors.fondo,
        borderRadius: BorderRadius.circular(tokens.radioLg),
        border: Border.all(
          color: enviando ? AppColors.primario : AppColors.borde,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 36,
              color: AppColors.complementario,
            ),
          ),
          SizedBox(height: tokens.espacioSm),
          Text(titulo, style: textos.titleMedium, textAlign: TextAlign.center),
          if (ayuda != null) ...[
            SizedBox(height: tokens.espacioXs),
            Text(ayuda!, style: textos.bodySmall, textAlign: TextAlign.center),
          ],
          SizedBox(height: tokens.espacioLg),
          CfButton(
            key: claveBoton,
            label: textoBoton,
            icon: Icons.add_photo_alternate_outlined,
            loading: enviando,
            onPressed: enviando || motivoDeshabilitado != null
                ? null
                : onElegir,
          ),
          if (motivoDeshabilitado != null) ...[
            SizedBox(height: tokens.espacioMd),
            Row(
              key: claveMotivo,
              mainAxisSize: MainAxisSize.min,
              children: [
                const ExcludeSemantics(
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.complementario,
                  ),
                ),
                SizedBox(width: tokens.espacioSm),
                Flexible(
                  child: Text(motivoDeshabilitado!, style: textos.bodyMedium),
                ),
              ],
            ),
          ],
          if (enviando) ...[
            SizedBox(height: tokens.espacioLg),
            Semantics(
              label: 'Progreso del envío',
              value: '$porcentaje %',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radioSm),
                child: LinearProgressIndicator(
                  key: claveProgreso,
                  value: valor,
                  minHeight: 8,
                  color: AppColors.primario,
                  backgroundColor: AppColors.secundario.withValues(alpha: 0.4),
                ),
              ),
            ),
            SizedBox(height: tokens.espacioXs),
            Text(
              valor < 1
                  ? 'Subiendo… $porcentaje %'
                  : 'Procesando en el servidor…',
              style: textos.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
