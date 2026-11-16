import '../data/almacen_sesion.dart';
import '../data/almacen_sesion_preferencias.dart';
import '../domain/politica_acceso.dart';
import '../domain/usuario.dart';

// ÚNICO archivo de `domain`, `data` (salvo el almacén concreto) y del
// controlador de `features/autenticacion` que es distinto en
// CreaFacil_Frontend y CreaFacil_AdminWeb. El resto es idéntico.

/// El panel es solo para la administradora (decisión aprobada de la Fase 1).
const politicaAccesoDeLaApp = PoliticaAcceso(
  rolPermitido: RolUsuario.admin,
  mensajeRechazo: 'Acceso solo para la administradora.',
);

/// En el panel web la sesión se guarda con `shared_preferences`.
AlmacenSesion crearAlmacenSesionDeLaApp() => AlmacenSesionPreferencias();
