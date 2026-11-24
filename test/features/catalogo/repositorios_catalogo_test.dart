import 'package:creafacil_admin/core/network/red.dart';
import 'package:creafacil_admin/features/catalogo/data/catalogo_repositories_impl.dart';
import 'package:creafacil_admin/features/catalogo/domain/entidades_catalogo.dart';
import 'package:creafacil_admin/features/catalogo/domain/precio.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/api_falsa.dart';
import '../../helpers/catalogo_falso.dart';

AdaptadorHttpFalso _adaptador(int estado, Object cuerpo) =>
    AdaptadorHttpFalso((_) async => respuestaJson(estado, cuerpo));

ApiClient _cliente(AdaptadorHttpFalso adaptador) => ApiClient(
  baseUrl: 'http://api.test/api/v1',
  proveedorToken: const ProveedorTokenSinSesion(),
  dio: Dio()..httpClientAdapter = adaptador,
);

Map<String, Object?> _error(
  String codigo,
  String mensaje, [
  List<Map<String, String>> detalles = const [],
]) => {
  'error': {'codigo': codigo, 'mensaje': mensaje, 'detalles': detalles},
};

void main() {
  group('CategoriasRepositoryImpl', () {
    test('GET con q y activa → lista', () async {
      final a = _adaptador(200, {
        'datos': [jsonCategoria(), jsonCategoria(id: 'c2', activa: false)],
      });
      final lista = await CategoriasRepositoryImpl(_cliente(a))
          .listar(q: ' mur ', activa: true);

      expect(a.peticiones.single.path, '/admin/categorias');
      expect(a.peticiones.single.queryParameters, {
        'q': 'mur',
        'activa': 'true',
      });
      expect(lista, hasLength(2));
      expect(lista.first.serviciosActivos, 2);
      expect(lista.first.descripcion, isNull);
      expect(lista.last.activa, isFalse);
    });

    test('GET sin filtros no envía parámetros', () async {
      final a = _adaptador(200, {'datos': <Object>[]});
      await CategoriasRepositoryImpl(_cliente(a)).listar();
      expect(a.peticiones.single.queryParameters, isEmpty);
    });

    test('POST 201 → categoría creada', () async {
      final a = _adaptador(201, {'categoria': jsonCategoria(nombre: 'X')});
      final c = await CategoriasRepositoryImpl(_cliente(a))
          .crear(const DatosCategoria(nombre: 'X', orden: 3));
      expect(a.peticiones.single.method, 'POST');
      expect(a.peticiones.single.data, {
        'nombre': 'X',
        'descripcion': null,
        'orden': 3,
      });
      expect(c.nombre, 'X');
    });

    test('PATCH 200 con el subconjunto de campos', () async {
      final a = _adaptador(200, {'categoria': jsonCategoria(activa: false)});
      final c = await CategoriasRepositoryImpl(_cliente(a))
          .actualizar('c1', {'activa': false});
      expect(a.peticiones.single.method, 'PATCH');
      expect(a.peticiones.single.path, '/admin/categorias/c1');
      expect(a.peticiones.single.data, {'activa': false});
      expect(c.activa, isFalse);
    });

    test('400 VALIDACION con detalles por campo', () async {
      final a = _adaptador(
        400,
        _error('VALIDACION', 'Datos no válidos.', [
          {'campo': 'nombre', 'ubicacion': 'body', 'mensaje': 'Muy corto'},
        ]),
      );
      await expectLater(
        CategoriasRepositoryImpl(_cliente(a))
            .crear(const DatosCategoria(nombre: 'a')),
        throwsA(
          isA<ApiException>()
              .having((e) => e.tipo, 'tipo', TipoErrorApi.validacion)
              .having((e) => e.erroresPorCampo, 'campos', {
                'nombre': 'Muy corto',
              }),
        ),
      );
    });

    test('404 y 409 con el mensaje del servidor', () async {
      await expectLater(
        CategoriasRepositoryImpl(
          _cliente(
            _adaptador(404, _error('NO_ENCONTRADO', 'La categoría no existe.')),
          ),
        ).actualizar('x', {'activa': true}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.estadoHttp, 'estado', 404)
              .having((e) => e.mensaje, 'mensaje', 'La categoría no existe.'),
        ),
      );
      await expectLater(
        CategoriasRepositoryImpl(
          _cliente(
            _adaptador(
              409,
              _error('CONFLICTO', 'Ya existe una categoría con ese nombre.'),
            ),
          ),
        ).crear(const DatosCategoria(nombre: 'Murales')),
        throwsA(
          isA<ApiException>().having((e) => e.codigo, 'codigo', 'CONFLICTO'),
        ),
      );
    });

    test('respuesta con otra forma → RESPUESTA_INVALIDA', () async {
      await expectLater(
        CategoriasRepositoryImpl(_cliente(_adaptador(200, {'otra': 1})))
            .listar(),
        throwsA(same(respuestaInvalidaCatalogo)),
      );
      await expectLater(
        CategoriasRepositoryImpl(
          _cliente(
            _adaptador(201, {
              'categoria': {...jsonCategoria(), 'orden': '1'},
            }),
          ),
        ).crear(const DatosCategoria(nombre: 'X')),
        throwsA(same(respuestaInvalidaCatalogo)),
      );
    });
  });

  group('MaterialesRepositoryImpl', () {
    test('GET paginado con el precio como texto', () async {
      final a = _adaptador(200, {
        'datos': [
          jsonMaterial(precio: '0.75'),
          jsonMaterial(id: 'm2', precio: '12.50'),
        ],
        'paginacion': {
          'pagina': 2,
          'porPagina': 20,
          'total': 22,
          'totalPaginas': 2,
        },
      });
      final p = await MaterialesRepositoryImpl(_cliente(a))
          .listar(pagina: 2, q: 'lie', activo: false);

      expect(a.peticiones.single.path, '/admin/materiales');
      expect(a.peticiones.single.queryParameters, {
        'pagina': '2',
        'porPagina': '20',
        'q': 'lie',
        'activo': 'false',
      });
      expect(p.datos.first.precioUnitario.centavos, 75);
      expect(p.datos.last.precioUnitario.formateado, r'$ 12,50');
      expect(p.datos.first.descripcion, 'Algodón');
      expect((p.pagina, p.total, p.totalPaginas, p.porPagina), (2, 22, 2, 20));
    });

    test('POST 201 envía el precio como texto', () async {
      final a = _adaptador(201, {'material': jsonMaterial()});
      final m = await MaterialesRepositoryImpl(_cliente(a)).crear(
        DatosMaterial(
          nombre: 'Lienzo',
          unidad: 'metro',
          precioUnitario: Precio.intentar('4.5')!,
        ),
      );
      final cuerpo = a.peticiones.single.data as Map<String, Object?>;
      expect(cuerpo['precioUnitario'], '4.50');
      expect(cuerpo['precioUnitario'], isA<String>());
      expect(m.precioUnitario.textoApi, '4.50');
    });

    test('PATCH 200 y 409', () async {
      final a = _adaptador(200, {'material': jsonMaterial(precio: '5.25')});
      final m = await MaterialesRepositoryImpl(_cliente(a))
          .actualizar('m1', {'precioUnitario': '5.25'});
      expect(a.peticiones.single.path, '/admin/materiales/m1');
      expect(m.precioUnitario.formateado, r'$ 5,25');

      await expectLater(
        MaterialesRepositoryImpl(
          _cliente(
            _adaptador(
              409,
              _error('CONFLICTO', 'Ya existe un material con ese nombre.'),
            ),
          ),
        ).actualizar('m1', {'nombre': 'X'}),
        throwsA(isA<ApiException>().having((e) => e.estadoHttp, 'estado', 409)),
      );
    });

    test('un precio numérico en la respuesta no es válido', () async {
      await expectLater(
        MaterialesRepositoryImpl(
          _cliente(_adaptador(200, {'material': jsonMaterial(precio: 4.5)})),
        ).actualizar('m1', {'activo': true}),
        throwsA(same(respuestaInvalidaCatalogo)),
      );
      await expectLater(
        MaterialesRepositoryImpl(
          _cliente(
            _adaptador(200, {
              'datos': [jsonMaterial()],
            }),
          ),
        ).listar(),
        throwsA(same(respuestaInvalidaCatalogo)),
      );
    });
  });
}
