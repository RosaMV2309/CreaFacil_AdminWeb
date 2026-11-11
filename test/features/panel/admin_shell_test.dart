import 'package:creafacil_admin/app.dart';
import 'package:creafacil_admin/core/design_system/cf_components.dart';
import 'package:creafacil_admin/core/router/app_router.dart';
import 'package:creafacil_admin/core/theme/app_colors.dart';
import 'package:creafacil_admin/features/panel/presentation/admin_shell.dart';
import 'package:creafacil_admin/features/panel/presentation/secciones_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/api_falsa.dart';
import '../../helpers/envolver.dart';

Future<ProviderContainer> montarPanel(WidgetTester tester, double ancho) async {
  fijarVentana(tester, ancho);
  final contenedor = ProviderContainer(overrides: apiConectada());
  addTearDown(contenedor.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: contenedor,
      child: const CreaFacilAdminApp(),
    ),
  );
  await tester.pumpAndSettle();
  return contenedor;
}

final riel = find.byKey(AdminShell.claveRiel);
final menu = find.byKey(AdminShell.claveMenu);

void main() {
  group('SeccionesPanel', () {
    test('las 7 secciones del DERCAS con su fase', () {
      expect(SeccionesPanel.todas.map((s) => (s.titulo, s.fase)), [
        ('Inicio', 0),
        ('Catálogo', 2),
        ('Precios', 3),
        ('Cotizaciones', 3),
        ('Solicitudes y pedidos', 4),
        ('Agenda', 5),
        ('Reportes', 7),
      ]);
      expect(SeccionesPanel.pendientes, isNot(contains(SeccionesPanel.inicio)));
    });

    test('indiceDe marca la sección según la ruta', () {
      expect(SeccionesPanel.indiceDe('/'), 0);
      expect(SeccionesPanel.indiceDe('/agenda'), 5);
      expect(SeccionesPanel.indiceDe('/catalogo/servicios/3'), 1);
      expect(SeccionesPanel.indiceDe('/catalogos'), 0);
      expect(SeccionesPanel.indiceDe('/desconocida'), 0);
    });
  });

  testWidgets('escritorio: riel extendido azul y cambio de sección', (
    tester,
  ) async {
    await montarPanel(tester, 1280);

    expect(riel, findsOneWidget);
    expect(menu, findsNothing);
    expect(find.byTooltip('Abrir el menú de navegación'), findsNothing);
    final rail = tester.widget<NavigationRail>(riel);
    expect(rail.extended, isTrue);
    expect(rail.selectedIndex, 0);
    expect(
      Theme.of(tester.element(riel)).navigationRailTheme.backgroundColor,
      AppColors.complementario,
    );
    expect(
      find.descendant(of: riel, matching: find.text('Solicitudes y pedidos')),
      findsOneWidget,
    );

    await tester.tap(find.descendant(of: riel, matching: find.text('Agenda')));
    await tester.pumpAndSettle();

    expect(tester.widget<NavigationRail>(riel).selectedIndex, 5);
    expect(find.byType(CfEmptyState), findsOneWidget);
    expect(find.textContaining('Disponible en la Fase 5.'), findsOneWidget);
  });

  testWidgets('tablet: riel compacto con etiquetas cortas', (tester) async {
    await montarPanel(tester, 768);

    final rail = tester.widget<NavigationRail>(riel);
    expect(rail.extended, isFalse);
    expect(rail.labelType, NavigationRailLabelType.all);

    await tester.tap(find.descendant(of: riel, matching: find.text('Pedidos')));
    await tester.pumpAndSettle();

    expect(find.text('Solicitudes y pedidos'), findsOneWidget);
    expect(find.textContaining('Disponible en la Fase 4.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('móvil: menú desplegable y cambio de sección', (tester) async {
    await montarPanel(tester, 375);

    expect(riel, findsNothing);
    expect(menu, findsNothing);

    await tester.tap(find.byTooltip('Abrir el menú de navegación'));
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    expect(
      find.descendant(of: menu, matching: find.byType(ListTile)),
      findsNWidgets(SeccionesPanel.todas.length),
    );

    await tester.tap(
      find.descendant(of: menu, matching: find.text('Cotizaciones')),
    );
    await tester.pumpAndSettle();

    expect(menu, findsNothing);
    expect(find.text('Cotizaciones'), findsOneWidget);
    expect(find.textContaining('Disponible en la Fase 3.'), findsOneWidget);

    // Al volver a abrir, la sección activa está marcada.
    await tester.tap(find.byTooltip('Abrir el menú de navegación'));
    await tester.pumpAndSettle();
    final activa = tester.widget<ListTile>(
      find.ancestor(
        of: find.descendant(of: menu, matching: find.text('Cotizaciones')),
        matching: find.byType(ListTile),
      ),
    );
    expect(activa.selected, isTrue);
  });

  for (final ancho in [375.0, 768.0, 1280.0]) {
    testWidgets('todas las secciones sin desbordes a ${ancho.toInt()} px', (
      tester,
    ) async {
      final contenedor = await montarPanel(tester, ancho);
      final router = contenedor.read(appRouterProvider);

      for (final seccion in SeccionesPanel.todas) {
        router.go(seccion.ruta);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: seccion.ruta);
        expect(find.byType(AdminShell), findsOneWidget);
        if (seccion != SeccionesPanel.inicio) {
          expect(
            find.textContaining(seccion.textoDisponibilidad),
            findsOneWidget,
          );
        }
      }
    });
  }
}
