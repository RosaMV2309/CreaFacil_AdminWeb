import 'package:flutter/material.dart';

import '../../../core/design_system/cf_components.dart';
import 'categorias_tab.dart';
import 'materiales_tab.dart';
import 'servicios_tab.dart';

/// Sección «Catálogo» del panel con pestañas: Categorías, Materiales y
/// Servicios (con sus fotos) [RF-22][RF-05][RF-04].
class CatalogoPage extends StatelessWidget {
  const CatalogoPage({super.key});

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
            contenido: ServiciosTab(),
          ),
        ],
      ),
    );
  }
}
