import 'dart:async';

import 'package:creafacil_admin/core/design_system/cf_components.dart';
import 'package:creafacil_admin/core/network/red.dart';
import 'package:creafacil_admin/core/router/rutas.dart';
import 'package:creafacil_admin/core/widgets/cf_logo.dart';
import 'package:creafacil_admin/features/autenticacion/domain/sesion.dart';
import 'package:creafacil_admin/features/autenticacion/domain/usuario.dart';
import 'package:creafacil_admin/features/autenticacion/presentation/acceso_page.dart';
import 'package:creafacil_admin/features/autenticacion/presentation/sesion_controller.dart';
import 'package:creafacil_admin/features/autenticacion/presentation/widgets/formulario_acceso.dart';
import 'package:creafacil_admin/features/panel/presentation/admin_shell.dart';
import 'package:creafacil_admin/features/panel/presentation/usuario_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_prueba.dart';
import '../../helpers/envolver.dart';
import '../../helpers/sesion_falsa.dart';

void main() {
  late AlmacenSesionMemoria almacen;
  late RepositorioAutenticacionFalso repositorio;

  setUp(() {
    almacen = AlmacenSesionMemoria();
    repositorio = RepositorioAutenticacionFalso();
  });

  Future<void> montar(
    WidgetTester tester, {
    String? ruta,
    double ancho = 1280,
  }) async {
    fijarVentana(tester, ancho, 1000);
    await montarApp(
      tester,
      almacen: almacen,
      repositorio: repositorio,
      ruta: ruta,
    );
  }

  String ruta(WidgetTester tester) =>
      rutaActual(ProviderScopeHelper.contenedor(tester));

  Future<void> escribir(WidgetTester tester, Key clave, String texto) =>
      tester.enterText(find.byKey(clave), texto);

  Future<void> entrar(WidgetTester tester) async {
    await escribir(tester, FormularioAcceso.claveEmail, 'admin@creafacil.test');
    await escribir(tester, FormularioAcceso.clavePassword, 'secreta123');
    await tester.tap(find.byKey(FormularioAcceso.claveEnviar));
    await tester.pumpAndSettle();
  }

  group('guardia activa', () {
    testWidgets('sin sesión, el panel abre en /acceso fuera del AdminShell', (
      tester,
    ) async {
      await montar(tester);
      expect(ruta(tester), Rutas.acceso);
      expect(find.byType(AdminShell), findsNothing);
      expect(find.byType(AccesoPage), findsOneWidget);
      expect(find.byType(CfLogo), findsOneWidget);
      // Solo inicia sesión: sin registro ni recuperación de contraseña.
      expect(find.text('Crear cuenta'), findsNothing);
      expect(find.textContaining('Olvidaste'), findsNothing);
    });

    testWidgets(
      'abrir una sección sin sesión lleva a /acceso y vuelve tras entrar',
      (tester) async {
        await montar(tester, ruta: Rutas.agenda);
        expect(ruta(tester), '/acceso?desde=%2Fagenda');

        await entrar(tester);
        expect(ruta(tester), Rutas.agenda);
        expect(find.byType(AdminShell), findsOneWidget);
        expect(find.textContaining('Disponible en la Fase 5.'), findsOneWidget);
      },
    );

    testWidgets('con sesión ADMIN, /acceso redirige a Inicio', (tester) async {
      almacen.sesion = sesionPrueba();
      await montar(tester, ruta: Rutas.acceso);
      expect(ruta(tester), Rutas.inicio);
      expect(find.text('Panel administrativo'), findsOneWidget);
    });
  });

  group('iniciar sesión', () {
    testWidgets('ADMIN: entra al panel con su nombre en la cabecera', (
      tester,
    ) async {
      await montar(tester);
      await entrar(tester);

      expect(ruta(tester), Rutas.inicio);
      expect(repositorio.llamadas, ['login:admin@creafacil.test']);
      expect(almacen.sesion?.usuario.rol, RolUsuario.admin);
      expect(
        tester.widget<Text>(find.byKey(AccionesUsuarioPanel.claveNombre)).data,
        'Rosalía',
      );
    });

    testWidgets('CLIENTE: rechazo y la sesión no se guarda', (tester) async {
      repositorio.alIniciar = (_, _) async =>
          sesionPrueba(usuario: clientePrueba);
      await montar(tester);
      await entrar(tester);

      expect(find.text('Acceso solo para la administradora.'), findsOneWidget);
      expect(almacen.guardados, 0);
      expect(ruta(tester), Rutas.acceso);
    });

    testWidgets('valida en el cliente sin llamar a la API', (tester) async {
      await montar(tester);
      await tester.tap(find.byKey(FormularioAcceso.claveEnviar));
      await tester.pump();
      expect(find.text('El correo electrónico es obligatorio'), findsOneWidget);
      expect(find.text('La contraseña es obligatoria'), findsOneWidget);
      expect(repositorio.llamadas, isEmpty);
    });

    for (final (estado, codigo, texto) in [
      (401, 'CREDENCIALES_INVALIDAS', 'Correo o contraseña incorrectos.'),
      (403, 'CUENTA_DESACTIVADA', 'Tu cuenta está desactivada.'),
      (
        429,
        'DEMASIADOS_INTENTOS',
        'Demasiados intentos de inicio de sesión. Inténtalo de nuevo en 15 minutos.',
      ),
    ]) {
      testWidgets('muestra el error $estado $codigo', (tester) async {
        repositorio.alIniciar = (_, _) async =>
            throw errorApi(estado, codigo, texto);
        await montar(tester);
        await entrar(tester);
        expect(
          tester
              .widget<CfMessage>(find.byKey(FormularioAcceso.claveError))
              .text,
          texto,
        );
        expect(ruta(tester), Rutas.acceso);
      });
    }

    testWidgets('estado de carga sin envíos dobles', (tester) async {
      final respuesta = Completer<Sesion>();
      repositorio.alIniciar = (_, _) => respuesta.future;
      await montar(tester);
      await escribir(tester, FormularioAcceso.claveEmail, 'admin@x.co');
      await escribir(tester, FormularioAcceso.clavePassword, 'secreta123');
      await tester.tap(find.byKey(FormularioAcceso.claveEnviar));
      await tester.pump();
      expect(find.text('Iniciando sesión…'), findsOneWidget);
      await tester.tap(find.byKey(FormularioAcceso.claveEnviar));
      await tester.pump();
      expect(repositorio.llamadas, hasLength(1));
      respuesta.complete(sesionPrueba());
      await tester.pumpAndSettle();
      expect(ruta(tester), Rutas.inicio);
    });
  });

  group('restauración y cierre', () {
    testWidgets(
      'al recargar se restaura la sesión (expiraEn + GET /auth/perfil)',
      (tester) async {
        almacen.sesion = sesionPrueba();
        final perfil = Completer<Usuario>();
        repositorio.alPerfil = (_) => perfil.future;
        fijarVentana(tester, 1280, 1000);
        await montarAppSinEsperar(tester, almacen, repositorio);
        expect(find.text(AccesoPage.textoRestaurando), findsOneWidget);

        perfil.complete(adminPrueba);
        await tester.pumpAndSettle();
        expect(repositorio.llamadas, ['perfil']);
        expect(ruta(tester), Rutas.inicio);
        expect(find.byKey(AccionesUsuarioPanel.claveNombre), findsOneWidget);
      },
    );

    testWidgets('sesión caducada al recargar: /acceso con el aviso', (
      tester,
    ) async {
      almacen.sesion = sesionPrueba(vigencia: const Duration(hours: -1));
      await montar(tester, ruta: Rutas.reportes);
      expect(ruta(tester), '/acceso?desde=%2Freportes');
      expect(find.text(SesionController.avisoSesionExpirada), findsOneWidget);
    });

    testWidgets('un 401 durante el uso vuelve a /acceso con el aviso', (
      tester,
    ) async {
      almacen.sesion = sesionPrueba();
      await montar(tester, ruta: Rutas.agenda);
      final contenedor = ProviderScopeHelper.contenedor(tester);

      contenedor.read(proveedorTokenProvider).tokenRechazado();
      await tester.pumpAndSettle();

      expect(ruta(tester), '/acceso?desde=%2Fagenda');
      expect(find.byKey(FormularioAcceso.claveAviso), findsOneWidget);
      expect(find.text(SesionController.avisoSesionExpirada), findsOneWidget);
      expect(almacen.sesion, isNull);
    });

    testWidgets('un 401 en Inicio también vuelve a /acceso', (tester) async {
      almacen.sesion = sesionPrueba();
      await montar(tester);
      ProviderScopeHelper.contenedor(tester)
          .read(proveedorTokenProvider)
          .tokenRechazado();
      await tester.pumpAndSettle();
      expect(ruta(tester), Rutas.acceso);
      expect(find.text(SesionController.avisoSesionExpirada), findsOneWidget);
    });

    testWidgets('cerrar sesión pide confirmación y vuelve a /acceso', (
      tester,
    ) async {
      almacen.sesion = sesionPrueba();
      await montar(tester, ruta: Rutas.catalogo);

      await tester.tap(find.byKey(AccionesUsuarioPanel.claveCerrarSesion));
      await tester.pumpAndSettle();
      expect(
        find.text('¿Quieres cerrar tu sesión en el panel de CreaFácil?'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(CfConfirmDialog.claveCancelar));
      await tester.pumpAndSettle();
      expect(ruta(tester), Rutas.catalogo);

      await tester.tap(find.byKey(AccionesUsuarioPanel.claveCerrarSesion));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CfConfirmDialog.claveConfirmar));
      await tester.pumpAndSettle();
      expect(ruta(tester), startsWith(Rutas.acceso));
      expect(almacen.sesion, isNull);
      expect(find.text(SesionController.avisoSesionExpirada), findsNothing);
    });

    testWidgets('móvil: nombre en el menú y botón de cerrar sesión', (
      tester,
    ) async {
      almacen.sesion = sesionPrueba();
      await montar(tester, ancho: 375);
      expect(find.byKey(AccionesUsuarioPanel.claveNombre), findsNothing);
      expect(
        find.byKey(AccionesUsuarioPanel.claveCerrarSesion),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Abrir el menú de navegación'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(UsuarioMenuPanel.clave),
          matching: find.text('Rosalía'),
        ),
        findsOneWidget,
      );
      expect(find.text('Administradora'), findsOneWidget);
    });
  });

  group('diseño adaptable', () {
    for (final ancho in [375.0, 768.0, 1280.0]) {
      testWidgets('acceso sin desbordes a ${ancho.toInt()} px', (tester) async {
        await montar(tester, ancho: ancho);
        expect(tester.takeException(), isNull);
        final tarjeta = tester.getRect(find.byKey(AccesoPage.claveTarjeta));
        expect(tarjeta.left, greaterThanOrEqualTo(0));
        expect(tarjeta.right, lessThanOrEqualTo(ancho));
        expect(tarjeta.width, lessThanOrEqualTo(440));
      });

      testWidgets('panel con sesión sin desbordes a ${ancho.toInt()} px', (
        tester,
      ) async {
        almacen.sesion = sesionPrueba(
          usuario: const Usuario(
            id: 'x',
            nombre: 'Rosalía Administradora de Creaciones con nombre largo',
            email: 'a@b.co',
            rol: RolUsuario.admin,
          ),
        );
        repositorio.alPerfil = (_) async => almacen.sesion!.usuario;
        await montar(tester, ancho: ancho);
        expect(tester.takeException(), isNull);
        expect(find.byType(AdminShell), findsOneWidget);
      });
    }
  });
}
