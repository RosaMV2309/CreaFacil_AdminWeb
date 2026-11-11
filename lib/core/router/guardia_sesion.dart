import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rutas.dart';

/// Roles que devuelve la API (`ADMIN` o `CLIENTE`).
enum RolUsuario { admin, cliente }

/// Sesión del panel. En la Fase 0 todavía no hay inicio de sesión.
class SesionPanel {
  const SesionPanel({this.rol});
  const SesionPanel.sinSesion() : rol = null;

  final RolUsuario? rol;

  bool get iniciada => rol != null;
  bool get esAdmin => rol == RolUsuario.admin;
}

/// Sesión actual del panel.
///
/// TODO(Fase 1, RF-01 y RF-02): leer la sesión real (token JWT y rol
/// devueltos por la API) y notificar al router cuando cambie.
final sesionPanelProvider = Provider<SesionPanel>(
  (ref) => const SesionPanel.sinSesion(),
);

/// Protección de rutas por rol. **Desactivada** en la Fase 0 porque aún no
/// existe el inicio de sesión.
///
/// TODO(Fase 1, RF-01 y RF-02): activar cuando exista [Rutas.acceso].
const proteccionPorRolActiva = false;

/// Esqueleto de la redirección del router por sesión y rol `ADMIN`.
///
/// Es solo navegación: los permisos reales los comprueba siempre el servidor
/// (RN-05) y la API responde 401 o 403 aunque la interfaz fallara.
///
/// Devuelve la ruta a la que redirigir o `null` para continuar.
String? redireccionPorSesion({
  required SesionPanel sesion,
  required String ubicacion,
  bool activa = proteccionPorRolActiva,
}) {
  if (!activa || ubicacion == Rutas.acceso) {
    return null;
  }
  // Sin sesión o con rol CLIENTE: el panel exige el rol ADMIN.
  if (!sesion.esAdmin) {
    return Rutas.acceso;
  }
  return null;
}
