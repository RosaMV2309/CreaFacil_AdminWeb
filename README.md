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

## Gestión del catálogo (categorías y materiales)

Fase 2 · subfase 2.4a (RF-22, RF-05, RF-08). La sección **Catálogo** (`/catalogo`) tiene tres
pestañas: **Categorías**, **Materiales** y **Servicios** (con sus fotos; ver la sección siguiente).

API consumida (todas exigen el token de la administradora):

| Acción | Petición |
|---|---|
| Listar categorías (sin paginar) | `GET /admin/categorias?q=&activa=` |
| Crear / editar categoría | `POST /admin/categorias` · `PATCH /admin/categorias/:id` |
| Listar materiales (paginado, 20 por página) | `GET /admin/materiales?pagina=&porPagina=&q=&activo=` |
| Crear / editar material | `POST /admin/materiales` · `PATCH /admin/materiales/:id` |

- **No se borra nada**: solo se activa o desactiva con `PATCH` (`activa`/`activo`).
- Al **desactivar una categoría con servicios activos** se pide confirmación: «Sus N servicios dejarán
  de verse en el catálogo, pero no se desactivan.».
- La edición envía **solo los campos cambiados**; si no hay cambios, no se envía nada.
- Errores: los 400 (`VALIDACION`) se muestran en su campo; los 409 (nombre repetido) y 404 (no existe),
  en un `CfMessage`. Mientras se guarda, el botón muestra la carga y no admite envíos dobles.
- Tras crear, editar o cambiar el estado se muestra un aviso de éxito y la lista se vuelve a pedir.

**Precio exacto (sin `double`).** La API envía y recibe el precio como texto con dos decimales
(`"0.75"`). La clase `Precio` (`features/catalogo/domain/precio.dart`) lo guarda como un **entero de
céntimos** y lo convierte con operaciones de enteros:

- Entrada: se valida con la misma regla que el servidor, `^\d+(\.\d{1,2})?$`, mayor que 0 y como
  máximo `99999.99` (punto decimal; `4,50` o `1.234` se rechazan con un mensaje claro).
- Envío: `precio.textoApi` → `"4.50"` (siempre texto).
- Pantalla: `precio.formateado` → `$ 4,50` o `$ 1.234,50` (coma decimal, punto de miles; sin redondeos).

Al editar el precio se recuerda que el cambio **no afecta a las cotizaciones ya guardadas** (RN-02).

Arquitectura: `features/catalogo/{domain,data,presentation}` con Riverpod (`filtroCategoriasProvider`,
`categoriasControllerProvider`, `filtroMaterialesProvider`, `materialesControllerProvider`). Componentes
nuevos en `lib/core/design_system/`: `CfDataTable` (estados de carga, vacío y error, paginación y vista
de tarjetas en pantallas estrechas), `CfDialog`, `CfSelect`, `CfTabs` y `CfTextarea`. **Por ahora solo
existen en este repositorio**; se sincronizarán con CreaFacil_Frontend en la subfase 2.5.

## Gestión del catálogo (servicios y fotos)

Fase 2 · subfase 2.4b (RF-22, RF-05, RF-04). Pestaña **Servicios** de la sección **Catálogo**.

API consumida (todas exigen el token de la administradora):

| Acción | Petición |
|---|---|
| Listar (paginado, 20 por página) | `GET /admin/servicios?pagina=&porPagina=&q=&categoriaId=&activo=` |
| Ficha completa (para editar y ver las fotos) | `GET /admin/servicios/:id` |
| Crear / editar / activar o desactivar | `POST /admin/servicios` · `PATCH /admin/servicios/:id` |
| Subir una foto (`multipart/form-data`, campo `foto`) | `POST /admin/servicios/:id/fotos` |
| Cambiar el orden (todos los ids) | `PATCH /admin/servicios/:id/fotos/orden` |
| Borrar una foto | `DELETE /admin/servicios/:id/fotos/:fotoId` |

**Tabla.** Miniatura de la portada, nombre, categoría (con la etiqueta «Categoría inactiva: no se ve en el
catálogo» si su categoría está desactivada), precio referencial («Desde $ 120,50» o «—»), número de fotos
(«2 de 8»), estado y acciones (**Editar**, **Fotos**, **Activar/Desactivar**). Buscador, filtro por categoría
(las inactivas aparecen marcadas) y filtro por estado. En pantallas estrechas, la tabla se ve como tarjetas.

