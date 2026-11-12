import 'package:creafacil_admin/app.dart';
import 'package:creafacil_admin/core/widgets/cf_logo.dart';
import 'package:creafacil_admin/core/widgets/responsive_layout.dart';
import 'package:creafacil_admin/features/estado_api/presentation/estado_api_tarjeta.dart';
import 'package:creafacil_admin/features/inicio/presentation/inicio_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/api_falsa.dart';
import 'helpers/envolver.dart';

/// El panel con la API simulada «conectada» (las pruebas no usan la red).
Widget appDePrueba() =>
    ProviderScope(overrides: apiConectada(), child: const CreaFacilAdminApp());

final tarjetaBienvenida = find.byKey(InicioPage.claveBienvenida);

void main() {
  testWidgets('muestra el inicio del panel administrativo', (tester) async {
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    expect(find.text('Panel administrativo'), findsOneWidget);
  });

  testWidgets('el panel acepta una clave propia', (tester) async {
    final clave = UniqueKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: apiConectada(),
        child: CreaFacilAdminApp(key: clave),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(clave), findsOneWidget);
    expect(find.text('Panel administrativo'), findsOneWidget);
  });

  testWidgets('la bienvenida muestra el logotipo completo de CreaFácil', (
    tester,
  ) async {
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    final enTarjeta = find.descendant(
      of: tarjetaBienvenida,
      matching: find.byType(CfLogo),
    );
    expect(enTarjeta, findsOneWidget);
    expect(tester.widget<CfLogo>(enTarjeta).variant, CfLogoVariant.completo);
    expect(
      find.descendant(of: enTarjeta, matching: find.byType(Image)),
      findsOneWidget,
    );
  });

  testWidgets('la cabecera del panel muestra la ilustración y «CreaFácil»', (
    tester,
  ) async {
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    final encabezado = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(CfMarcaEncabezado),
    );
    expect(encabezado, findsOneWidget);
    final icono = find.descendant(
      of: encabezado,
      matching: find.byType(CfLogo),
    );
    expect(tester.widget<CfLogo>(icono).variant, CfLogoVariant.icono);
    expect(
      find.descendant(of: encabezado, matching: find.text('CreaFácil')),
      findsOneWidget,
    );
  });

  testWidgets('el dashboard muestra el estado de la API', (tester) async {
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    expect(find.byType(EstadoApiTarjeta), findsOneWidget);
    expect(find.text(EstadoApiTarjeta.textoConectado), findsOneWidget);
  });

  testWidgets('«Gestionar el catálogo» abre la sección Catálogo', (
    tester,
  ) async {
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gestionar el catálogo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Disponible en la Fase 2.'), findsOneWidget);
  });

  testWidgets('en modo debug abre el catálogo de componentes', (tester) async {
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver componentes'));
    // El catálogo tiene un CfSpinner animado: no se usa pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Catálogo de componentes'), findsOneWidget);
  });

  for (final ancho in [360.0, 375.0, 768.0, 1280.0]) {
    testWidgets('el inicio se adapta sin desbordes a ${ancho.toInt()} px', (
      tester,
    ) async {
      fijarVentana(tester, ancho);

      await tester.pumpWidget(appDePrueba());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final tarjeta in [
        tester.getRect(tarjetaBienvenida),
        tester.getRect(find.byType(EstadoApiTarjeta)),
      ]) {
        expect(tarjeta.left, greaterThanOrEqualTo(0));
        expect(tarjeta.right, lessThanOrEqualTo(ancho));
      }

      // El logotipo completo cabe en la tarjeta y cambia de tamaño.
      final tarjeta = tester.getRect(tarjetaBienvenida);
      final logo = tester.getRect(
        find.descendant(of: tarjetaBienvenida, matching: find.byType(CfLogo)),
      );
      expect(logo.left, greaterThanOrEqualTo(tarjeta.left));
      expect(logo.right, lessThanOrEqualTo(tarjeta.right));
      expect(logo.width, InicioPage.tamanoLogo(PuntosCorte.de(ancho)));
    });
  }
}
