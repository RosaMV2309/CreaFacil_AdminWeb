import 'package:flutter/material.dart';

import '../../../core/design_system/cf_components.dart';
import 'secciones_panel.dart';

/// Marcador de una sección del panel que se implementará más adelante.
class SeccionPendientePage extends StatelessWidget {
  const SeccionPendientePage({required this.seccion, super.key});

  final SeccionPanel seccion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: CfEmptyState(
          icon: seccion.icono,
          title: seccion.titulo,
          message: '${seccion.textoDisponibilidad}\n${seccion.descripcion}',
        ),
      ),
    );
  }
}
