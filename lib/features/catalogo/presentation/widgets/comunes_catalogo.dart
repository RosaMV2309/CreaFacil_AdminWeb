import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design_system/cf_components.dart';
import '../../../../core/network/red.dart';
import '../catalogo_providers.dart';

/// Mensaje para un `CfMessage` (título, texto y severidad).
class AvisoCatalogo {
  const AvisoCatalogo(this.texto, {this.titulo, this.severidad});

  /// Aviso de error a partir de una [ApiException] (404, 409, sin conexión…).
  factory AvisoCatalogo.desdeError(ApiException error) => AvisoCatalogo(
    error.mensaje,
    titulo: switch (error.estadoHttp) {
      409 => 'Nombre repetido',
      404 => 'No encontrado',
      400 => 'Revisa los datos',
      _ => switch (error.tipo) {
        TipoErrorApi.sinConexion => 'Sin conexión',
        TipoErrorApi.tiempoAgotado => 'Sin respuesta',
        TipoErrorApi.prohibido => 'Sin permiso',
        _ => 'No se pudo guardar',
      },
    },
    severidad: CfMessageSeverity.error,
  );

  final String texto;
  final String? titulo;
  final CfMessageSeverity? severidad;

  Widget mostrar({VoidCallback? onClose, Key? key}) => CfMessage(
    key: key,
    title: titulo,
    text: texto,
    severity: severidad ?? CfMessageSeverity.success,
    onClose: onClose,
  );
}

/// Errores de un formulario tras un fallo de la API:
/// - 400 VALIDACION: cada detalle en su campo; los demás, en [aviso].
/// - 404, 409 y el resto: en [aviso] (un `CfMessage`).
class ErroresFormulario {
  const ErroresFormulario({this.porCampo = const {}, this.aviso});

  factory ErroresFormulario.desde(ApiException error, Set<String> campos) {
    if (error.estadoHttp != 400 || error.detalles.isEmpty) {
      return ErroresFormulario(aviso: AvisoCatalogo.desdeError(error));
    }
    final porCampo = <String, String>{};
    final otros = <String>[];
    for (final d in error.detalles) {
      if (d.campo != null && campos.contains(d.campo)) {
        porCampo.putIfAbsent(d.campo!, () => d.mensaje);
      } else {
        otros.add(d.mensaje);
      }
    }
    return ErroresFormulario(
      porCampo: porCampo,
      aviso: otros.isEmpty
          ? null
          : AvisoCatalogo(
              otros.join('\n'),
              titulo: 'Revisa los datos',
              severidad: CfMessageSeverity.error,
            ),
    );
  }

  final Map<String, String> porCampo;
  final AvisoCatalogo? aviso;
}

/// Opciones del filtro por estado.
List<CfOpcion<FiltroEstado>> opcionesEstado({required bool femenino}) => [
  CfOpcion(FiltroEstado.todos, femenino ? 'Todas' : 'Todos'),
  CfOpcion(FiltroEstado.activos, femenino ? 'Activas' : 'Activos'),
  CfOpcion(FiltroEstado.inactivos, femenino ? 'Inactivas' : 'Inactivos'),
];

/// Encabezado de una pestaña: título, descripción y botón principal.
class EncabezadoCatalogo extends StatelessWidget {
  const EncabezadoCatalogo({
    required this.titulo,
    required this.descripcion,
    required this.accion,
    super.key,
  });

  final String titulo;
  final String descripcion;
  final Widget accion;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: tokens.espacioLg,
      runSpacing: tokens.espacioMd,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(titulo, style: textos.headlineSmall),
              ),
              SizedBox(height: tokens.espacioXs),
              Text(descripcion, style: textos.bodyMedium),
            ],
          ),
        ),
        accion,
      ],
    );
  }
}

/// Buscador (con espera de 400 ms al escribir) y filtro por estado.
class BarraFiltros extends StatefulWidget {
  const BarraFiltros({
    required this.etiquetaBusqueda,
    required this.textoInicial,
    required this.onBuscar,
    required this.filtro,
    super.key,
  });

  final String etiquetaBusqueda;
  final String textoInicial;
  final ValueChanged<String> onBuscar;

  /// Normalmente un `CfSelect` con el estado.
  final Widget filtro;

  static const espera = Duration(milliseconds: 400);
  static const claveBuscador = ValueKey('catalogo-buscador');

  @override
  State<BarraFiltros> createState() => _BarraFiltrosState();
}

class _BarraFiltrosState extends State<BarraFiltros> {
  late final _texto = TextEditingController(text: widget.textoInicial);
  Timer? _temporizador;

  @override
  void dispose() {
    _temporizador?.cancel();
    _texto.dispose();
    super.dispose();
  }

  void _alEscribir(String valor) {
    _temporizador?.cancel();
    _temporizador = Timer(BarraFiltros.espera, () => widget.onBuscar(valor));
  }

  void _buscarYa(String valor) {
    _temporizador?.cancel();
    widget.onBuscar(valor);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final buscador = CfInputText(
      key: BarraFiltros.claveBuscador,
      label: widget.etiquetaBusqueda,
      controller: _texto,
      prefixIcon: Icons.search_rounded,
      textInputAction: TextInputAction.search,
      maxLength: 100,
      onChanged: _alEscribir,
      onSubmitted: _buscarYa,
    );
    return LayoutBuilder(
      builder: (context, restricciones) {
        if (restricciones.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buscador,
              SizedBox(height: tokens.espacioMd),
              widget.filtro,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: buscador),
            SizedBox(width: tokens.espacioMd),
            SizedBox(width: 220, child: widget.filtro),
          ],
        );
      },
    );
  }
}

/// Estructura común de las pestañas: desplazable, centrada y con el ancho
/// máximo del panel [RNF-05].
class PaginaCatalogo extends StatelessWidget {
  const PaginaCatalogo({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final movil = MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.all(movil ? tokens.espacioLg : tokens.espacioXl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de estado (activa o inactiva).
CfTag etiquetaEstado({required bool activo, required bool femenino}) => CfTag(
  label: activo
      ? (femenino ? 'Activa' : 'Activo')
      : (femenino ? 'Inactiva' : 'Inactivo'),
  severity: activo ? CfTagSeverity.success : CfTagSeverity.neutral,
  icon: activo ? Icons.check_rounded : Icons.pause_rounded,
  rounded: true,
);
