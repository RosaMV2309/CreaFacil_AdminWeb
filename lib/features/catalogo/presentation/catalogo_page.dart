import 'package:flutter/material.dart';

import '../../../core/design_system/cf_components.dart';
import 'categorias_tab.dart';
import 'materiales_tab.dart';

/// Sección «Catálogo» del panel con pestañas: Categorías, Materiales y
/// Servicios (la gestión de servicios llega en la subfase 2.4b) [RF-22].
class CatalogoPage extends StatelessWidget {
  const CatalogoPage({super.key});

  static const textoServicios = 'Disponible en la subfase 2.4b';

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: CfTabs(
        tabs: [
          CfTab(
            etiqueta: 'Categorías',
            icono: Icons.category_outlined,
            contenido: CategoriasTab(),
          ),
          CfTab(
            etiqueta: 'Materiales',
            icono: Icons.palette_outlined,
            contenido: MaterialesTab(),
          ),
          CfTab(
            etiqueta: 'Servicios',
            icono: Icons.design_services_outlined,
            contenido: Center(
              child: SingleChildScrollView(
                child: CfEmptyState(
                  icon: Icons.design_services_outlined,
                  title: 'Servicios',
                  message: '$textoServicios.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
