import 'dart:async';

import 'package:creafacil_admin/app.dart';
import 'package:creafacil_admin/core/design_system/cf_components.dart';
import 'package:creafacil_admin/core/router/app_router.dart';
import 'package:creafacil_admin/features/catalogo/domain/servicios.dart';
import 'package:creafacil_admin/features/catalogo/presentation/servicios_tab.dart';
import 'package:creafacil_admin/features/catalogo/presentation/widgets/comunes_catalogo.dart';
import 'package:creafacil_admin/features/catalogo/presentation/widgets/formulario_servicio.dart';
import 'package:creafacil_admin/features/catalogo/presentation/widgets/fotos_servicio.dart';
import 'package:creafacil_admin/features/estado_api/presentation/estado_api_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/api_falsa.dart';
import '../../helpers/catalogo_falso.dart';
import '../../helpers/envolver.dart';
import '../../helpers/sesion_falsa.dart';

final _categorias = [
  categoriaPrueba(),
  categoriaPrueba(id: 'c2', nombre: 'Cuadros', activa: false),
];

const _inactiva = CategoriaDeServicio(
  id: 'c2',
  nombre: 'Cuadros',
  activa: false,
);

const _lienzoInactivo = MaterialDeServicio(
  id: 'm9',
  nombre: 'Barniz',
  unidad: 'litro',
  activo: false,
);

RepositorioServiciosFalso _servicios({int fotos = 2}) =>
    RepositorioServiciosFalso([
      servicioPrueba(
        fotos: [for (var i = 0; i < fotos; i++) fotoPrueba('f${i + 1}', i)],
        materiales: const [_lienzoInactivo],
        descripcion: 'Mural a mano',
      ),
      servicioPrueba(
        id: 's2',
        nombre: 'Cuadro',
        categoria: _inactiva,
        precio: null,
        activo: false,
      ),
    ], _categorias);

Future<void> _montar(
  WidgetTester tester, {
  RepositorioServiciosFalso? servicios,
  SelectorArchivosFalso? selector,
  double ancho = 1280,
  double alto = 1400,
}) async {
  fijarVentana(tester, ancho, alto);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        estadoApiRepositoryProvider.overrideWithValue(
          RepositorioEstadoApiFalso(() async => estadoConectado),
        ),
        ...sesionSimulada(almacen: AlmacenSesionMemoria(sesionPrueba())),
        ...catalogoSimulado(
          categorias: RepositorioCategoriasFalso(_categorias),
          materiales: RepositorioMaterialesFalso([
            materialPrueba(nombre: 'Lienzo', unidad: 'metro'),
            materialPrueba(id: 'm2', nombre: 'Pintura', unidad: 'litro'),
          ]),
          servicios: servicios ?? _servicios(),
          selector: selector,
        ),
      ],
      child: const CreaFacilAdminApp(),
    ),
  );
  await tester.pumpAndSettle();
  ProviderScope.containerOf(tester.element(find.byType(CreaFacilAdminApp)))
      .read(appRouterProvider)
      .go(Rutas.catalogo);
  await tester.pumpAndSettle();
  await _pulsar(tester, find.widgetWithText(Tab, 'Servicios'));
}

Future<void> _pulsar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, Key clave, String texto) =>
    tester.enterText(find.byKey(clave), texto);

Future<void> _elegir(WidgetTester tester, Key select, String opcion) async {
  await _pulsar(tester, find.byKey(select));
  await _pulsar(tester, find.text(opcion).last);
}

Finder _enAviso(Key clave, String texto) => find.descendant(
  of: find.byKey(clave),
  matching: find.textContaining(texto),
);

