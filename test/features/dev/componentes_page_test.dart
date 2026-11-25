import 'package:creafacil_admin/core/design_system/cf_components.dart';
import 'package:creafacil_admin/core/theme/app_theme.dart';
import 'package:creafacil_admin/features/dev/presentation/componentes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/envolver.dart';

Future<void> _montarCatalogo(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.claro(), home: const ComponentesPage()),
  );
  await tester.pump();
}

void main() {
  testWidgets('el catálogo muestra todas las variantes de los componentes', (
    tester,
  ) async {
    fijarVentana(tester, 1280, 4000);
    await _montarCatalogo(tester);

    expect(find.text('Catálogo de componentes'), findsOneWidget);
    expect(find.byType(CfButton), findsWidgets);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Secundario'), findsWidgets);
    expect(find.text('Contorno'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
    expect(find.byType(CfTag), findsNWidgets(8));
    expect(find.byType(CfMessage), findsNWidgets(4));
    expect(find.byType(CfSpinner), findsOneWidget);
    expect(find.byType(CfEmptyState), findsNWidgets(2));
    expect(find.byType(CfFileUpload), findsNWidgets(2));
    expect(find.byType(CfGalleria), findsNWidgets(2));
    expect(find.byType(CfMultiSelect<int>), findsOneWidget);
    expect(find.byType(CfErrorState), findsOneWidget);
    expect(find.byType(CfDataTable<(String, String)>), findsOneWidget);
    expect(find.byType(CfSelect<int>), findsOneWidget);
    expect(find.byType(CfTextarea), findsOneWidget);

    await tester.ensureVisible(find.text('Abrir diálogo'));
    await tester.tap(find.text('Abrir diálogo'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Contenido del formulario.'), findsOneWidget);
    await tester.tap(find.widgetWithText(CfButton, 'Cerrar'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Contenido del formulario.'), findsNothing);
    await tester.tap(find.byTooltip('Editar').first);
    await tester.pump();

    // Componentes de archivos y selección múltiple.
    await tester.ensureVisible(find.text('Barniz (litro)'));
    await tester.tap(find.text('Barniz (litro)'));
    await tester.pump();
    expect(find.text('2 seleccionados'), findsOneWidget);
    await tester.tap(find.text('Elegir imagen').first);
    await tester.tap(find.byTooltip('Mover a la derecha').first);
    await tester.tap(find.byTooltip('Borrar').first);
    await tester.pump();
  });

  testWidgets('el botón de carga del catálogo cambia de estado', (
    tester,
  ) async {
    fijarVentana(tester, 1280, 4000);
    await _montarCatalogo(tester);

    await tester.tap(find.text('Probar carga'));
    await tester.pump();
    expect(find.text('Guardando'), findsOneWidget);

    await tester.tap(find.text('Detener carga'));
    await tester.pump();
    expect(find.text('Probar carga'), findsOneWidget);
  });

  for (final ancho in [375.0, 768.0, 1280.0]) {
    testWidgets('el catálogo se adapta sin desbordes a ${ancho.toInt()} px', (
      tester,
    ) async {
      fijarVentana(tester, ancho);
      await _montarCatalogo(tester);

      expect(tester.takeException(), isNull);

      // Recorre todo el catálogo para construir y revisar cada sección.
      final desplazable = find.byType(Scrollable).first;
      for (var i = 0; i < 12; i++) {
        await tester.drag(desplazable, const Offset(0, -600));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
