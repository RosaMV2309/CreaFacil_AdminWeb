import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Área de texto al estilo del Textarea de PrimeNG, con etiqueta, ayuda,
/// validación en el cliente y error del servidor ([errorText]).
class CfTextarea extends StatelessWidget {
  const CfTextarea({
    required this.label,
    this.controller,
    this.helper,
    this.errorText,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.minLines = 3,
    this.maxLines = 6,
    this.enabled = true,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? helper;

  /// Error impuesto desde fuera (servidor). Tiene prioridad sobre [validator].
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  /// Longitud máxima que se deja escribir (sin contador visible).
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      validator: validator,
      forceErrorText: errorText,
      onChanged: onChanged,
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
        errorMaxLines: 3,
        alignLabelWithHint: true,
      ),
    );
  }
}
