import 'dart:typed_data';

import 'package:creafacil_admin/core/network/red.dart';
import 'package:creafacil_admin/features/catalogo/data/catalogo_repositories_impl.dart';
import 'package:creafacil_admin/features/catalogo/domain/precio.dart';
import 'package:creafacil_admin/features/catalogo/domain/servicios.dart';
import 'package:creafacil_admin/features/catalogo/presentation/catalogo_providers.dart';
import 'package:creafacil_admin/features/catalogo/presentation/servicios_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/api_falsa.dart';
import '../../helpers/catalogo_falso.dart';

AdaptadorHttpFalso _adaptador(int estado, Object cuerpo) =>
    AdaptadorHttpFalso((_) async => respuestaJson(estado, cuerpo));

ServiciosRepositoryImpl _repo(AdaptadorHttpFalso adaptador) =>
    ServiciosRepositoryImpl(
      ApiClient(
        baseUrl: 'http://api.test/api/v1',
        proveedorToken: const ProveedorTokenSinSesion(),
        dio: Dio()..httpClientAdapter = adaptador,
      ),
    );

Map<String, Object?> _error(
  String codigo,
  String mensaje, [
  List<Map<String, String>> detalles = const [],
]) => {
  'error': {'codigo': codigo, 'mensaje': mensaje, 'detalles': detalles},
};

final _png = ArchivoFoto(
  nombre: 'mural.PNG',
  bytes: Uint8List.fromList([137, 80, 78, 71]),
);

Future<ApiException> _fallo(Future<Object?> peticion) async {
  try {
    await peticion;
  } on ApiException catch (e) {
    return e;
  }
  fail('Se esperaba una ApiException');
}

