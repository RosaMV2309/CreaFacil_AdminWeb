import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/autenticacion/presentation/estado_sesion.dart';
import 'rutas.dart';

/// Protección de las rutas del panel por sesión y rol `ADMIN`. **Activa**
/// desde la Fase 1 (RF-01, RF-02 y RNF-03).
const proteccionPorRolActiva = true;

/// Redirección del router por sesión y rol `ADMIN`.
///
/// - Sin sesión de administradora (o mientras se restaura), cualquier ruta
///   del panel va a `/acceso?desde=<ruta>`.
/// - Con sesión ADMIN, `/acceso` lleva al destino guardado o a Inicio.
/// - El catálogo `/dev/componentes` (solo en debug) no se protege.
///
/// Es solo navegación: los permisos reales los comprueba siempre el servidor
/// (RN-05) y la API responde 401 o 403 aunque la interfaz fallara.
///
/// Devuelve la ruta a la que redirigir o `null` para continuar.
String? redireccionPorSesion({
  required AsyncValue<EstadoSesion> estado,
  required Uri uri,
  bool activa = proteccionPorRolActiva,
}) {
  final ruta = uri.path;
  if (!activa || ruta == Rutas.componentes) {
    return null;
  }
  final esAdmin = estado.value?.usuario?.esAdmin ?? false;

  if (ruta == Rutas.acceso) {
    return esAdmin
        ? destinoSeguro(uri.queryParameters[Rutas.parametroDesde]) ??
              Rutas.inicio
        : null;
  }
  if (!esAdmin) {
    return Rutas.accesoDesde(ruta == Rutas.inicio ? null : uri.toString());
  }
  return null;
}

/// Acepta solo destinos internos del panel (evita redirecciones abiertas).
String? destinoSeguro(String? destino) {
  if (destino == null ||
      !destino.startsWith('/') ||
      destino.startsWith('//') ||
      destino.contains('\\')) {
    return null;
  }
  final ruta = Uri.tryParse(destino)?.path;
  if (ruta == null || ruta == Rutas.acceso) {
    return null;
  }
  return destino;
}
