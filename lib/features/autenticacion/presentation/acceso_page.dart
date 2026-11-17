import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/cf_components.dart';
import '../../../core/widgets/cf_logo.dart';
import '../../../core/widgets/responsive_layout.dart';
import 'autenticacion_providers.dart';
import 'widgets/formulario_acceso.dart';

/// «Iniciar sesión» del panel administrativo [RF-01][RF-02][RNF-03].
///
/// Fuera del `AdminShell`: logotipo y tarjeta centrados. Solo inicia sesión
/// (no hay registro en el panel). Si entra un CLIENTE, se rechaza sin guardar
/// la sesión. Mientras se restaura la sesión guardada muestra un indicador.
class AccesoPage extends ConsumerWidget {
  const AccesoPage({this.desde, super.key});

  /// Ruta a la que volver tras iniciar sesión (la conserva el router).
  final String? desde;

  static const claveTarjeta = ValueKey('acceso-panel-tarjeta');
  static const textoRestaurando = 'Comprobando tu sesión…';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    final tamano = PuntosCorte.deContexto(context);
    final movil = tamano == TamanoPantalla.movil;
    final restaurando = ref.watch(sesionControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              movil ? tokens.espacioLg : tokens.espacioXl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: CfLogo(size: movil ? 120 : 160)),
                  SizedBox(height: tokens.espacioLg),
                  Text(
                    'Panel administrativo',
                    textAlign: TextAlign.center,
                    style: textos.titleMedium,
                  ),
                  SizedBox(height: tokens.espacioXl),
                  CfCard(
                    key: claveTarjeta,
                    title: 'Iniciar sesión',
                    subtitle: 'Acceso para la administradora de CreaFácil.',
                    padding: EdgeInsets.all(
                      movil ? tokens.espacioXl : tokens.espacioXxl,
                    ),
                    child: restaurando
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CfSpinner(label: textoRestaurando),
                            ),
                          )
                        : const FormularioAcceso(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