void main() {
  group('ServiciosRepositoryImpl', () {
    test('GET lista con filtros, precio exacto y categoría', () async {
      final a = _adaptador(200, {
        'datos': [
          jsonServicio(),
          jsonServicio(id: 's2', precio: null, categoriaActiva: false),
        ],
        'paginacion': {
          'pagina': 2,
          'porPagina': 20,
          'total': 22,
          'totalPaginas': 2,
        },
      });
      final p = await _repo(a)
          .listar(pagina: 2, q: ' mur ', categoriaId: 'c1', activo: false);

      expect(a.peticiones.single.path, '/admin/servicios');
      expect(a.peticiones.single.queryParameters, {
        'pagina': '2',
        'porPagina': '20',
        'q': 'mur',
        'categoriaId': 'c1',
        'activo': 'false',
      });
      expect(p.total, 22);
      expect(p.datos.first.precioBaseReferencial, const Precio.centavos(12050));
      expect(p.datos.first.portadaUrl, 'http://api.test/uploads/f1.png');
      expect(p.datos.first.numeroFotos, 2);
      expect(p.datos.last.precioBaseReferencial, isNull);
      expect(p.datos.last.categoria.activa, isFalse);
    });

    test('GET sin filtros solo envía la paginación', () async {
      final a = _adaptador(200, {
        'datos': <Object>[],
        'paginacion': {
          'pagina': 1,
          'porPagina': 20,
          'total': 0,
          'totalPaginas': 0,
        },
      });
      await _repo(a).listar(categoriaId: '');
      expect(a.peticiones.single.queryParameters, {
        'pagina': '1',
        'porPagina': '20',
      });
    });

    test('GET /:id → ficha con materiales y fotos ordenadas', () async {
      final a = _adaptador(200, {'servicio': jsonServicio(detalle: true)});
      final s = await _repo(a).obtener('s 1');
      expect(a.peticiones.single.path, '/admin/servicios/s%201');
      expect(s.descripcion, 'Mural pintado a mano');
      expect(s.dimensionesOrientativas, isNull);
      expect(s.materiales.single.activo, isFalse);
      expect([for (final f in s.fotos) f.id], ['f1', 'f2']);
      expect(s.fotos.first.esPortada, isTrue);
    });

    test('POST crea con el precio como texto', () async {
      final a = _adaptador(201, {'servicio': jsonServicio(detalle: true)});
      await _repo(a).crear(
        const DatosServicio(
          categoriaId: 'c1',
          nombre: 'Mural',
          precioBaseReferencial: Precio.centavos(12050),
          materialIds: ['m1', 'm2'],
        ),
      );
      expect(a.peticiones.single.method, 'POST');
      expect(a.peticiones.single.data, {
        'categoriaId': 'c1',
        'nombre': 'Mural',
        'precioBaseReferencial': '120.50',
        'materialIds': ['m1', 'm2'],
      });
    });

    test('PATCH envía el subconjunto', () async {
      final a = _adaptador(200, {'servicio': jsonServicio(detalle: true)});
      await _repo(a).actualizar('s1', {'activo': false});
      expect(a.peticiones.single.method, 'PATCH');
      expect(a.peticiones.single.path, '/admin/servicios/s1');
      expect(a.peticiones.single.data, {'activo': false});
    });

    test('409 nombre repetido y respuesta inesperada', () async {
      final e = await _fallo(
        _repo(
          _adaptador(
            409,
            _error(
              'CONFLICTO',
              'Ya existe un servicio con ese nombre en esta categoría.',
            ),
          ),
        ).crear(const DatosServicio(categoriaId: 'c1', nombre: 'Mural')),
      );
      expect(e.estadoHttp, 409);
      expect(e.mensaje, contains('en esta categoría'));

      final rara = await _fallo(
        _repo(_adaptador(200, {'servicio': 'x'})).obtener('s1'),
      );
      expect(rara.codigo, 'RESPUESTA_INVALIDA');
      final sinFotos = await _fallo(
        _repo(_adaptador(200, {'nada': 1})).borrarFoto('s1', 'f1'),
      );
      expect(sinFotos.codigo, 'RESPUESTA_INVALIDA');
      final sinMateriales = await _fallo(
        _repo(
          _adaptador(200, {
            'servicio': {...jsonServicio(detalle: true), 'materiales': null},
          }),
        ).obtener('s1'),
      );
      expect(sinMateriales.codigo, 'RESPUESTA_INVALIDA');
    });

    test('POST /:id/fotos con FormData, campo «foto» y progreso', () async {
      final a = _adaptador(201, {
        'foto': {
          'id': 'f3',
          'url': 'http://api.test/uploads/f3.png',
          'orden': 2,
        },
      });
      final foto = await _repo(a).subirFoto('s1', _png, progreso: (_) {});

      final peticion = a.peticiones.single;
      expect(peticion.method, 'POST');
      expect(peticion.path, '/admin/servicios/s1/fotos');
      final datos = peticion.data as FormData;
      final archivo = datos.files.single;
      expect(archivo.key, 'foto');
      expect(archivo.value.filename, 'mural.PNG');
      expect(archivo.value.contentType?.mimeType, 'image/png');
      expect(archivo.value.length, 4);
      expect(peticion.onSendProgress, isNotNull);
      expect(foto.orden, 2);
    });

    for (final (estado, codigo, mensaje, detalles) in [
      (
        400,
        'VALIDACION',
        'Datos no válidos.',
        [
          {
            'campo': 'foto',
            'ubicacion': 'body',
            'mensaje': 'El archivo no es una imagen JPG, PNG o WebP válida.',
          },
        ],
      ),
      (
        413,
        'ARCHIVO_DEMASIADO_GRANDE',
        'La foto supera el máximo de 5 MB.',
        <Map<String, String>>[],
      ),
      (
        409,
        'CONFLICTO',
        'El servicio ya tiene 8 fotos, el máximo.',
        <Map<String, String>>[],
      ),
    ]) {
      test('subir foto: $estado $codigo', () async {
        final e = await _fallo(
          _repo(_adaptador(estado, _error(codigo, mensaje, detalles)))
              .subirFoto('s1', _png),
        );
        expect(e.estadoHttp, estado);
        expect(e.mensaje, mensaje);
        expect(e.detalles.length, detalles.length);
      });
    }

    test('PATCH /fotos/orden y DELETE /fotos/:fotoId', () async {
      final fotos = {
        'fotos': [
          {'id': 'f2', 'url': 'u2', 'orden': 0},
          {'id': 'f1', 'url': 'u1', 'orden': 1},
        ],
      };
      final a = _adaptador(200, fotos);
      final r = await _repo(a).ordenarFotos('s1', ['f2', 'f1']);
      expect(a.peticiones.single.method, 'PATCH');
      expect(a.peticiones.single.path, '/admin/servicios/s1/fotos/orden');
      expect(a.peticiones.single.data, {
        'fotoIds': ['f2', 'f1'],
      });
      expect(r.first.id, 'f2');

      final b = _adaptador(200, fotos);
      await _repo(b).borrarFoto('s1', 'f9');
      expect(b.peticiones.single.method, 'DELETE');
      expect(b.peticiones.single.path, '/admin/servicios/s1/fotos/f9');
    });
  });

  group('Dominio de servicios', () {
    test('aJson omite lo vacío y cambiosRespectoA solo lo que cambia', () {
      expect(const DatosServicio(categoriaId: 'c1', nombre: 'Mural').aJson(), {
        'categoriaId': 'c1',
        'nombre': 'Mural',
      });
      final actual = servicioPrueba(
        descripcion: 'Antes',
        materiales: const [
          MaterialDeServicio(id: 'm1', nombre: 'L', unidad: 'u', activo: true),
        ],
      );
      final iguales = DatosServicio(
        categoriaId: 'c1',
        nombre: actual.nombre,
        descripcion: 'Antes',
        precioBaseReferencial: actual.precioBaseReferencial,
        materialIds: const ['m1'],
      );
      expect(iguales.cambiosRespectoA(actual), isEmpty);
      const distintos = DatosServicio(
        categoriaId: 'c2',
        nombre: 'Otro',
        dimensionesOrientativas: '2 x 3 m',
        observaciones: 'Nota',
        materialIds: ['m2'],
      );
      expect(distintos.cambiosRespectoA(actual), {
        'categoriaId': 'c2',
        'nombre': 'Otro',
        'descripcion': null,
        'dimensionesOrientativas': '2 x 3 m',
        'observaciones': 'Nota',
        'precioBaseReferencial': null,
        'materialIds': ['m2'],
      });
    });

    test('validaciones del formulario y del archivo', () {
      expect(ValidacionesServicio.nombre(' '), 'Escribe el nombre.');
      expect(ValidacionesServicio.nombre('a'), contains('al menos 2'));
      expect(ValidacionesServicio.nombre('a' * 121), contains('120'));
      expect(ValidacionesServicio.nombre('Mural'), isNull);
      expect(ValidacionesServicio.categoria(null), 'Elige la categoría.');
      expect(ValidacionesServicio.categoria('c1'), isNull);
      expect(ValidacionesServicio.precioOpcional(''), isNull);
      expect(ValidacionesServicio.precioOpcional('120.5'), isNull);
      expect(ValidacionesServicio.precioOpcional('0'), contains('mayor'));
      final dimensiones = ValidacionesServicio.textoMaximo(
        'Las dimensiones',
        3,
      );
      expect(dimensiones('abcd'), contains('como máximo 3'));
      expect(dimensiones(null), isNull);

      expect(ValidacionesServicio.archivo('a.pdf', 10), contains('JPG'));
      expect(ValidacionesServicio.archivo('sinextension', 10), isNotNull);
      expect(
        ValidacionesServicio.archivo('a.jpg', 0),
        'El archivo está vacío.',
      );
      expect(
        ValidacionesServicio.archivo('a.webp', 6 * 1024 * 1024),
        'La foto pesa 6.0 MB y el máximo es 5 MB.',
      );
      expect(ValidacionesServicio.archivo('a.JPEG', 5 * 1024 * 1024), isNull);
      expect(ValidacionesServicio.tipoMime('a.jpg'), 'image/jpeg');
      expect(ValidacionesServicio.tipoMime('a.webp'), 'image/webp');
    });
  });

  group('Controladores de servicios', () {
    ProviderContainer contenedor(RepositorioServiciosFalso repo) {
      final c = ProviderContainer(overrides: catalogoSimulado(servicios: repo));
      addTearDown(c.dispose);
      return c;
    }

    test('lista, filtros, página y recarga tras guardar', () async {
      final repo = RepositorioServiciosFalso([
        servicioPrueba(),
        servicioPrueba(id: 's2', nombre: 'Cuadro', activo: false),
      ]);
      final c = contenedor(repo);
      c.listen(serviciosControllerProvider, (_, _) {});
      expect((await c.read(serviciosControllerProvider.future)).total, 2);

      c.read(filtroServiciosProvider.notifier)
        ..buscar(' cua ')
        ..buscar('cua')
        ..filtrarPorCategoria('c1')
        ..filtrarPorEstado(FiltroEstado.inactivos)
        ..irAPagina(1);
      final p = await c.read(serviciosControllerProvider.future);
      expect(p.datos.single.nombre, 'Cuadro');
      expect(repo.llamadas.last, 'listar:1:cua:c1:false');

      final notifier = c.read(serviciosControllerProvider.notifier);
      await notifier.cambiarEstado(p.datos.single, activo: true);
      expect(repo.ultimosCambios, {'activo': true});
      expect(await c.read(serviciosControllerProvider.future), isA<Object>());
      expect(repo.llamadas.last, 'listar:1:cua:c1:false');
      expect((await notifier.obtener('s1')).id, 's1');
    });

    test('fotos: subir, mover, portada y borrar', () async {
      final repo = RepositorioServiciosFalso([
        servicioPrueba(fotos: [fotoPrueba('f1', 0), fotoPrueba('f2', 1)]),
      ]);
      final c = contenedor(repo);
      final provider = fotosServicioProvider('s1');
      c.listen(provider, (_, _) {});
      expect(await c.read(provider.future), hasLength(2));

      final progresos = <double>[];
      await c.read(provider.notifier).subir(_png, progreso: progresos.add);
      expect(progresos, [0.5, 1]);
      expect(repo.llamadas, contains('subir:s1:mural.PNG:image/png'));
      final fotos = c.read(provider).requireValue;
      expect(fotos, hasLength(3));

      await c.read(provider.notifier).mover(fotos.last, 0);
      expect(repo.llamadas.last, 'ordenar:s1:f100,f1,f2');
      final ordenadas = c.read(provider).requireValue;
      await c.read(provider.notifier).mover(ordenadas.first, 9);
      expect(repo.llamadas.last, 'ordenar:s1:f1,f2,f100');

      await c.read(provider.notifier).borrar(c.read(provider).requireValue[0]);
      expect(
        [for (final f in c.read(provider).requireValue) f.id],
        ['f2', 'f100'],
      );
      expect(c.read(provider).requireValue.first.esPortada, isTrue);

      await c.read(provider.notifier).recargar();
      expect(await c.read(provider.future), hasLength(2));
    });

    test('opciones: categorías y materiales activos', () async {
      final c = ProviderContainer(
        overrides: catalogoSimulado(
          categorias: RepositorioCategoriasFalso([categoriaPrueba()]),
          materiales: RepositorioMaterialesFalso([
            materialPrueba(),
            materialPrueba(id: 'm2', activo: false),
          ]),
        ),
      );
      addTearDown(c.dispose);
      c
        ..listen(opcionesCategoriasProvider, (_, _) {})
        ..listen(materialesActivosProvider, (_, _) {});
      expect(await c.read(opcionesCategoriasProvider.future), hasLength(1));
      expect((await c.read(materialesActivosProvider.future)).single.id, 'm1');
    });
  });
}
