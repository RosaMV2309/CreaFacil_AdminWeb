import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dev/presentation/componentes_page.dart';
import '../../features/inicio/presentation/inicio_page.dart';
import '../../features/panel/presentation/admin_shell.dart';
import '../../features/panel/presentation/seccion_pendiente_page.dart';
import '../../features/panel/presentation/secciones_panel.dart';
import 'guardia_sesion.dart';
import 'rutas.dart';

export 'rutas.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Rutas.inicio,
    // Esqueleto de la protección por sesión y rol ADMIN. Hoy es permisivo.
    // TODO(Fase 1, RF-01 y RF-02): activar y refrescar al cambiar la sesión.
    redirect: (context, state) => redireccionPorSesion(
      sesion: ref.read(sesionPanelProvider),
      ubicacion: state.matchedLocation,
    ),
    routes: [
      // Secciones del panel dentro del AdminShell (menú adaptable).
      ShellRoute(
        builder: (context, state, child) =>
            AdminShell(ubicacion: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: Rutas.inicio,
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const InicioPage()),
          ),
          for (final seccion in SeccionesPanel.pendientes)
            GoRoute(
              path: seccion.ruta,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: SeccionPendientePage(seccion: seccion),
              ),
            ),
        ],
      ),
      // Catálogo de componentes para revisión visual: solo en modo debug,
      // no existe en las compilaciones de perfil ni de producción.
      if (kDebugMode)
        GoRoute(
          path: Rutas.componentes,
          builder: (context, state) => const ComponentesPage(),
        ),
    ],
  );
});
