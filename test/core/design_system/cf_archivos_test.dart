import 'package:creafacil_admin/core/design_system/cf_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/envolver.dart';

void main() {
  group('CfFileUpload', () {
    testWidgets(
      'elige, muestra el progreso y el motivo si está deshabilitado',
      (tester) async {
        var elegido = 0;
        await montar(
          tester,
          CfFileUpload(ayuda: 'JPG o PNG', onElegir: () => elegido++),
        );
        expect(find.text('JPG o PNG'), findsOneWidget);
        await tester.tap(find.byKey(CfFileUpload.claveBoton));
        expect(elegido, 1);

        await montar(tester, CfFileUpload(progreso: 0.42, onElegir: () {}));
        expect(find.byKey(CfFileUpload.claveProgreso), findsOneWidget);
        expect(find.text('Subiendo… 42 %'), findsOneWidget);
        await montar(tester, CfFileUpload(progreso: 1, onElegir: () {}));
        expect(find.text('Procesando en el servidor…'), findsOneWidget);

        await montar(
          tester,
          CfFileUpload(
            motivoDeshabilitado: 'Ya hay 8 fotos.',
            onElegir: () => elegido++,
          ),
        );
        expect(find.byKey(CfFileUpload.claveMotivo), findsOneWidget);
        await tester.tap(
          find.byKey(CfFileUpload.claveBoton),
          warnIfMissed: false,
        );
        expect(elegido, 1);
      },
    );
  });

  group('CfGalleria y CfMiniatura', () {
    testWidgets('insignia, acciones, columnas y marcadores', (tester) async {
      fijarVentana(tester, 900);
      var borradas = 0;
      await montar(
        tester,
        SizedBox(
          width: 640,
          child: CfGalleria(
            items: [
              for (var i = 0; i < 3; i++)
                CfGaleriaItem(
                  clave: ValueKey('g$i'),
                  url: 'http://api.test/f$i.png',
                  descripcion: 'Foto $i',
                  insignia: i == 0 ? 'Portada' : null,
                  acciones: [
                    CfAccionFila(
                      etiqueta: 'Borrar',
                      icono: Icons.delete_outline,
                      peligro: true,
                      onPressed: () => borradas++,
                    ),
                    CfAccionFila(
                      etiqueta: 'Mover',
                      icono: Icons.arrow_forward,
                      cargando: i == 2,
                      onPressed: () {},
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.widgetWithText(CfTag, 'Portada'), findsOneWidget);
      // 640 px, mínimo 200 px y 12 px de separación: 3 columnas.
      expect(
        tester.getSize(find.byKey(const ValueKey('g0'))).width,
        closeTo((640 - 24) / 3, 0.01),
      );
      await tester.tap(find.byTooltip('Borrar').first);
      expect(borradas, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await montar(
        tester,
        const CfGalleria(items: [], textoVacio: 'Sin fotos'),
      );
      expect(find.text('Sin fotos'), findsOneWidget);

      await montar(
        tester,
        const CfMiniatura(url: null, descripcion: 'Portada', tamano: 48),
      );
      expect(find.bySemanticsLabel('Portada: sin imagen'), findsOneWidget);
    });
  });

  group('CfMultiSelect y CfSelect', () {
    testWidgets('marca, desmarca, nota, error y deshabilitado', (tester) async {
      var seleccion = <int>{1};
      Widget lista({ValueChanged<Set<int>>? alCambiar, String? error}) =>
          SizedBox(
            width: 400,
            child: CfMultiSelect<int>(
              label: 'Materiales',
              ayuda: 'Solo activos',
              errorText: error,
              opciones: const [
                CfOpcionMultiple(1, 'Lienzo'),
                CfOpcionMultiple(2, 'Barniz', nota: 'inactivo'),
              ],
              seleccionados: seleccion,
              onChanged: alCambiar,
            ),
          );
      await montar(tester, lista(alCambiar: (v) => seleccion = v));
      expect(find.text('1 seleccionado'), findsOneWidget);
      expect(find.text('Solo activos'), findsOneWidget);
      expect(find.widgetWithText(CfTag, 'inactivo'), findsOneWidget);
      await tester.tap(find.byKey(CfMultiSelect.claveOpcion(2)));
      expect(seleccion, {1, 2});
      await montar(tester, lista(alCambiar: (v) => seleccion = v));
      expect(find.text('2 seleccionados'), findsOneWidget);
      await tester.tap(find.byKey(CfMultiSelect.claveOpcion(1)));
      expect(seleccion, {2});

      await montar(tester, lista(error: 'Material no válido'));
      expect(find.text('Material no válido'), findsOneWidget);
      expect(find.text('Solo activos'), findsNothing);
      await tester.tap(find.byKey(CfMultiSelect.claveOpcion(1)));
      expect(seleccion, {2});

      await montar(
        tester,
        const CfMultiSelect<int>(
          label: 'Vacío',
          opciones: [],
          seleccionados: {},
          onChanged: null,
          textoVacio: 'Nada',
        ),
      );
      expect(find.text('Nada'), findsOneWidget);
      expect(find.text('0 seleccionados'), findsOneWidget);
    });

    testWidgets('CfSelect con hint, validador y error externo', (tester) async {
      final formulario = GlobalKey<FormState>();
      await montar(
        tester,
        SizedBox(
          width: 300,
          child: Form(
            key: formulario,
            child: CfSelect<String?>(
              label: 'Categoría',
              hint: 'Elige una',
              valor: null,
              opciones: const [CfOpcion('c1', 'Murales')],
              validator: (v) => v == null ? 'Obligatoria' : null,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Elige una'), findsOneWidget);
      formulario.currentState!.validate();
      await tester.pump();
      expect(find.text('Obligatoria'), findsOneWidget);

      await montar(
        tester,
        SizedBox(
          width: 300,
          child: CfSelect<String>(
            label: 'Categoría',
            valor: 'c1',
            errorText: 'Del servidor',
            opciones: const [CfOpcion('c1', 'Murales')],
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Del servidor'), findsOneWidget);
    });
  });
}
