import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/autenticacion/presentation/acceso_page.dart';
import '../../features/autenticacion/presentation/autenticacion_providers.dart';
import '../../features/catalogo/presentation/catalogo_page.dart';
import '../../features/dev/presentation/componentes_page.dart';
import '../../features/inicio/presentation/inicio_page.dart';
import '../../features/panel/presentation/admin_shell.dart';
import '../../features/panel/presentation/seccion_pendiente_page.dart';
import '../../features/panel/presentation/secciones_panel.dart';
import 'guardia_sesion.dart';
import 'rutas.dart';

export 'rutas.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Avisa al router cada vez que cambia la sesión para reevaluar `redirect`.
  final refresco = ValueNotifier<int>(0);
  late final GoRouter router;

  ref.listen(sesionControllerProvider, (anterior, siguiente) {
    final teniaSesion = anterior?.value?.iniciada ?? false;
    final estado = siguiente.value;
    // Sesión caducada o 401: al inicio de sesión con el aviso, recordando la
    // sección. La ubicación se toma ANTES de refrescar el router.
    if (teniaSesion &&
        estado != null &&
        !estado.iniciada &&
        estado.aviso != null) {
      final actual = router.routerDelegate.currentConfiguration.uri;
      final desde = actual.path == Rutas.acceso || actual.path == Rutas.inicio
          ? null
          : actual.toString();
      router.go(Rutas.accesoDesde(desde));
    }
    refresco.value++;
  });

  router = GoRouter(
    initialLocation: Rutas.inicio,
    refreshListenable: refresco,
    // Guardia activa: el panel exige una sesión con rol ADMIN [RF-02][RNF-03].
    redirect: (context, state) => redireccionPorSesion(
      estado: ref.read(sesionControllerProvider),
      uri: state.uri,
    ),
    routes: [
      // Inicio de sesión, fuera del AdminShell.
      GoRoute(
        path: Rutas.acceso,
        builder: (context, state) =>
            AccesoPage(desde: state.uri.queryParameters[Rutas.parametroDesde]),
      ),
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
          GoRoute(
            path: Rutas.catalogo,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const CatalogoPage(),
            ),
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

  ref.onDispose(() {
    router.dispose();
    refresco.dispose();
  });
  return router;
});
