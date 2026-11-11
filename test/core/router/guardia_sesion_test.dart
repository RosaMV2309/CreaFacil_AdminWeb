import 'package:creafacil_admin/core/router/guardia_sesion.dart';
import 'package:creafacil_admin/core/router/rutas.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Fase 0: la protección está desactivada y deja pasar', () {
    expect(proteccionPorRolActiva, isFalse);
    expect(
      redireccionPorSesion(
        sesion: const SesionPanel.sinSesion(),
        ubicacion: Rutas.agenda,
      ),
      isNull,
    );
  });

  test('la sesión de la Fase 0 es «sin sesión»', () {
    final contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);
    final sesion = contenedor.read(sesionPanelProvider);
    expect(sesion.iniciada, isFalse);
    expect(sesion.esAdmin, isFalse);
  });

  group('activada (esqueleto para la Fase 1)', () {
    String? redirigir(SesionPanel sesion, String ubicacion) =>
        redireccionPorSesion(
          sesion: sesion,
          ubicacion: ubicacion,
          activa: true,
        );

    test('sin sesión → inicio de sesión', () {
      expect(
        redirigir(const SesionPanel.sinSesion(), Rutas.inicio),
        Rutas.acceso,
      );
    });

    test('rol CLIENTE → inicio de sesión (RN-05)', () {
      expect(
        redirigir(const SesionPanel(rol: RolUsuario.cliente), Rutas.reportes),
        Rutas.acceso,
      );
    });

    test('rol ADMIN → continúa', () {
      expect(
        redirigir(const SesionPanel(rol: RolUsuario.admin), Rutas.reportes),
        isNull,
      );
    });

    test('la propia ruta de acceso no se redirige', () {
      expect(redirigir(const SesionPanel.sinSesion(), Rutas.acceso), isNull);
    });
  });
}
