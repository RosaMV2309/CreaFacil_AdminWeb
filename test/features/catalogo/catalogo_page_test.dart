import 'package:creafacil_admin/app.dart';
import 'package:creafacil_admin/core/design_system/cf_components.dart';
import 'package:creafacil_admin/core/router/app_router.dart';
import 'package:creafacil_admin/features/catalogo/presentation/catalogo_page.dart';
import 'package:creafacil_admin/features/catalogo/presentation/categorias_tab.dart';
import 'package:creafacil_admin/features/catalogo/presentation/materiales_tab.dart';
import 'package:creafacil_admin/features/catalogo/presentation/servicios_tab.dart';
import 'package:creafacil_admin/features/catalogo/presentation/widgets/comunes_catalogo.dart';
import 'package:creafacil_admin/features/catalogo/presentation/widgets/formulario_categoria.dart';
import 'package:creafacil_admin/features/catalogo/presentation/widgets/formulario_material.dart';
import 'package:creafacil_admin/features/estado_api/presentation/estado_api_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/api_falsa.dart';
import '../../helpers/catalogo_falso.dart';
import '../../helpers/envolver.dart';
import '../../helpers/sesion_falsa.dart';

Future<void> _montar(
  WidgetTester tester, {
  RepositorioCategoriasFalso? categorias,
  RepositorioMaterialesFalso? materiales,
  double ancho = 1280,
  double alto = 900,
}) async {
  fijarVentana(tester, ancho, alto);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        estadoApiRepositoryProvider.overrideWithValue(
          RepositorioEstadoApiFalso(() async => estadoConectado),
        ),
        ...sesionSimulada(almacen: AlmacenSesionMemoria(sesionPrueba())),
        ...catalogoSimulado(categorias: categorias, materiales: materiales),
      ],
      child: const CreaFacilAdminApp(),
    ),
  );
  await tester.pumpAndSettle();
  ProviderScope.containerOf(tester.element(find.byType(CreaFacilAdminApp)))
      .read(appRouterProvider)
      .go(Rutas.catalogo);
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, Key clave, String texto) =>
    tester.enterText(find.byKey(clave), texto);

Future<void> _pulsar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _irAMateriales(WidgetTester tester) =>
    _pulsar(tester, find.widgetWithText(Tab, 'Materiales'));

RepositorioCategoriasFalso _categorias() => RepositorioCategoriasFalso([
  categoriaPrueba(serviciosActivos: 3, serviciosTotales: 4),
  categoriaPrueba(id: 'c2', nombre: 'Cuadros', descripcion: null),
]);

