# CreaFacil_AdminWeb

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

## Comandos

| Comando | Qué hace |
|---|---|
| `flutter analyze` | Análisis estático |
| `dart format lib test` | Formatea el código |
| `flutter test` | Pruebas |
| `flutter build web` | Compila el panel en `build/web` |

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
```

## Identidad visual

Solo se usan los colores de la paleta oficial, definidos en `lib/core/theme/app_colors.dart`
(idéntico al de la app móvil). La navegación usa el azul artesanal `#244A68`.

## Ramas

- `main`: versiones estables.
- `develop`: integración. Todo cambio entra por Pull Request desde `feature/*`, `fix/*` o `refactor/*`.
