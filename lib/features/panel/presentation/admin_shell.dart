import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/cf_tokens.dart';
import '../../../core/widgets/cf_logo.dart';
import '../../../core/widgets/responsive_layout.dart';
import 'secciones_panel.dart';

/// Estructura del panel administrativo con navegación adaptable [RNF-05]:
///
/// - Escritorio (≥ 1024 px): riel lateral extendido con los nombres.
/// - Tablet (600 a 1023 px): riel compacto con ícono y etiqueta corta.
/// - Móvil (< 600 px): menú desplegable (Drawer) desde el encabezado.
///
/// La navegación usa el azul artesanal y el encabezado la marca de CreaFácil.
class AdminShell extends StatelessWidget {
  const AdminShell({required this.ubicacion, required this.child, super.key});

  /// Ruta actual, para marcar la sección activa.
  final String ubicacion;

  /// Contenido de la sección.
  final Widget child;

  static const claveRiel = ValueKey('panel-riel');
  static const claveMenu = ValueKey('panel-menu');

  @override
  Widget build(BuildContext context) {
    final tamano = PuntosCorte.deContexto(context);
    final indice = SeccionesPanel.indiceDe(ubicacion);
    void ir(int i) => context.go(SeccionesPanel.todas[i].ruta);

    if (tamano == TamanoPantalla.movil) {
      return Scaffold(
        appBar: AppBar(title: const CfMarcaEncabezado()),
        drawer: _MenuDesplegable(indice: indice, alElegir: ir),
        body: child,
      );
    }

    final extendido = tamano == TamanoPantalla.escritorio;
    return Scaffold(
      appBar: AppBar(title: const CfMarcaEncabezado()),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationRail(
            key: claveRiel,
            extended: extendido,
            minWidth: 96,
            minExtendedWidth: 264,
            labelType: extendido
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            selectedIndex: indice,
            onDestinationSelected: ir,
            destinations: [
              for (final s in SeccionesPanel.todas)
                NavigationRailDestination(
                  icon: Icon(s.icono),
                  selectedIcon: Icon(s.iconoSeleccionado),
                  label: Text(extendido ? s.titulo : s.etiquetaCorta),
                ),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Menú lateral desplegable para móvil, en azul artesanal.
class _MenuDesplegable extends StatelessWidget {
  const _MenuDesplegable({required this.indice, required this.alElegir});

  final int indice;
  final ValueChanged<int> alElegir;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;

    return Drawer(
      key: AdminShell.claveMenu,
      child: SafeArea(
        child: ListTileTheme(
          // Blanco sobre azul (≈ 9,6:1); la sección activa en pastel con
          // texto principal (≈ 5:1). Todo dentro de la paleta.
          textColor: AppColors.blanco,
          iconColor: AppColors.blanco.withValues(alpha: 0.85),
          selectedColor: AppColors.texto,
          selectedTileColor: AppColors.secundario,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radioMd),
          ),
          child: ListView(
            padding: EdgeInsets.all(tokens.espacioMd),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.espacioSm,
                  tokens.espacioSm,
                  tokens.espacioSm,
                  tokens.espacioLg,
                ),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: CfMarcaEncabezado(),
                ),
              ),
              Divider(color: AppColors.blanco.withValues(alpha: 0.2)),
              SizedBox(height: tokens.espacioSm),
              for (var i = 0; i < SeccionesPanel.todas.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.espacioXs),
                  child: ListTile(
                    selected: i == indice,
                    leading: Icon(
                      i == indice
                          ? SeccionesPanel.todas[i].iconoSeleccionado
                          : SeccionesPanel.todas[i].icono,
                      color: i == indice ? AppColors.complementario : null,
                    ),
                    title: Text(
                      SeccionesPanel.todas[i].titulo,
                      style: textos.titleSmall?.copyWith(
                        color: i == indice ? AppColors.texto : AppColors.blanco,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      alElegir(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
