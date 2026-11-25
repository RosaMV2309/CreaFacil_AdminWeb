import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pestaña de [CfTabs].
class CfTab {
  const CfTab({required this.etiqueta, required this.contenido, this.icono});

  final String etiqueta;
  final IconData? icono;
  final Widget contenido;
}

/// Pestañas al estilo del Tabs de PrimeNG: texto en azul artesanal y
/// subrayado coral en la pestaña activa. Necesita una altura acotada.
class CfTabs extends StatefulWidget {
  const CfTabs({required this.tabs, this.indiceInicial = 0, super.key});

  final List<CfTab> tabs;
  final int indiceInicial;

  @override
  State<CfTabs> createState() => _CfTabsState();
}

class _CfTabsState extends State<CfTabs> with SingleTickerProviderStateMixin {
  late final TabController _controlador = TabController(
    length: widget.tabs.length,
    initialIndex: widget.indiceInicial,
    vsync: this,
  );

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.blanco,
          child: TabBar(
            controller: _controlador,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.complementario,
            unselectedLabelColor: AppColors.texto,
            labelStyle: textos.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: textos.titleSmall,
            indicatorColor: AppColors.primario,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: AppColors.borde,
            overlayColor: WidgetStatePropertyAll(
              AppColors.secundario.withValues(alpha: 0.3),
            ),
            tabs: [
              for (final t in widget.tabs)
                Tab(
                  height: 52,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (t.icono != null) ...[
                        Icon(t.icono, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(t.etiqueta),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _controlador,
            physics: const NeverScrollableScrollPhysics(),
            children: [for (final t in widget.tabs) t.contenido],
          ),
        ),
      ],
    );
  }
}
