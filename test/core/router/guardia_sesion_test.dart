import 'package:creafacil_admin/core/router/guardia_sesion.dart';
import 'package:creafacil_admin/core/router/rutas.dart';
import 'package:creafacil_admin/features/autenticacion/presentation/estado_sesion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/sesion_falsa.dart';

void main() {
  const sinSesion = AsyncData(EstadoSesion());
  final admin = AsyncData(EstadoSesion(sesion: sesionPrueba()));
  final cliente = AsyncData(
    EstadoSesion(sesion: sesionPrueba(usuario: clientePrueba)),
  );
  const cargando = AsyncLoading<EstadoSesion>();

  String? redirigir(AsyncValue<EstadoSesion> estado, String ruta) =>
      redireccionPorSesion(estado: estado, uri: Uri.parse(ruta));

  test('Fase 1: la protección por rol está ACTIVA', () {
    expect(proteccionPorRolActiva, isTrue);
  });

  test('desactivada deja pasar (solo para depurar)', () {
    expect(
      redireccionPorSesion(
        estado: sinSesion,
        uri: Uri.parse(Rutas.agenda),
        activa: false,
      ),
      isNull,
    );
  });

  test('sin sesión, todas las rutas del panel van a /acceso', () {
    expect(redirigir(sinSesion, Rutas.inicio), Rutas.acceso);
    for (final ruta in [
      Rutas.catalogo,
      Rutas.precios,
      Rutas.cotizaciones,
      Rutas.pedidos,
      Rutas.agenda,
      Rutas.reportes,
    ]) {
      expect(redirigir(sinSesion, ruta), Rutas.accesoDesde(ruta), reason: ruta);
    }
  });

  test('mientras se restaura la sesión, se espera en /acceso', () {
    expect(redirigir(cargando, Rutas.agenda), '/acceso?desde=%2Fagenda');
    expect(redirigir(cargando, Rutas.acceso), isNull);
  });

  test('rol CLIENTE → /acceso (RN-05)', () {
    expect(redirigir(cliente, Rutas.reportes), '/acceso?desde=%2Freportes');
    expect(redirigir(cliente, Rutas.acceso), isNull);
  });

  test('rol ADMIN → continúa; /acceso lleva al destino o a Inicio', () {
    expect(redirigir(admin, Rutas.reportes), isNull);
    expect(redirigir(admin, Rutas.inicio), isNull);
    expect(redirigir(admin, Rutas.acceso), Rutas.inicio);
    expect(redirigir(admin, '/acceso?desde=%2Fagenda'), Rutas.agenda);
  });

  test('el catálogo de componentes (debug) no se protege', () {
    expect(redirigir(sinSesion, Rutas.componentes), isNull);
  });

  test('destinoSeguro solo acepta rutas internas', () {
    expect(destinoSeguro(null), isNull);
    expect(destinoSeguro('https://malo.com'), isNull);
    expect(destinoSeguro('//malo.com'), isNull);
    expect(destinoSeguro(r'/\malo.com'), isNull);
    expect(destinoSeguro(Rutas.acceso), isNull);
    expect(destinoSeguro(Rutas.agenda), Rutas.agenda);
    expect(Rutas.accesoDesde(null), Rutas.acceso);
  });
}