**Formulario** (en un `CfDialog`, como en categorías y materiales, para no perder la tabla de vista):

- Categoría (obligatoria; si se elige una inactiva, se avisa de que el servicio no se verá), nombre (2–120),
  descripción (≤ 2000), dimensiones orientativas (≤ 200), observaciones (≤ 1000) y precio referencial
  **opcional** (mismas reglas que el precio de los materiales; viaja como texto, `"120.50"`; vacío = sin precio).
- **Materiales habituales**: lista de casillas con los materiales activos. Los que el servicio ya tenía y
  ahora están desactivados aparecen marcados con «inactivo» y se conservan (el servidor no deja añadir
  materiales desactivados nuevos). `materialIds` reemplaza la lista completa.
- Al editar se envía **solo lo que cambió** (un campo vaciado se envía como `null`). 400 en su campo; 409
  (nombre repetido **dentro de la categoría**) y 404, en un `CfMessage`. Sin envíos dobles.
- **Activar y desactivar piden confirmación.** No existe el borrado de servicios (RF-05).

**Fotos** (diálogo «Fotos del servicio»):

- **Subir** con el selector de archivos del navegador (`file_picker`). Antes de enviar se comprueban la
  extensión (JPG, PNG o WebP) y el tamaño (≤ 5 MB); el servidor valida además el **contenido real**. Se
  envía con Dio (`FormData`, campo `foto`, nombre del archivo y `contentType` según la extensión) y se
  muestra una **barra de progreso**. Errores del servidor: 400 (no es una imagen válida), 413 (más de
  5 MB) y 409 (máximo de 8 fotos), con su mensaje.
- **Cuadrícula** de miniaturas; la primera lleva la etiqueta **Portada** (es la que se ve en el catálogo).
- **Ordenar** con los botones **Mover a la izquierda**, **Mover a la derecha** y **Usar como portada**. Se
  eligieron botones en lugar de arrastrar y soltar porque funcionan con teclado y lector de pantalla y
  son más fiables en pantallas táctiles. Se envía el orden completo y se muestra el que devuelve el servidor.
- **Borrar** con confirmación (si es la portada, se avisa de que la siguiente pasa a serlo).
- Con **8 fotos**, «Subir foto» se desactiva y se explica el motivo.
- Las URL de las fotos son absolutas y se cargan sin token (en web, si el navegador no deja leer la
  imagen, se usa un elemento `<img>`).

Arquitectura: `features/catalogo/domain/servicios.dart` (entidades, `DatosServicio.cambiosRespectoA`,
`ValidacionesServicio`, contrato `ServiciosRepository`), `data/` (`ServiciosRepositoryImpl`) y
`presentation/` (`servicios_providers.dart`: `filtroServiciosProvider`, `serviciosControllerProvider`,
`opcionesCategoriasProvider`, `materialesActivosProvider` y `fotosServicioProvider(id)`; `servicios_tab.dart`,
`widgets/formulario_servicio.dart` y `widgets/fotos_servicio.dart`). El selector de archivos está detrás de
la interfaz `SelectorArchivos` (`core/archivos/`) para poder simularlo en las pruebas.

Componentes nuevos en `lib/core/design_system/` (también en `/dev/componentes`): `CfFileUpload` (zona de
carga con ayuda, motivo de deshabilitado y barra de progreso), `CfGalleria` y `CfMiniatura` (cuadrícula
de imágenes con insignia y acciones; imagen con marcador mientras carga o si falla) y `CfMultiSelect`
(selección múltiple con casillas). `CfSelect` admite ahora `hint`, `validator` y `errorText`, y
`ApiClient.post` admite `alEnviar` (progreso del envío). **Pendientes de sincronizar con
CreaFacil_Frontend en la subfase 2.5.**

## Identidad visual

Solo se usan los colores de la paleta oficial, definidos en `lib/core/theme/app_colors.dart`
(idéntico al de la app móvil). La navegación usa el azul artesanal `#244A68`.

## Ramas

- `main`: versiones estables.
- `develop`: integración. Todo cambio entra por Pull Request desde `feature/*`, `fix/*` o `refactor/*`.
