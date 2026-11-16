import 'package:shared_preferences/shared_preferences.dart';

import 'almacen_sesion.dart';

/// Sesión guardada con `shared_preferences` (solo panel web) [RNF-01].
///
/// En el navegador acaba en el almacenamiento local (`localStorage`), así que
/// la sesión sobrevive a una recarga de la página. **Riesgo**: un script
/// inyectado (XSS) podría leer el token. Se acepta porque:
/// - el servidor verifica SIEMPRE el JWT y el rol `ADMIN` (RNF-03, RN-05);
/// - el token caduca a las 8 horas y no se renueva;
/// - Flutter web no inserta HTML del usuario y no hay contenido de terceros.
class AlmacenSesionPreferencias extends AlmacenSesionTexto {
  AlmacenSesionPreferencias([Future<SharedPreferences>? preferencias])
    : _preferencias = preferencias;

  final Future<SharedPreferences>? _preferencias;

  Future<SharedPreferences> get _instancia =>
      _preferencias ?? SharedPreferences.getInstance();

  @override
  Future<String?> leerTexto(String clave) async =>
      (await _instancia).getString(clave);

  @override
  Future<void> escribirTexto(String clave, String valor) async {
    await (await _instancia).setString(clave, valor);
  }

  @override
  Future<void> borrarTexto(String clave) async {
    await (await _instancia).remove(clave);
  }
}
