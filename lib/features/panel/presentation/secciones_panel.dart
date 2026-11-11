import 'package:flutter/material.dart';

import '../../../core/router/rutas.dart';

/// Sección del menú del panel administrativo.
class SeccionPanel {
  const SeccionPanel({
    required this.titulo,
    required this.etiquetaCorta,
    required this.ruta,
    required this.icono,
    required this.iconoSeleccionado,
    required this.fase,
    required this.descripcion,
  });

  /// Nombre completo (menú desplegable y riel extendido).
  final String titulo;

  /// Nombre corto para el riel compacto de tablet.
  final String etiquetaCorta;
  final String ruta;
  final IconData icono;
  final IconData iconoSeleccionado;

  /// Fase del plan en la que se implementa.
  final int fase;

  /// Qué incluirá la sección y sus requisitos del DERCAS.
  final String descripcion;

  String get textoDisponibilidad => 'Disponible en la Fase $fase.';
}

/// Secciones del panel según el DERCAS.
abstract final class SeccionesPanel {
  static const inicio = SeccionPanel(
    titulo: 'Inicio',
    etiquetaCorta: 'Inicio',
    ruta: Rutas.inicio,
    icono: Icons.dashboard_outlined,
    iconoSeleccionado: Icons.dashboard_rounded,
    fase: 0,
    descripcion: 'Resumen del panel y estado del servicio.',
  );

  static const catalogo = SeccionPanel(
    titulo: 'Catálogo',
    etiquetaCorta: 'Catálogo',
    ruta: Rutas.catalogo,
    icono: Icons.inventory_2_outlined,
    iconoSeleccionado: Icons.inventory_2_rounded,
    fase: 2,
    descripcion:
        'Categorías, servicios y materiales; activar o desactivar '
        '(RF-05 y RF-22).',
  );

  static const precios = SeccionPanel(
    titulo: 'Precios',
    etiquetaCorta: 'Precios',
    ruta: Rutas.precios,
    icono: Icons.sell_outlined,
    iconoSeleccionado: Icons.sell_rounded,
    fase: 3,
    descripcion:
        'Precios de materiales, mano de obra y factor de complejidad '
        '(RF-08).',
  );

  static const cotizaciones = SeccionPanel(
    titulo: 'Cotizaciones',
    etiquetaCorta: 'Cotizaciones',
    ruta: Rutas.cotizaciones,
    icono: Icons.request_quote_outlined,
    iconoSeleccionado: Icons.request_quote_rounded,
    fase: 3,
    descripcion:
        'Lista y revisión de las cotizaciones estimadas (RF-09 y RF-11).',
  );

  static const pedidos = SeccionPanel(
    titulo: 'Solicitudes y pedidos',
    etiquetaCorta: 'Pedidos',
    ruta: Rutas.pedidos,
    icono: Icons.assignment_outlined,
    iconoSeleccionado: Icons.assignment_rounded,
    fase: 4,
    descripcion:
        'Solicitudes de los clientes, conversión en pedidos y cambio de '
        'estados (RF-12, RF-13, RF-14 y RF-21).',
  );

  static const agenda = SeccionPanel(
    titulo: 'Agenda',
    etiquetaCorta: 'Agenda',
    ruta: Rutas.agenda,
    icono: Icons.calendar_month_outlined,
    iconoSeleccionado: Icons.calendar_month_rounded,
    fase: 5,
    descripcion:
        'Calendario de trabajos, tentativas y avisos de conflicto '
        '(RF-15 a RF-19).',
  );

  static const reportes = SeccionPanel(
    titulo: 'Reportes',
    etiquetaCorta: 'Reportes',
    ruta: Rutas.reportes,
    icono: Icons.bar_chart_outlined,
    iconoSeleccionado: Icons.bar_chart_rounded,
    fase: 7,
    descripcion: 'Reportes básicos de actividad (RF-23).',
  );

  /// Todas las secciones, en el orden del menú.
  static const todas = [
    inicio,
    catalogo,
    precios,
    cotizaciones,
    pedidos,
    agenda,
    reportes,
  ];

  /// Secciones que todavía son marcadores de posición.
  static const pendientes = [
    catalogo,
    precios,
    cotizaciones,
    pedidos,
    agenda,
    reportes,
  ];

  /// Índice de la sección que corresponde a [ubicacion] (Inicio si no hay).
  static int indiceDe(String ubicacion) {
    for (var i = 1; i < todas.length; i++) {
      final ruta = todas[i].ruta;
      if (ubicacion == ruta || ubicacion.startsWith('$ruta/')) {
        return i;
      }
    }
    return 0;
  }
}
