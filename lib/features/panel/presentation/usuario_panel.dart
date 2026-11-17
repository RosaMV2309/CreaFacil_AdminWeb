import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/cf_components.dart';
import '../../../core/theme/app_colors.dart';
import '../../autenticacion/presentation/autenticacion_providers.dart';

/// Pide confirmación y cierra la sesión del panel [RF-01]. El router lleva
/// después a `/acceso`.
Future<void> confirmarCierreSesion(BuildContext context, WidgetRef ref) async {
  final controlador = ref.read(sesionControllerProvider.notifier);
  final confirmado = await CfConfirmDialog.mostrar(
    context,
    titulo: 'Cerrar sesión',
    mensaje: '¿Quieres cerrar tu sesión en el panel de CreaFácil?',
    textoConfirmar: 'Cerrar sesión',
    peligro: true,
    icono: Icons.logout_rounded,
  );
  if (confirmado) {
    await controlador.cerrarSesion();
  }
}

/// Nombre de la administradora y botón «Cerrar sesión» para la cabecera
/// azul del panel. En móvil ([compacto]) solo se muestra el botón: el nombre
/// aparece en el menú desplegable.
class AccionesUsuarioPanel extends ConsumerWidget {
  const AccionesUsuarioPanel({this.compacto = false, super.key});

  final bool compacto;

  static const claveNombre = ValueKey('panel-usuario-nombre');
  static const claveCerrarSesion = ValueKey('panel-cerrar-sesion');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioActualProvider);
    if (usuario == null) {
      return const SizedBox.shrink();
    }
    final tokens = CfTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compacto) ...[
          const ExcludeSemantics(
            child: Icon(Icons.account_circle_outlined, color: AppColors.blanco),
          ),
          SizedBox(width: tokens.espacioSm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              usuario.nombre,
              key: claveNombre,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: AppColors.blanco),
            ),
          ),
          SizedBox(width: tokens.espacioXs),
        ],
        IconButton(
          key: claveCerrarSesion,
          tooltip: 'Cerrar sesión',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => confirmarCierreSesion(context, ref),
        ),
        SizedBox(width: tokens.espacioSm),
      ],
    );
  }
}

/// Nombre de la administradora en el menú desplegable (móvil).
class UsuarioMenuPanel extends ConsumerWidget {
  const UsuarioMenuPanel({super.key});

  static const clave = ValueKey('panel-menu-usuario');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioActualProvider);
    if (usuario == null) {
      return const SizedBox.shrink();
    }
    final textos = Theme.of(context).textTheme;
    return Row(
      key: clave,
      children: [
        Icon(
          Icons.account_circle_outlined,
          color: AppColors.blanco.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario.nombre,
                overflow: TextOverflow.ellipsis,
                style: textos.titleSmall?.copyWith(color: AppColors.blanco),
              ),
              Text(
                usuario.rol.etiqueta,
                style: textos.bodySmall?.copyWith(color: AppColors.blanco),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
