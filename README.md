# CreaFacil_AdminWeb

[![CI](https://github.com/RosaMV2309/CreaFacil_AdminWeb/actions/workflows/ci.yml/badge.svg?branch=develop)](https://github.com/RosaMV2309/CreaFacil_AdminWeb/actions/workflows/ci.yml)

Panel administrativo de **CreaFácil** para la administradora: catálogo, precios, cotizaciones,
solicitudes, pedidos, agenda y reportes.

- Tecnología: Flutter Web 3.47 / Dart 3.13
- Estado: Riverpod · Navegación: go_router · HTTP: Dio · Sesión: shared_preferences
- Especificación: DERCAS v1.0 (Rosa Virginia Moreira Vidal, Sexto B)

> Se usa `shared_preferences` para la sesión porque en el navegador los datos terminan
> en el almacenamiento local de todos modos; la protección real la aplica la API (JWT y rol `ADMIN`).

## Requisitos

- Flutter 3.47 (canal stable)
- Google Chrome
- La API de `CreaFacil_Backend` en ejecución

## Ejecutar

```sh
flutter pub get
flutter run -d chrome --web-port 5001 --dart-define=API_URL=http://localhost:3000/api/v1
```

| Variable (`--dart-define`) | Por defecto | Descripción |
|---|---|---|
| `API_URL` | `http://localhost:3000/api/v1` | Dirección de la API |

La API solo admite CORS desde `http://localhost:5000` y `http://localhost:5001`: abre el panel
siempre como `http://localhost:5001` (no `127.0.0.1`). Sin Chrome, también sirve:
`flutter run -d web-server --web-port 5001 --dart-define=API_URL=http://localhost:3000/api/v1`.

## Comandos

| Comando | Qué hace |
|---|---|
| `flutter analyze` | Análisis estático |
| `dart format lib test tool` | Formatea el código |
| `flutter test` | Pruebas |
| `flutter test --coverage` | Pruebas con informe de cobertura en `coverage/lcov.info` |
| `dart run tool/cobertura.dart` | Comprueba el umbral de cobertura (80 %) |
| `flutter build web --release` | Compila el panel en `build/web` |

## Pruebas y cobertura

```sh
flutter test --coverage
dart run tool/cobertura.dart            # falla (código 1) si la cobertura de lib/ es menor del 80 %
dart run tool/cobertura.dart --detalle  # además, la cobertura de cada archivo
```

- `tool/cobertura.dart` (idéntico al de la app móvil) lee `coverage/lcov.info` sin dependencias externas,
  así que funciona igual en Windows y en la CI.
- Cuenta las líneas de `lib/` y solo excluye código generado (`*.g.dart`, `*.freezed.dart`, `generated/`…).
- Opciones: `--minimo=<porcentaje>` y `--lcov=<ruta>`.
- `coverage/` no se sube al repositorio.

## Integración continua (GitHub Actions)

`.github/workflows/ci.yml` se ejecuta en cada push a `develop` y `main` y en cada Pull Request, con
Flutter 3.47.9 (stable):

1. `flutter pub get`
2. `dart format --set-exit-if-changed lib test tool`
3. `flutter analyze`
4. `flutter test --coverage` y el umbral del 80 % (`dart run tool/cobertura.dart`)
5. Paleta oficial: `git grep` de colores fuera de `lib/core/theme/app_colors.dart` (falla si encuentra alguno)
6. `flutter build web --release`

Artefactos de cada ejecución (pestaña **Actions** → la ejecución → **Artifacts**): `cobertura-lcov` y
`creafacil-admin-web` (el contenido de `build/web`). Se guardan 14 días.

## Compilación web

```sh
flutter build web --release --dart-define=API_URL=https://<api>/api/v1
```

El resultado queda en `build/web` y se puede publicar en cualquier alojamiento estático. Para probarlo
en local: `python -m http.server 5001 --directory build/web` y abrir `http://localhost:5001`.

## Estructura

```
lib/
├── main.dart
├── app.dart                    # MaterialApp.router, tema e idioma español
├── core/
│   ├── config/app_config.dart  # configuración por --dart-define
│   ├── router/app_router.dart  # rutas (go_router)
│   ├── theme/                  # paleta oficial (app_colors.dart) y tema
│   ├── network/                # cliente HTTP (subfase 0.8)
│   ├── design_system/          # componentes Cf* al estilo PrimeNG (subfase 0.7)
│   └── widgets/                # diseño adaptable y menú lateral
└── features/<funcionalidad>/
    ├── data/
    ├── domain/
    └── presentation/
tool/
└── cobertura.dart              # umbral de cobertura (CI y local)
```

## Acceso de la administradora (Fase 1 · RF-01, RF-02, RNF-03)

El panel **exige iniciar sesión con el rol `ADMIN`**. Código en `lib/features/autenticacion/`.

**Flujo**

1. Sin sesión, cualquier ruta del panel lleva a `/acceso` (fuera del AdminShell), conservando la
   sección pedida (`/acceso?desde=/agenda`). Solo hay inicio de sesión: **no hay registro** en el panel
   ni «¿Olvidaste tu contraseña?».
2. Con las credenciales de la administradora (`ADMIN_EMAIL` y `ADMIN_PASSWORD` del `.env` del
   backend, creadas por el seed) entra al panel; su nombre aparece en la cabecera (en móvil, en el
   menú desplegable) junto a «Cerrar sesión», que pide confirmación.
3. Si inicia sesión un **CLIENTE**, la sesión **no se guarda** y se muestra
   «Acceso solo para la administradora.».
4. Errores con `CfMessage`: 401 «Correo o contraseña incorrectos.», 403 cuenta desactivada y
   429 demasiados intentos (con el tiempo de espera).

API consumida: `POST /auth/login` y `GET /auth/perfil`.

**Guardia por rol** (`lib/core/router/guardia_sesion.dart`, `proteccionPorRolActiva = true`): el router
se refresca con cada cambio de la sesión (`refreshListenable`). Es solo navegación: el servidor
verifica **siempre** el JWT y el rol (RNF-03, RN-05).

**Sesión**

- JWT de 8 horas **sin renovación**. Al recargar la página se restaura: si `expiraEn` ya pasó se borra;
  si no, se valida con `GET /auth/perfil` (si responde 401, se borra).
- Si caduca o la API responde 401 a una petición autenticada, se vuelve a `/acceso` con el aviso
  «Tu sesión expiró, vuelve a iniciar sesión.».
- Se guarda con `shared_preferences`, que en el navegador usa el **almacenamiento local**.
  **Riesgo de XSS**: un script inyectado podría leer el token. Se acepta en esta etapa porque el
  servidor verifica siempre el JWT y el rol `ADMIN`, el token caduca a las 8 horas, Flutter web no
  inserta HTML de usuarios y el panel no carga contenido de terceros. Una mejora futura sería una
  cookie `HttpOnly` emitida por el backend.

**Código compartido con CreaFacil_Frontend**: `lib/core/` (red, componentes `Cf*`, tema y widgets) y,
en `features/autenticacion/`, el dominio, los modelos, el repositorio, `AlmacenSesion`, el controlador,
los providers y el formulario de acceso son **idénticos**. Solo cambian
`presentation/configuracion_acceso.dart` (rol `ADMIN`, mensaje de rechazo y almacén), el almacén
concreto (`AlmacenSesionPreferencias`) y la pantalla `acceso_page.dart`. Si se cambia un archivo
común, hay que replicarlo en el otro repositorio en su propia rama y PR.

## Identidad visual

Solo se usan los colores de la paleta oficial, definidos en `lib/core/theme/app_colors.dart`
(idéntico al de la app móvil). La navegación usa el azul artesanal `#244A68`.

## Ramas

- `main`: versiones estables.
- `develop`: integración. Todo cambio entra por Pull Request desde `feature/*`, `fix/*` o `refactor/*`.
