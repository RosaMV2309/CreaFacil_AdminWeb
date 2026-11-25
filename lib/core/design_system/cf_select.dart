import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/cf_tokens.dart';

/// Opción de [CfSelect].
class CfOpcion<T> {
  const CfOpcion(this.valor, this.etiqueta);

  final T valor;
  final String etiqueta;
}

/// Lista desplegable al estilo del Select de PrimeNG.
class CfSelect<T> extends StatelessWidget {
  const CfSelect({
    required this.label,
    required this.opciones,
    required this.valor,
    required this.onChanged,
    this.prefixIcon,
    this.hint,
    this.validator,
    this.errorText,
    super.key,
  });

  final String label;
  final List<CfOpcion<T>> opciones;
  final T valor;

  /// Si es `null`, el campo queda deshabilitado.
  final ValueChanged<T>? onChanged;
  final IconData? prefixIcon;

  /// Texto que se ve cuando [valor] es `null`.
  final String? hint;

  /// Validación dentro de un `Form`.
  final FormFieldValidator<T>? validator;

  /// Error externo (por ejemplo, el 400 del servidor).
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    return DropdownButtonFormField<T>(
      // La clave fuerza a mostrar el valor nuevo si cambia desde fuera.
      key: ValueKey(valor),
      initialValue: valor,
      isExpanded: true,
      dropdownColor: AppColors.blanco,
      borderRadius: BorderRadius.circular(tokens.radioSm),
      hint: hint == null ? null : Text(hint!, overflow: TextOverflow.ellipsis),
      validator: validator,
      forceErrorText: errorText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
      items: [
        for (final o in opciones)
          DropdownMenuItem<T>(
            value: o.valor,
            child: Text(o.etiqueta, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged == null ? null : (nuevo) => onChanged!(nuevo as T),
    );
  }
}
