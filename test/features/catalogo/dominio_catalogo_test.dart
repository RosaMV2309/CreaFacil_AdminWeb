import 'package:creafacil_admin/features/catalogo/domain/entidades_catalogo.dart';
import 'package:creafacil_admin/features/catalogo/domain/precio.dart';
import 'package:creafacil_admin/features/catalogo/domain/validaciones_catalogo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/catalogo_falso.dart';

void main() {
  group('Precio (exacto, sin double)', () {
    test('lee el texto de la API en céntimos', () {
      expect(Precio.intentar('0.75')!.centavos, 75);
      expect(Precio.intentar('4.5')!.centavos, 450);
      expect(Precio.intentar('12')!.centavos, 1200);
      expect(Precio.intentar('007.05')!.centavos, 705);
      expect(Precio.intentar('99999.99')!.centavos, 9999999);
      // Un double daría 0.30000000000000004: aquí 0.1 + 0.2 es exacto.
      expect(
        Precio.intentar('0.1')!.centavos + Precio.intentar('0.2')!.centavos,
        Precio.intentar('0.3')!.centavos,
      );
    });

    test('rechaza formatos que el servidor no admite', () {
      for (final t in ['', '1.234', '0,75', '-1', '1e3', '.5', '4.', 'abc']) {
        expect(Precio.intentar(t), isNull, reason: t);
      }
      expect(Precio.intentar('1234567890'), isNull);
    });

    test('texto para la API y para mostrar', () {
      expect(Precio.intentar('4.5')!.textoApi, '4.50');
      expect(Precio.intentar('0.75')!.formateado, r'$ 0,75');
      expect(Precio.intentar('4.5')!.formateado, r'$ 4,50');
      expect(Precio.intentar('1234.5')!.formateado, r'$ 1.234,50');
      expect(Precio.intentar('99999.99')!.formateado, r'$ 99.999,99');
      expect(Precio.intentar('5.25').toString(), '5.25');
    });

    test('desdeApi exige texto con el formato del contrato', () {
      expect(Precio.desdeApi('12.50'), Precio.intentar('12.5'));
      expect(() => Precio.desdeApi(0.75), throwsFormatException);
      expect(() => Precio.desdeApi(null), throwsFormatException);
      expect(() => Precio.desdeApi('0,75'), throwsFormatException);
    });

    test('igualdad, orden y hash', () {
      final a = Precio.intentar('1.00')!;
      expect(a, Precio.intentar('1'));
      expect(a.hashCode, const Precio.centavos(100).hashCode);
      expect(a.compareTo(Precio.intentar('2')!), lessThan(0));
    });

    test('validar con los mismos límites que el servidor', () {
      expect(Precio.validar(null), 'Escribe el precio unitario.');
      expect(Precio.validar('4,50'), contains('punto'));
      expect(Precio.validar('abc'), contains('número válido'));
      expect(Precio.validar('-1'), contains('número válido'));
      expect(Precio.validar('1.234'), contains('2 decimales'));
      expect(Precio.validar('100000'), contains('99999.99'));
      expect(Precio.validar('12345678901234'), contains('99999.99'));
      expect(Precio.validar('0'), contains('mayor que 0'));
      expect(Precio.validar('0.00'), contains('mayor que 0'));
      expect(Precio.validar(' 4.5 '), isNull);
      expect(Precio.validar('99999.99'), isNull);
    });
  });

  group('ValidacionesCatalogo', () {
    test('nombre 2–80 con espacios normalizados', () {
      expect(ValidacionesCatalogo.normalizar('  Hola   mundo '), 'Hola mundo');
      expect(ValidacionesCatalogo.nombre('  '), 'Escribe el nombre.');
      expect(ValidacionesCatalogo.nombre('a'), contains('al menos 2'));
      expect(ValidacionesCatalogo.nombre('a' * 81), contains('80'));
      expect(ValidacionesCatalogo.nombre('Cuadros'), isNull);
    });

    test('descripción, orden y unidad', () {
      expect(ValidacionesCatalogo.descripcion('a' * 501), contains('500'));
      expect(ValidacionesCatalogo.descripcion(null), isNull);
      expect(ValidacionesCatalogo.opcional('  '), isNull);
      expect(ValidacionesCatalogo.opcional(' x '), 'x');
      expect(ValidacionesCatalogo.orden(''), isNull);
      expect(ValidacionesCatalogo.orden('1.5'), contains('entero'));
      expect(ValidacionesCatalogo.orden('10000'), contains('9999'));
      expect(ValidacionesCatalogo.orden('9999'), isNull);
      expect(ValidacionesCatalogo.ordenDe(''), 0);
      expect(ValidacionesCatalogo.ordenDe('7'), 7);
      expect(ValidacionesCatalogo.unidad(''), contains('unidad'));
      expect(ValidacionesCatalogo.unidad('a' * 31), contains('30'));
      expect(ValidacionesCatalogo.unidad('metro'), isNull);
    });
  });

  group('Datos de los formularios', () {
    test('categoría: alta completa y PATCH solo con los cambios', () {
      const datos = DatosCategoria(nombre: 'Cuadros', orden: 2);
      expect(datos.aJson(), {
        'nombre': 'Cuadros',
        'descripcion': null,
        'orden': 2,
      });
      final actual = categoriaPrueba(nombre: 'Cuadros', descripcion: 'x');
      expect(datos.cambiosRespectoA(actual), {'descripcion': null, 'orden': 2});
    });

    test('material: el precio viaja como texto', () {
      final datos = DatosMaterial(
        nombre: 'Lienzo',
        unidad: 'metro',
        precioUnitario: Precio.intentar('4.5')!,
      );
      expect(datos.aJson()['precioUnitario'], '4.50');
      final actual = materialPrueba(nombre: 'Lienzo', unidad: 'metro');
      expect(datos.cambiosRespectoA(actual), {'precioUnitario': '4.50'});
      expect(
        DatosMaterial(
          nombre: 'Otro',
          unidad: 'm',
          precioUnitario: actual.precioUnitario,
          descripcion: 'd',
        ).cambiosRespectoA(actual),
        {'nombre': 'Otro', 'unidad': 'm', 'descripcion': 'd'},
      );
    });
  });
}
