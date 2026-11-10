import 'package:creafacil_admin/app.dart';
import 'package:creafacil_admin/core/theme/app_colors.dart';
import 'package:creafacil_admin/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el inicio del panel administrativo', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CreaFacilAdminApp()));
    await tester.pumpAndSettle();

    expect(find.text('CreaFácil'), findsOneWidget);
    expect(find.text('Panel administrativo'), findsOneWidget);
  });

  test('el tema usa la paleta oficial', () {
    final tema = AppTheme.claro();
    expect(tema.colorScheme.primary, AppColors.primario);
    expect(tema.colorScheme.secondary, AppColors.complementario);
    expect(tema.colorScheme.tertiary, AppColors.terciario);
    expect(tema.scaffoldBackgroundColor, AppColors.fondo);
    expect(tema.colorScheme.onSurface, AppColors.texto);
  });
}
