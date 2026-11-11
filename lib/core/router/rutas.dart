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

  /// Inicio de sesión de la administradora. Prevista para la Fase 1
  /// (RF-01 y RF-02); todavía no existe.
  static const acceso = '/acceso';

  /// Catálogo de componentes Cf*. Solo existe en modo debug.
  static const componentes = '/dev/componentes';
}