void main() {
  group('Categorías', () {
    testWidgets('tabla con estado, servicios activos y pestañas', (
      tester,
    ) async {
      await _montar(tester, categorias: _categorias());

      expect(find.byType(CatalogoPage), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Servicios'), findsOneWidget);
      expect(find.text('Murales'), findsOneWidget);
      expect(find.text('3 de 4'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.widgetWithText(CfTag, 'Activa'), findsNWidgets(2));
      expect(find.byTooltip('Desactivar'), findsNWidgets(2));

      await _pulsar(tester, find.widgetWithText(Tab, 'Servicios'));
      expect(find.byType(ServiciosTab), findsOneWidget);
      expect(find.text('Aún no hay servicios'), findsOneWidget);
    });

    testWidgets('crear: validación, 409 con CfMessage y éxito', (tester) async {
      final repo = _categorias();
      await _montar(tester, categorias: repo);

      await _pulsar(tester, find.byKey(CategoriasTab.claveNueva));
      expect(find.text('Nueva categoría'), findsWidgets);

      // Validación en el cliente: no se envía nada.
      await _pulsar(tester, find.byKey(FormularioCategoria.claveGuardar));
      expect(find.text('Escribe el nombre.'), findsOneWidget);
      expect(repo.llamadas.where((l) => l.startsWith('crear')), isEmpty);

      await _escribir(tester, FormularioCategoria.claveNombre, 'Murales');
      repo.errorGuardar = errorCatalogo(
        409,
        'CONFLICTO',
        'Ya existe una categoría con ese nombre.',
        [
          {'campo': 'nombre', 'ubicacion': 'body', 'mensaje': 'Repetido'},
        ],
      );
      await _pulsar(tester, find.byKey(FormularioCategoria.claveGuardar));
      final aviso = find.byKey(FormularioCategoria.claveAviso);
      expect(aviso, findsOneWidget);
      expect(
        find.descendant(
          of: aviso,
          matching: find.text('Ya existe una categoría con ese nombre.'),
        ),
        findsOneWidget,
      );
      expect(find.text('Nombre repetido'), findsOneWidget);

      repo.errorGuardar = null;
      await _escribir(
        tester,
        FormularioCategoria.claveNombre,
        '  [newman]   Cuadros ',
      );
      await _escribir(tester, FormularioCategoria.claveOrden, '7');
      await _pulsar(tester, find.byKey(FormularioCategoria.claveGuardar));

      expect(find.byType(FormularioCategoria), findsNothing);
      expect(repo.ultimoAlta!.nombre, '[newman] Cuadros');
      expect(repo.ultimoAlta!.orden, 7);
      expect(
        find.text('Se creó la categoría «[newman] Cuadros».'),
        findsOneWidget,
      );
      expect(find.text('[newman] Cuadros'), findsOneWidget);

      await _pulsar(tester, find.byTooltip('Cerrar'));
      expect(find.byKey(CategoriasTab.claveAviso), findsNothing);
    });

    testWidgets('errores 400 en su campo y se limpian al escribir', (
      tester,
    ) async {
      final repo = _categorias()
        ..errorGuardar = errorCatalogo(400, 'VALIDACION', 'Datos no válidos.', [
          {'campo': 'nombre', 'ubicacion': 'body', 'mensaje': 'Nombre raro'},
          {'campo': 'orden', 'ubicacion': 'body', 'mensaje': 'Orden raro'},
          {'campo': 'body', 'ubicacion': 'body', 'mensaje': 'Otro problema'},
        ]);
      await _montar(tester, categorias: repo);

      await _pulsar(tester, find.byKey(CategoriasTab.claveNueva));
      await _escribir(tester, FormularioCategoria.claveNombre, 'Velas');
      await _pulsar(tester, find.byKey(FormularioCategoria.claveGuardar));

      expect(find.text('Nombre raro'), findsOneWidget);
      expect(find.text('Orden raro'), findsOneWidget);
      expect(find.text('Otro problema'), findsOneWidget);

      await _escribir(tester, FormularioCategoria.claveNombre, 'Velas 2');
      await tester.pump();
      expect(find.text('Nombre raro'), findsNothing);
      expect(find.text('Orden raro'), findsOneWidget);

      await _pulsar(tester, find.text('Cancelar'));
      expect(find.byType(FormularioCategoria), findsNothing);
    });

    testWidgets('editar envía solo los cambios', (tester) async {
      final repo = _categorias();
      await _montar(tester, categorias: repo);

      await _pulsar(tester, find.byKey(CategoriasTab.claveEditar('c2')));
      expect(find.text('Editar categoría'), findsOneWidget);
      await _pulsar(tester, find.byKey(FormularioCategoria.claveGuardar));
      expect(find.text('No hay cambios que guardar.'), findsOneWidget);

      await _escribir(
        tester,
        FormularioCategoria.claveDescripcion,
        'Cuadros pintados',
      );
      await _pulsar(tester, find.byKey(FormularioCategoria.claveGuardar));
      expect(repo.ultimosCambios, {'descripcion': 'Cuadros pintados'});
      expect(
        find.text('Se guardaron los cambios de «Cuadros».'),
        findsOneWidget,
      );
    });

    testWidgets('desactivar con servicios pide confirmación', (tester) async {
      final repo = _categorias();
      await _montar(tester, categorias: repo);

      await _pulsar(tester, find.byKey(CategoriasTab.claveEstado('c1')));
      expect(find.byType(CfConfirmDialog), findsOneWidget);
      expect(
        find.text(
          'Sus 3 servicios dejarán de verse en el catálogo, pero no se '
          'desactivan.',
        ),
        findsOneWidget,
      );
      await _pulsar(tester, find.byKey(CfConfirmDialog.claveCancelar));
      expect(repo.ultimosCambios, isNull);

      await _pulsar(tester, find.byKey(CategoriasTab.claveEstado('c1')));
      await _pulsar(tester, find.byKey(CfConfirmDialog.claveConfirmar));
      expect(repo.ultimosCambios, {'activa': false});
      expect(
        find.text('La categoría «Murales» está desactivada.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(CfTag, 'Inactiva'), findsOneWidget);

      // Activar no pide confirmación.
      await _pulsar(tester, find.byKey(CategoriasTab.claveEstado('c1')));
      expect(find.byType(CfConfirmDialog), findsNothing);
      expect(repo.ultimosCambios, {'activa': true});
      expect(CategoriasTab.avisoServicios(1), contains('Su servicio activo'));
    });

    testWidgets('desactivar sin servicios: sin confirmación; 404 en aviso', (
      tester,
    ) async {
      final repo = _categorias()
        ..errorGuardar = errorCatalogo(
          404,
          'NO_ENCONTRADO',
          'La categoría no existe.',
        );
      await _montar(tester, categorias: repo);

      await _pulsar(tester, find.byKey(CategoriasTab.claveEstado('c2')));
      expect(find.byType(CfConfirmDialog), findsNothing);
      expect(find.text('La categoría no existe.'), findsOneWidget);
      expect(find.text('No encontrado'), findsOneWidget);
    });

    testWidgets(
      'búsqueda con espera, filtro por estado y error con reintento',
      (tester) async {
        final repo = _categorias();
        await _montar(tester, categorias: repo);

        await tester.enterText(find.byKey(BarraFiltros.claveBuscador), 'cua');
        await tester.pump(BarraFiltros.espera);
        await tester.pumpAndSettle();
        expect(repo.llamadas.last, 'listar:cua:null');
        expect(find.text('Murales'), findsNothing);

        await _pulsar(tester, find.byKey(CategoriasTab.claveFiltro));
        await _pulsar(tester, find.text('Inactivas').last);
        expect(repo.llamadas.last, 'listar:cua:false');
        expect(find.text('Ninguna categoría coincide'), findsOneWidget);

        repo.errorListar = errorCatalogo(500, 'ERROR_INTERNO', 'Falló.');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.enterText(find.byKey(BarraFiltros.claveBuscador), 'x');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        expect(find.byType(CfErrorState), findsOneWidget);
        expect(find.text('Falló.'), findsOneWidget);

        repo.errorListar = null;
        await _pulsar(tester, find.text('Reintentar'));
        expect(find.byType(CfErrorState), findsNothing);
      },
    );
  });

  group('Materiales', () {
    testWidgets('precio exacto: validación, alta con texto y edición', (
      tester,
    ) async {
      final repo = RepositorioMaterialesFalso([materialPrueba()]);
      await _montar(tester, materiales: repo);
      await _irAMateriales(tester);

      expect(find.text(r'$ 0,75'), findsOneWidget);
      expect(find.widgetWithText(CfTag, 'Activo'), findsOneWidget);

      await _pulsar(tester, find.byKey(MaterialesTab.claveNuevo));
      expect(find.byKey(FormularioMaterial.claveNotaPrecio), findsNothing);
      await _escribir(
        tester,
        FormularioMaterial.claveNombre,
        '[newman] Lienzo',
      );
      await _escribir(tester, FormularioMaterial.claveUnidad, 'metro');

      for (final (precio, error) in [
        ('1.234', 'El precio admite como máximo 2 decimales.'),
        ('4,5', 'Usa el punto como separador decimal (por ejemplo, 4.50).'),
        ('0', 'El precio debe ser mayor que 0.'),
        ('100000', 'El precio no puede superar 99999.99.'),
      ]) {
        await _escribir(tester, FormularioMaterial.clavePrecio, precio);
        await _pulsar(tester, find.byKey(FormularioMaterial.claveGuardar));
        expect(find.text(error), findsOneWidget, reason: precio);
      }
      expect(repo.llamadas.where((l) => l.startsWith('crear')), isEmpty);

      await _escribir(tester, FormularioMaterial.clavePrecio, '4.5');
      await _pulsar(tester, find.byKey(FormularioMaterial.claveGuardar));
      expect(repo.ultimoAlta!.aJson()['precioUnitario'], '4.50');
      expect(
        find.text(r'Se creó el material «[newman] Lienzo» ($ 4,50).'),
        findsOneWidget,
      );
      expect(find.text(r'$ 4,50'), findsOneWidget);

      final id = repo.materiales.last.id;
      await _pulsar(tester, find.byKey(MaterialesTab.claveEditar(id)));
      expect(find.byKey(FormularioMaterial.claveNotaPrecio), findsOneWidget);
      expect(find.text(FormularioMaterial.notaPrecio), findsOneWidget);
      await _escribir(tester, FormularioMaterial.clavePrecio, '5.25');
      await _pulsar(tester, find.byKey(FormularioMaterial.claveGuardar));
      expect(repo.ultimosCambios, {'precioUnitario': '5.25'});
      expect(find.text(r'$ 5,25'), findsOneWidget);
    });

    testWidgets('400 del servidor en el campo del precio y 409 en aviso', (
      tester,
    ) async {
      final repo = RepositorioMaterialesFalso([materialPrueba()])
        ..errorGuardar = errorCatalogo(400, 'VALIDACION', 'Datos no válidos.', [
          {
            'campo': 'precioUnitario',
            'ubicacion': 'body',
            'mensaje': 'El precio no es válido (servidor).',
          },
        ]);
      await _montar(tester, materiales: repo);
      await _irAMateriales(tester);

      await _pulsar(tester, find.byKey(MaterialesTab.claveEditar('m1')));
      await _escribir(tester, FormularioMaterial.clavePrecio, '9.99');
      await _pulsar(tester, find.byKey(FormularioMaterial.claveGuardar));
      expect(find.text('El precio no es válido (servidor).'), findsOneWidget);
      // Regresión: volver a guardar sin tocar el campo reenvía la petición.
      await _pulsar(tester, find.byKey(FormularioMaterial.claveGuardar));
      expect(
        repo.llamadas.where((l) => l.startsWith('actualizar')),
        hasLength(2),
      );
      await _escribir(tester, FormularioMaterial.clavePrecio, '9.98');
      await tester.pumpAndSettle();
      expect(find.text('El precio no es válido (servidor).'), findsNothing);

      repo.errorGuardar = errorCatalogo(
        409,
        'CONFLICTO',
        'Ya existe un material con ese nombre.',
      );
      await _pulsar(tester, find.byKey(FormularioMaterial.claveGuardar));
      expect(
        find.text('Ya existe un material con ese nombre.'),
        findsOneWidget,
      );
      await _pulsar(tester, find.byKey(CfDialog.claveCerrar));
      await _pulsar(tester, find.byKey(MaterialesTab.claveEditar('m1')));
      await _pulsar(tester, find.byKey(FormularioMaterial.claveGuardar));
      expect(find.text('No hay cambios que guardar.'), findsOneWidget);
    });

    testWidgets('paginación, filtro y activar o desactivar', (tester) async {
      final repo = RepositorioMaterialesFalso([
        for (var i = 0; i < 25; i++)
          materialPrueba(id: 'm$i', nombre: 'Material ${i + 10}'),
      ]);
      await _montar(tester, materiales: repo, alto: 3000);
      await _irAMateriales(tester);

      expect(find.text('Página 1 de 2 · 25 registros'), findsOneWidget);
      await _pulsar(tester, find.byKey(CfDataTable.claveSiguiente));
      expect(repo.llamadas.last, 'listar:2::null');
      expect(find.text('Página 2 de 2 · 25 registros'), findsOneWidget);

      await _pulsar(tester, find.byKey(MaterialesTab.claveEstado('m24')));
      expect(repo.ultimosCambios, {'activo': false});
      expect(
        find.text('El material «Material 34» está desactivado.'),
        findsOneWidget,
      );
      await _pulsar(tester, find.byKey(MaterialesTab.claveEstado('m24')));
      expect(
        find.text('El material «Material 34» está activo.'),
        findsOneWidget,
      );

      repo.errorGuardar = errorCatalogo(
        404,
        'NO_ENCONTRADO',
        'El material no existe.',
      );
      await _pulsar(tester, find.byKey(MaterialesTab.claveEstado('m24')));
      expect(find.text('El material no existe.'), findsOneWidget);

      await _pulsar(tester, find.byKey(MaterialesTab.claveFiltro));
      await _pulsar(tester, find.text('Inactivos').last);
      expect(repo.llamadas.last, 'listar:1::false');
      expect(find.text('Ningún material coincide'), findsOneWidget);
    });

    testWidgets('error al cargar con reintento', (tester) async {
      final repo = RepositorioMaterialesFalso([materialPrueba()])
        ..errorListar = errorCatalogo(
          403,
          'PROHIBIDO',
          'No tienes permiso para esta acción.',
        );
      await _montar(tester, materiales: repo);
      await _irAMateriales(tester);
      expect(find.text('No tienes permiso para esta acción.'), findsOneWidget);

      repo.errorListar = null;
      await _pulsar(tester, find.text('Reintentar'));
      expect(find.text(r'$ 0,75'), findsOneWidget);
    });
  });

  test('AvisoCatalogo.desdeError pone un título claro', () {
    String? titulo(int estado) =>
        AvisoCatalogo.desdeError(errorCatalogo(estado, 'X', 'm')).titulo;
    expect(titulo(400), 'Revisa los datos');
    expect(titulo(403), 'Sin permiso');
    expect(titulo(500), 'No se pudo guardar');
  });

  for (final ancho in [375.0, 768.0, 1280.0]) {
    testWidgets('sin desbordes a ${ancho.toInt()} px', (tester) async {
      await _montar(
        tester,
        ancho: ancho,
        categorias: _categorias(),
        materiales: RepositorioMaterialesFalso([
          materialPrueba(descripcion: 'Pintura de colores vivos'),
          materialPrueba(id: 'm2', nombre: 'Lienzo', precio: '1234.5'),
        ]),
      );
      expect(tester.takeException(), isNull);
      if (ancho < 1024) {
        // Con el riel o el menú, el área útil baja de 600 px: tarjetas.
        expect(find.widgetWithText(CfButton, 'Editar'), findsNWidgets(2));
      } else {
        expect(find.text('Acciones'), findsOneWidget);
      }

      await _pulsar(tester, find.byKey(CategoriasTab.claveNueva));
      expect(tester.takeException(), isNull);
      await _pulsar(tester, find.byKey(FormularioCategoria.claveGuardar));
      expect(tester.takeException(), isNull);
      await _pulsar(tester, find.byKey(CfDialog.claveCerrar));

      await _irAMateriales(tester);
      expect(tester.takeException(), isNull);
      expect(find.text(r'$ 1.234,50'), findsOneWidget);
      await _pulsar(tester, find.byKey(MaterialesTab.claveEditar('m1')));
      expect(tester.takeException(), isNull);
      await _pulsar(tester, find.byKey(CfDialog.claveCerrar));
    });
  }
}