void main() {
  group('Tabla de servicios', () {
    testWidgets('columnas, aviso de categoría inactiva y filtros', (
      tester,
    ) async {
      final repo = _servicios();
      await _montar(tester, servicios: repo);

      expect(find.byType(ServiciosTab), findsOneWidget);
      expect(find.text('Mural infantil'), findsOneWidget);
      expect(find.text(r'Desde $ 120,50'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('2 de 8'), findsOneWidget);
      expect(find.text('0 de 8'), findsOneWidget);
      expect(find.byType(CfMiniatura), findsNWidgets(2));
      expect(
        find.widgetWithText(CfTag, ServiciosTab.avisoCategoriaInactiva),
        findsOneWidget,
      );
      expect(find.widgetWithText(CfTag, 'Inactivo'), findsOneWidget);

      await tester.enterText(find.byKey(BarraFiltros.claveBuscador), 'cua');
      await tester.pump(BarraFiltros.espera);
      await tester.pumpAndSettle();
      expect(repo.llamadas.last, 'listar:1:cua::null');

      await _elegir(
        tester,
        ServiciosTab.claveFiltroCategoria,
        'Cuadros (inactiva)',
      );
      expect(repo.llamadas.last, 'listar:1:cua:c2:null');
      await _elegir(tester, ServiciosTab.claveFiltroEstado, 'Activos');
      expect(repo.llamadas.last, 'listar:1:cua:c2:true');
      expect(find.text('Ningún servicio coincide'), findsOneWidget);
    });

    testWidgets('error al cargar con reintento', (tester) async {
      final repo = _servicios()
        ..errorListar = errorCatalogo(500, 'ERROR_INTERNO', 'Falló.');
      await _montar(tester, servicios: repo);
      expect(find.text('Falló.'), findsOneWidget);
      repo.errorListar = null;
      await _pulsar(tester, find.text('Reintentar'));
      expect(find.text('Mural infantil'), findsOneWidget);
    });

    testWidgets('activar y desactivar con confirmación', (tester) async {
      final repo = _servicios();
      await _montar(tester, servicios: repo);

      await _pulsar(tester, find.byKey(ServiciosTab.claveEstado('s1')));
      expect(find.byType(CfConfirmDialog), findsOneWidget);
      expect(find.textContaining('dejará de verse'), findsOneWidget);
      await _pulsar(tester, find.byKey(CfConfirmDialog.claveCancelar));
      expect(repo.ultimosCambios, isNull);

      await _pulsar(tester, find.byKey(ServiciosTab.claveEstado('s1')));
      await _pulsar(tester, find.byKey(CfConfirmDialog.claveConfirmar));
      expect(repo.ultimosCambios, {'activo': false});
      expect(
        find.text('El servicio «Mural infantil» está desactivado.'),
        findsOneWidget,
      );

      await _pulsar(tester, find.byKey(ServiciosTab.claveEstado('s2')));
      expect(
        find.textContaining('cuando actives su categoría'),
        findsOneWidget,
      );
      await _pulsar(tester, find.byKey(CfConfirmDialog.claveConfirmar));
      expect(repo.ultimosCambios, {'activo': true});
      expect(find.text('El servicio «Cuadro» está activo.'), findsOneWidget);

      repo.errorGuardar = errorCatalogo(
        404,
        'NO_ENCONTRADO',
        'El servicio no existe.',
      );
      await _pulsar(tester, find.byKey(ServiciosTab.claveEstado('s2')));
      await _pulsar(tester, find.byKey(CfConfirmDialog.claveConfirmar));
      expect(find.text('El servicio no existe.'), findsOneWidget);
      await _pulsar(tester, find.byTooltip('Cerrar'));
      expect(find.byKey(ServiciosTab.claveAviso), findsNothing);
    });
  });

  group('Formulario de servicio', () {
    testWidgets('crear: validación, precio, materiales, 409 y éxito', (
      tester,
    ) async {
      final repo = _servicios();
      await _montar(tester, servicios: repo);

      await _pulsar(tester, find.byKey(ServiciosTab.claveNuevo));
      expect(find.text('Nuevo servicio'), findsWidgets);
      await _pulsar(tester, find.byKey(FormularioServicio.claveGuardar));
      expect(find.text('Elige la categoría.'), findsOneWidget);
      expect(find.text('Escribe el nombre.'), findsOneWidget);

      await _elegir(
        tester,
        FormularioServicio.claveCategoria,
        'Cuadros (inactiva)',
      );
      expect(
        find.byKey(FormularioServicio.claveAvisoCategoria),
        findsOneWidget,
      );
      await _elegir(tester, FormularioServicio.claveCategoria, 'Murales');
      expect(find.byKey(FormularioServicio.claveAvisoCategoria), findsNothing);

      await _escribir(tester, FormularioServicio.claveNombre, '[newman] Mural');
      for (final (precio, error) in [
        ('1.234', 'El precio admite como máximo 2 decimales.'),
        ('120,5', 'Usa el punto como separador decimal (por ejemplo, 4.50).'),
        ('0', 'El precio debe ser mayor que 0.'),
      ]) {
        await _escribir(tester, FormularioServicio.clavePrecio, precio);
        await _pulsar(tester, find.byKey(FormularioServicio.claveGuardar));
        expect(find.text(error), findsOneWidget, reason: precio);
      }
      expect(repo.llamadas.where((l) => l.startsWith('crear')), isEmpty);

      await _escribir(tester, FormularioServicio.clavePrecio, '120.5');
      await _pulsar(tester, find.byKey(CfMultiSelect.claveOpcion('m2')));
      await _pulsar(tester, find.byKey(CfMultiSelect.claveOpcion('m1')));
      expect(find.text('2 seleccionados'), findsOneWidget);
      await _escribir(tester, FormularioServicio.claveDimensiones, '2 x 3 m');

      repo.errorGuardar = errorCatalogo(
        409,
        'CONFLICTO',
        'Ya existe un servicio con ese nombre en esta categoría.',
      );
      await _pulsar(tester, find.byKey(FormularioServicio.claveGuardar));
      expect(
        _enAviso(FormularioServicio.claveAviso, 'en esta categoría'),
        findsOneWidget,
      );
      expect(find.text('Nombre repetido'), findsOneWidget);

      repo.errorGuardar = null;
      await _pulsar(tester, find.byKey(FormularioServicio.claveGuardar));
      expect(find.byType(FormularioServicio), findsNothing);
      expect(repo.ultimoAlta!.aJson(), {
        'categoriaId': 'c1',
        'nombre': '[newman] Mural',
        'dimensionesOrientativas': '2 x 3 m',
        'precioBaseReferencial': '120.50',
        'materialIds': ['m1', 'm2'],
      });
      expect(
        _enAviso(
          ServiciosTab.claveAviso,
          'Se creó el servicio «[newman] Mural»',
        ),
        findsOneWidget,
      );
    });

    testWidgets('editar: material inactivo, solo cambios y 400 en su campo', (
      tester,
    ) async {
      final repo = _servicios();
      await _montar(tester, servicios: repo);

      await _pulsar(tester, find.byKey(ServiciosTab.claveEditar('s1')));
      expect(find.text('Editar servicio'), findsOneWidget);
      expect(find.text('Mural a mano'), findsOneWidget);
      final inactivo = find.byKey(CfMultiSelect.claveOpcion('m9'));
      expect(
        find.descendant(of: inactivo, matching: find.text('inactivo')),
        findsOneWidget,
      );

      await _pulsar(tester, find.byKey(FormularioServicio.claveGuardar));
      expect(find.text('No hay cambios que guardar.'), findsOneWidget);

      repo.errorGuardar = errorCatalogo(
        400,
        'VALIDACION',
        'Datos no válidos.',
        [
          {
            'campo': 'precioBaseReferencial',
            'ubicacion': 'body',
            'mensaje': 'Precio no válido (servidor).',
          },
          {
            'campo': 'materialIds',
            'ubicacion': 'body',
            'mensaje': 'Material desactivado (servidor).',
          },
        ],
      );
      await _escribir(tester, FormularioServicio.clavePrecio, '');
      await _pulsar(tester, inactivo);
      await _pulsar(tester, find.byKey(FormularioServicio.claveGuardar));
      expect(repo.ultimosCambios, {
        'precioBaseReferencial': null,
        'materialIds': <String>[],
      });
      expect(find.text('Precio no válido (servidor).'), findsOneWidget);
      expect(find.text('Material desactivado (servidor).'), findsOneWidget);
      await _pulsar(tester, find.byKey(CfMultiSelect.claveOpcion('m1')));
      expect(find.text('Material desactivado (servidor).'), findsNothing);

      repo.errorGuardar = null;
      await _pulsar(tester, find.byKey(FormularioServicio.claveGuardar));
      expect(
        find.text('Se guardaron los cambios de «Mural infantil».'),
        findsOneWidget,
      );
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('editar: 404 al cargar la ficha', (tester) async {
      final repo = _servicios()
        ..errorObtener = errorCatalogo(
          404,
          'NO_ENCONTRADO',
          'El servicio no existe.',
        );
      await _montar(tester, servicios: repo);
      await _pulsar(tester, find.byKey(ServiciosTab.claveEditar('s1')));
      expect(find.byType(FormularioServicio), findsNothing);
      expect(find.text('El servicio no existe.'), findsOneWidget);
    });
  });

  group('Fotos del servicio', () {
    testWidgets('cuadrícula, portada, reordenar y borrar con confirmación', (
      tester,
    ) async {
      final repo = _servicios(fotos: 3);
      await _montar(tester, servicios: repo);

      await _pulsar(tester, find.byKey(ServiciosTab.claveFotos('s1')));
      expect(find.byType(CfGalleria), findsOneWidget);
      expect(find.textContaining('3 de 8 fotos'), findsOneWidget);
      final portada = find.descendant(
        of: find.byKey(FotosServicio.claveFoto('f1')),
        matching: find.widgetWithText(CfTag, 'Portada'),
      );
      expect(portada, findsOneWidget);

      await _pulsar(tester, find.byKey(FotosServicio.claveDerecha('f1')));
      expect(repo.llamadas.last, 'ordenar:s1:f2,f1,f3');
      expect(_enAviso(FotosServicio.claveAviso, 'nuevo orden'), findsOneWidget);
      await _pulsar(tester, find.byKey(FotosServicio.claveIzquierda('f3')));
      expect(repo.llamadas.last, 'ordenar:s1:f2,f3,f1');
      await _pulsar(tester, find.byKey(FotosServicio.clavePortada('f1')));
      expect(repo.llamadas.last, 'ordenar:s1:f1,f2,f3');
      expect(_enAviso(FotosServicio.claveAviso, 'portada'), findsOneWidget);

      await _pulsar(tester, find.byKey(FotosServicio.claveBorrar('f1')));
      expect(find.textContaining('Es la portada'), findsOneWidget);
      await _pulsar(tester, find.byKey(CfConfirmDialog.claveCancelar));
      expect(repo.llamadas.last, startsWith('ordenar'));
      await _pulsar(tester, find.byKey(FotosServicio.claveBorrar('f2')));
      expect(find.textContaining('se borrará del servicio'), findsOneWidget);
      await _pulsar(tester, find.byKey(CfConfirmDialog.claveConfirmar));
      expect(repo.llamadas.last, 'borrar:s1:f2');
      expect(find.byKey(FotosServicio.claveFoto('f2')), findsNothing);

      repo.errorFoto = errorCatalogo(
        404,
        'NO_ENCONTRADO',
        'La foto no existe en este servicio.',
      );
      await _pulsar(tester, find.byKey(FotosServicio.claveDerecha('f1')));
      expect(find.text('La foto no existe en este servicio.'), findsOneWidget);

      await _pulsar(tester, find.byKey(FotosServicio.claveCerrar));
      expect(find.byType(FotosServicio), findsNothing);
      expect(find.text('2 de 8'), findsOneWidget);
    });

    testWidgets('subir: validación en el cliente, progreso y errores', (
      tester,
    ) async {
      final repo = _servicios(fotos: 1);
      final selector = SelectorArchivosFalso();
      await _montar(tester, servicios: repo, selector: selector);
      await _pulsar(tester, find.byKey(ServiciosTab.claveFotos('s1')));
      final subir = find.byKey(CfFileUpload.claveBoton);

      // Cancelar el selector no hace nada.
      await _pulsar(tester, subir);
      expect(selector.llamadas, 1);

      selector.elegir('documento.pdf');
      await _pulsar(tester, subir);
      expect(find.text('Elige una imagen JPG, PNG o WebP.'), findsOneWidget);
      selector.elegir('grande.jpg', tamano: 6 * 1024 * 1024);
      await _pulsar(tester, subir);
      expect(
        find.text('La foto pesa 6.0 MB y el máximo es 5 MB.'),
        findsOneWidget,
      );
      selector.elegir('vacia.png', tamano: null, bytes: 0);
      await _pulsar(tester, subir);
      expect(find.text('El archivo está vacío.'), findsOneWidget);
      expect(repo.llamadas.where((l) => l.startsWith('subir')), isEmpty);

      // 400 del servidor: el contenido no es una imagen.
      repo.errorFoto = errorCatalogo(400, 'VALIDACION', 'Datos no válidos.', [
        {
          'campo': 'foto',
          'ubicacion': 'body',
          'mensaje': 'El archivo no es una imagen JPG, PNG o WebP válida.',
        },
      ]);
      selector.elegir('no-es-imagen.png');
      await _pulsar(tester, subir);
      expect(repo.llamadas.last, 'subir:s1:no-es-imagen.png:image/png');
      expect(
        find.text('El archivo no es una imagen JPG, PNG o WebP válida.'),
        findsOneWidget,
      );
      expect(find.text('No se pudo subir la foto'), findsOneWidget);

      repo.errorFoto = errorCatalogo(
        413,
        'ARCHIVO_DEMASIADO_GRANDE',
        'La foto supera el máximo de 5 MB.',
      );
      await _pulsar(tester, subir);
      expect(find.text('Archivo demasiado grande'), findsOneWidget);
      repo.errorFoto = errorCatalogo(
        409,
        'CONFLICTO',
        'El servicio ya tiene 8 fotos, el máximo.',
      );
      await _pulsar(tester, subir);
      expect(find.text('Límite de fotos'), findsOneWidget);

      // Éxito con barra de progreso.
      repo
        ..errorFoto = null
        ..esperaFoto = Completer<void>();
      selector.elegir('mural.webp');
      await tester.tap(subir);
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }
      expect(find.byKey(CfFileUpload.claveProgreso), findsOneWidget);
      expect(find.text('Subiendo… 50 %'), findsOneWidget);
      // Sin envíos dobles mientras sube.
      await tester.tap(subir, warnIfMissed: false);
      repo.esperaFoto!.complete();
      await tester.pumpAndSettle();
      expect(
        repo.llamadas.where((l) => l == 'subir:s1:mural.webp:image/webp'),
        hasLength(1),
      );
      expect(find.byKey(CfFileUpload.claveProgreso), findsNothing);
      expect(find.text('Se subió la foto «mural.webp».'), findsOneWidget);
      expect(find.textContaining('2 de 8 fotos'), findsOneWidget);
    });

    testWidgets('límite de 8: «Subir» deshabilitado con el motivo', (
      tester,
    ) async {
      final selector = SelectorArchivosFalso()..elegir('otra.png');
      await _montar(
        tester,
        servicios: _servicios(fotos: 8),
        selector: selector,
      );
      await _pulsar(tester, find.byKey(ServiciosTab.claveFotos('s1')));
      expect(find.text(FotosServicio.motivoLimite), findsOneWidget);
      await tester.ensureVisible(find.byKey(CfFileUpload.claveBoton));
      await tester.tap(
        find.byKey(CfFileUpload.claveBoton),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(selector.llamadas, 0);
    });

    testWidgets('sin fotos y error al cargar con reintento', (tester) async {
      final repo = _servicios(fotos: 0);
      await _montar(tester, servicios: repo);
      await _pulsar(tester, find.byKey(ServiciosTab.claveFotos('s1')));
      expect(find.text('Este servicio aún no tiene fotos'), findsOneWidget);
      await _pulsar(tester, find.byKey(FotosServicio.claveCerrar));

      repo.errorObtener = errorCatalogo(500, 'ERROR_INTERNO', 'Falló.');
      await _pulsar(tester, find.byKey(ServiciosTab.claveFotos('s2')));
      expect(find.text('No se pudieron cargar las fotos'), findsOneWidget);
      repo.errorObtener = null;
      await _pulsar(tester, find.text('Reintentar'));
      expect(find.text('Este servicio aún no tiene fotos'), findsOneWidget);
    });
  });

  for (final ancho in [375.0, 768.0, 1280.0]) {
    testWidgets('servicios sin desbordes a ${ancho.toInt()} px', (
      tester,
    ) async {
      await _montar(tester, ancho: ancho, alto: 900);
      expect(tester.takeException(), isNull);
      if (ancho < 1024) {
        expect(find.widgetWithText(CfButton, 'Fotos'), findsNWidgets(2));
      } else {
        expect(find.text('Acciones'), findsOneWidget);
      }

      await _pulsar(tester, find.byKey(ServiciosTab.claveNuevo));
      expect(tester.takeException(), isNull);
      await _pulsar(tester, find.byKey(FormularioServicio.claveGuardar));
      expect(tester.takeException(), isNull);
      await _pulsar(tester, find.byKey(CfDialog.claveCerrar));

      await _pulsar(tester, find.byKey(ServiciosTab.claveFotos('s1')));
      expect(tester.takeException(), isNull);
      expect(find.byType(CfGalleria), findsOneWidget);
      await _pulsar(tester, find.byKey(FotosServicio.claveCerrar));
      expect(tester.takeException(), isNull);
    });
  }
}
