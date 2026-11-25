import 'package:creafacil_admin/core/design_system/cf_components.dart';
import 'package:creafacil_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/envolver.dart';

typedef _Fila = ({String nombre, int cantidad});

const _filas = <_Fila>[
  (nombre: 'Lienzo', cantidad: 3),
  (nombre: 'Hilo', cantidad: 1),
];

Widget _tabla({
  List<_Fila> filas = _filas,
  bool cargando = false,
  String? error,
  VoidCallback? onReintentar,
  CfPaginacion? paginacion,
  void Function(String)? alPulsar,
}) => CfDataTable<_Fila>(
  etiqueta: 'Tabla de prueba',
  filas: filas,
  cargando: cargando,
  error: error,
  onReintentar: onReintentar,
  paginacion: paginacion,
  tituloVacio: 'Sin datos',
  claveFila: (f) => ValueKey('fila-${f.nombre}'),
  columnas: [
    CfColumna(titulo: 'Nombre', flex: 2, celda: (f) => Text(f.nombre)),
    CfColumna(
      titulo: 'Cantidad',
      numerica: true,
      celda: (f) => Text('${f.cantidad}'),
    ),
  ],
  acciones: (f) => [
    CfAccionFila(
      etiqueta: 'Editar',
      icono: Icons.edit_outlined,
      clave: ValueKey('editar-${f.nombre}'),
      onPressed: () => alPulsar?.call(f.nombre),
    ),
    CfAccionFila(
      etiqueta: 'Desactivar',
      icono: Icons.block,
      peligro: true,
      cargando: f.nombre == 'Hilo',
      onPressed: () {},
    ),
  ],
);

Future<void> _montarAncho(WidgetTester tester, double ancho, Widget w) async {
  fijarVentana(tester, ancho);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.claro(),
      home: Scaffold(body: SingleChildScrollView(child: w)),
    ),
  );
}

void main() {
  group('CfDataTable', () {
    testWidgets('tabla con encabezado, filas y acciones de ícono', (
      tester,
    ) async {
      final pulsadas = <String>[];
      await _montarAncho(tester, 1280, _tabla(alPulsar: pulsadas.add));

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Acciones'), findsOneWidget);
      expect(find.byKey(const ValueKey('fila-Lienzo')), findsOneWidget);
      expect(find.byTooltip('Editar'), findsNWidgets(2));
      // La acción en curso muestra un indicador y no se puede pulsar.
      expect(
        find.bySemanticsLabel(RegExp('Desactivar: en curso')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('editar-Lienzo')));
      expect(pulsadas, ['Lienzo']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('en pantallas estrechas se muestra como tarjetas', (
      tester,
    ) async {
      final pulsadas = <String>[];
      await _montarAncho(tester, 375, _tabla(alPulsar: pulsadas.add));

      expect(find.text('Acciones'), findsNothing);
      expect(find.text('Cantidad'), findsNWidgets(2));
      expect(find.widgetWithText(CfButton, 'Editar'), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('editar-Hilo')));
      expect(pulsadas, ['Hilo']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('estados de carga, vacío y error', (tester) async {
      await _montarAncho(tester, 1280, _tabla(filas: [], cargando: true));
      expect(find.byType(CfSpinner), findsOneWidget);

      await _montarAncho(tester, 1280, _tabla(filas: []));
      expect(find.text('Sin datos'), findsOneWidget);

      await _montarAncho(tester, 1280, _tabla(cargando: true));
      expect(find.byKey(CfDataTable.claveCargando), findsOneWidget);
      expect(find.text('Lienzo'), findsOneWidget);

      var reintentos = 0;
      await _montarAncho(
        tester,
        1280,
        _tabla(error: 'Sin conexión', onReintentar: () => reintentos++),
      );
      expect(find.byType(CfErrorState), findsOneWidget);
      expect(find.text('Lienzo'), findsNothing);
      await tester.tap(find.text('Reintentar'));
      expect(reintentos, 1);
    });

    testWidgets('paginación', (tester) async {
      final paginas = <int>[];
      await _montarAncho(
        tester,
        1280,
        _tabla(
          paginacion: CfPaginacion(
            pagina: 1,
            totalPaginas: 2,
            total: 22,
            onCambiar: paginas.add,
          ),
        ),
      );
      expect(find.text('Página 1 de 2 · 22 registros'), findsOneWidget);
      await tester.tap(find.byKey(CfDataTable.claveAnterior));
      await tester.tap(find.byKey(CfDataTable.claveSiguiente));
      expect(paginas, [2]);

      await _montarAncho(
        tester,
        1280,
        _tabla(
          paginacion: CfPaginacion(
            pagina: 1,
            totalPaginas: 0,
            total: 1,
            onCambiar: paginas.add,
          ),
        ),
      );
      expect(find.text('Página 1 de 1 · 1 registro'), findsOneWidget);
    });
  });

  testWidgets('CfDialog: título, cuerpo, acciones y cerrar', (tester) async {
    await montar(
      tester,
      Builder(
        builder: (context) => CfButton(
          label: 'Abrir',
          onPressed: () => CfDialog.mostrar<void>(
            context,
            builder: (_) => const CfDialog(
              titulo: 'Nuevo',
              subtitulo: 'Sub',
              acciones: [Text('Acción')],
              child: Text('Cuerpo'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo'), findsOneWidget);
    expect(find.text('Sub'), findsOneWidget);
    expect(find.text('Cuerpo'), findsOneWidget);
    expect(find.text('Acción'), findsOneWidget);
    await tester.tap(find.byKey(CfDialog.claveCerrar));
    await tester.pumpAndSettle();
    expect(find.text('Cuerpo'), findsNothing);
  });

  testWidgets('CfDialog no cerrable deshabilita «Cerrar»', (tester) async {
    await montar(
      tester,
      const CfDialog(titulo: 'T', cerrable: false, child: Text('x')),
    );
    final cerrar = tester.widget<IconButton>(find.byKey(CfDialog.claveCerrar));
    expect(cerrar.onPressed, isNull);
  });

  testWidgets('CfSelect cambia el valor', (tester) async {
    final elegidos = <int>[];
    await montar(
      tester,
      SizedBox(
        width: 300,
        child: CfSelect<int>(
          label: 'Estado',
          valor: 1,
          opciones: const [CfOpcion(1, 'Uno'), CfOpcion(2, 'Dos')],
          onChanged: elegidos.add,
        ),
      ),
    );
    await tester.tap(find.text('Uno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dos').last);
    await tester.pumpAndSettle();
    expect(elegidos, [2]);
  });

  testWidgets('CfTabs cambia de pestaña y CfTextarea valida', (tester) async {
    final formulario = GlobalKey<FormState>();
    fijarVentana(tester, 800);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro(),
        home: Scaffold(
          body: CfTabs(
            tabs: [
              CfTab(
                etiqueta: 'Uno',
                icono: Icons.looks_one,
                contenido: Form(
                  key: formulario,
                  child: CfTextarea(
                    label: 'Descripción',
                    maxLength: 5,
                    validator: (v) => (v ?? '').isEmpty ? 'Obligatoria' : null,
                  ),
                ),
              ),
              const CfTab(etiqueta: 'Dos', contenido: Text('Contenido dos')),
            ],
          ),
        ),
      ),
    );
    expect(formulario.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Obligatoria'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'abcdefgh');
    expect(find.text('abcde'), findsOneWidget);

    await tester.tap(find.text('Dos'));
    await tester.pumpAndSettle();
    expect(find.text('Contenido dos'), findsOneWidget);
  });
}
