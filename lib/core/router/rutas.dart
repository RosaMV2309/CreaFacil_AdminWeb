/// Rutas del panel administrativo (go_router).
abstract final class Rutas {
  /// Inicio (dashboard).
  static const inicio = '/';

  /// Catálogo: categorías, servicios y materiales (Fase 2).
  static const catalogo = '/catalogo';

  /// Precios, mano de obra y factor de complejidad (Fase 3).
  static const precios = '/precios';

  /// Cotizaciones (Fase 3).
  static const cotizaciones = '/cotizaciones';

  /// Solicitudes y pedidos (Fase 4).
  static const pedidos = '/pedidos';

  /// Agenda (Fase 5).
  static const agenda = '/agenda';

  /// Reportes (Fase 7).
  static const reportes = '/reportes';

  /// Inicio de sesión de la administradora (RF-01 y RF-02). Fuera del
  /// AdminShell y sin protección.
  static const acceso = '/acceso';

  /// Catálogo de componentes Cf*. Solo existe en modo debug.
  static const componentes = '/dev/componentes';

  /// Parámetro de consulta con el destino al que volver tras iniciar sesión.
  static const parametroDesde = 'desde';

  /// `/acceso?desde=<destino>` (o `/acceso` si no hay destino).
  static String accesoDesde(String? destino) => destino == null
      ? acceso
      : Uri(
          path: acceso,
          queryParameters: {parametroDesde: destino},
        ).toString();
}
