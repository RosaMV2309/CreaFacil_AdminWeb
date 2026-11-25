import 'package:creafacil_admin/core/network/red.dart';
import 'package:creafacil_admin/features/catalogo/domain/entidades_catalogo.dart';
import 'package:creafacil_admin/features/catalogo/domain/precio.dart';
import 'package:creafacil_admin/features/catalogo/presentation/catalogo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/catalogo_falso.dart';

ProviderContainer _contenedor({
  RepositorioCategoriasFalso? categorias,
  RepositorioMaterialesFalso? materiales,
}) {
  final c = ProviderContainer(
    overrides: catalogoSimulado(categorias: categorias, materiales: materiales),
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('CategoriasController', () {
    test('carga, filtra y recarga tras crear y cambiar el estado', () async {
      final repo = RepositorioCategoriasFalso([
        categoriaPrueba(),
        categoriaPrueba(id: 'c2', nombre: 'Cuadros', activa: false),
      ]);
      final c = _contenedor(categorias: repo);
      c.listen(categoriasControllerProvider, (_, _) {});

      expect(await c.read(categoriasControllerProvider.future), hasLength(2));

      c.read(filtroCategoriasProvider.notifier)
        ..buscar(' cua ')
        ..buscar('cua');
      c
          .read(filtroCategoriasProvider.notifier)
          .filtrarPorEstado(FiltroEstado.inactivos);
      final filtradas = await c.read(categoriasControllerProvider.future);
      expect(filtradas.single.nombre, 'Cuadros');
      expect(repo.llamadas.last, 'listar:cua:false');

      final ctrl = c.read(categoriasControllerProvider.notifier);
      await ctrl.crear(const DatosCategoria(nombre: 'Cuadros 2'));
      await c.read(categoriasControllerProvider.future);
      final r = await ctrl.cambiarEstado(repo.categorias[1], activa: true);
      expect(r.activa, isTrue);
      expect(repo.ultimosCambios, {'activa': true});
      await ctrl.recargar();
      // Con el filtro «inactivas», la categoría recién activada ya no sale.
      expect(await c.read(categoriasControllerProvider.future), isEmpty);
    });

    test('los errores de la API llegan al estado sin reintentos', () async {
      final repo = RepositorioCategoriasFalso()
        ..errorListar = errorCatalogo(403, 'PROHIBIDO', 'Sin permiso.');
      final c = _contenedor(categorias: repo);
      c.listen(categoriasControllerProvider, (_, _) {});
      await expectLater(
        c.read(categoriasControllerProvider.future),
        throwsA(isA<ApiException>()),
      );
      expect(repo.llamadas, hasLength(1));
    });
  });

  group('MaterialesController', () {
    test('paginación, búsqueda que vuelve a la página 1 y edición', () async {
      final repo = RepositorioMaterialesFalso([
        for (var i = 0; i < 25; i++)
          materialPrueba(id: 'm$i', nombre: 'Material ${i + 10}'),
      ]);
      final c = _contenedor(materiales: repo);
      c.listen(materialesControllerProvider, (_, _) {});

      var p = await c.read(materialesControllerProvider.future);
      expect((p.total, p.totalPaginas, p.datos.length), (25, 2, 20));

      c.read(filtroMaterialesProvider.notifier).irAPagina(2);
      p = await c.read(materialesControllerProvider.future);
      expect((p.pagina, p.datos.length), (2, 5));

      c.read(filtroMaterialesProvider.notifier)
        ..buscar('Material 3')
        ..filtrarPorEstado(FiltroEstado.activos);
      p = await c.read(materialesControllerProvider.future);
      expect(p.pagina, 1);
      expect(repo.llamadas.last, 'listar:1:Material 3:true');

      final ctrl = c.read(materialesControllerProvider.notifier);
      final nuevo = await ctrl.crear(
        DatosMaterial(
          nombre: 'Lienzo',
          unidad: 'metro',
          precioUnitario: Precio.intentar('4.5')!,
        ),
      );
      expect(nuevo.precioUnitario.formateado, r'$ 4,50');
      final editado = await ctrl.actualizar(nuevo.id, {
        'precioUnitario': '5.25',
      });
      expect(editado.precioUnitario.textoApi, '5.25');
      final inactivo = await ctrl.cambiarEstado(editado, activo: false);
      expect(inactivo.activo, isFalse);
      await ctrl.recargar();
      await c.read(materialesControllerProvider.future);
    });
  });
}
