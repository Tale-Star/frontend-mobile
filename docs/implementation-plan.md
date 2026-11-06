# 📋 Tale Star — Mobile Application Implementation Plan

> **Estado:** Fase 8 — Pulido Visual, Accesibilidad, Rendimiento y QA Final Implementada y Verificada · **Versión:** 3.0  
> **Repositorio:** `StarTale_mobile` · **Framework:** Flutter SDK 3.41.9 (channel stable) · **Runtime:** Dart SDK 3.11.5 · **DevTools:** 2.54.2  
> **Entorno de desarrollo:** Windows · **Plataforma objetivo del MVP:** Android (ARCore opcional, validación en hardware físico)  
> **Soporte iOS:** Arquitectura preparada y desacoplada; implementación y validación diferidas a post-MVP  
> **Modo de trabajo:** ARCore nativo completo implementado (OpenGL ES feed de cámara, PlatformView, detección continua de planos y anclaje espacial). Hardware certificado verificado (Redmi Note 15 Pro 5G / 25080RABDG con Android 16). Desacoplamiento USE_MOCK_DATA y USE_MOCK_AR verificado. Modo Niño por PIN parental verificado. Sistema de Temas (Claro, Oscuro, Sistema) y Perfil de Usuario verificado. Auditoría y pulido de Accesibilidad (touch targets ≥ 48dp, TextScaler clamp 0.85–1.35x, TalkBack Semantics), Rendimiento (fuga de FocusNode erradicada) y Catálogo oficial de suscripciones (Go, Plus, Pro) verificado (351/351 tests passed, 0 analyzer issues, debug APK compilado exitosamente)

---

## Índice

1. [Entorno de Desarrollo Verificado y Auditoría del Repositorio](#1-entorno-de-desarrollo-verificado-y-auditoría-del-repositorio)
2. [Clasificación Funcional y Delimitación de Capacidades](#2-clasificación-funcional-y-delimitación-de-capacidades)
3. [Decisiones Arquitectónicas y Análisis de Referencia](#3-decisiones-arquitectónicas-y-análisis-de-referencia)
4. [Estructura de Carpetas](#4-estructura-de-carpetas)
5. [Dependencias Justificadas y Compatibilidad](#5-dependencias-justificadas-y-compatibilidad)
6. [Sistema de Diseño, Tokens y Tono de Comunicación](#6-sistema-de-diseño-tokens-y-tono-de-comunicación)
7. [Pantallas y Flujos de Navegación](#7-pantallas-y-flujos-de-navegación)
8. [Contratos de API Verificados y Bloqueos de Integración](#8-contratos-de-api-verificados-y-bloqueos-de-integración)
9. [Estrategia de Realidad Aumentada y Protocolo de AR Spike](#9-estrategia-de-realidad-aumentada-y-protocolo-de-ar-spike)
10. [Alineación de Historias de Usuario Críticas (US03, US04, US36)](#10-alineación-de-historias-de-usuario-críticas-us03-us04-us36)
11. [Matriz de Trazabilidad Completa](#11-matriz-de-trazabilidad-completa)
12. [Riesgos Técnicos y Mitigaciones Actualizadas](#12-riesgos-técnicos-y-mitigaciones-actualizadas)
13. [Fases de Implementación](#13-fases-de-implementación)
14. [Definición de Terminado (Definition of Done)](#14-definición-de-terminado-definition-of-done)

---

## 1. Entorno de Desarrollo Verificado y Auditoría del Repositorio

### 1.1 Entorno Confirmado en la Máquina de Desarrollo

La configuración del equipo de desarrollo Windows ha sido confirmada mediante la ejecución oficial de `flutter --version`:

| Componente | Versión Confirmada | Notas de Entorno |
|---|---|---|
| **Flutter SDK** | **3.41.9** (channel stable) | Versión del framework (Framework revision `00b0c91f06`, 2026-04-29). Engine hash `9161402dc0e134b3fb5adee5046b6e84b1a5e1c1`. |
| **Dart SDK** | **3.11.5** | Versión del lenguaje y runtime de ejecución. |
| **DevTools** | **2.54.2** | Suite de diagnóstico y perfilado de rendimiento. |
| **Restricción `pubspec.yaml`** | `environment.sdk: ^3.11.5` | Restricción sintáctica del SDK de Dart, **no** la versión del framework Flutter. |
| **SO de desarrollo** | Windows 10/11 | Entorno host de compilación. |
| **Target de prueba MVP** | Android (minSdk 24+) | Validación en emulador y dispositivo Android físico compatible. |
| **Target iOS** | Post-MVP | Código y abstracciones preparadas para iOS, validación diferida por costos de aprovisionamiento. |

> [!IMPORTANT]
> Se descartan todas las referencias ambiguas a "Flutter 3.11+". Queda claramente delimitado: el framework es **Flutter 3.41.9** y el lenguaje es **Dart 3.11.5**. Las versiones de paquetes listadas en este plan son propuestas estables sujetas a validación formal de dependencias (`flutter pub get`) durante la Fase 0.

### 1.2 Auditoría del Estado del Repositorio

| Archivo / Área | Estado Real Auditado | Impacto en la Planificación |
|---|---|---|
| `lib/main.dart` | Plantilla por defecto de Flutter (contador de clics). Sin código de producción. | Se reemplazará íntegramente tras la aprobación. |
| `pubspec.yaml` | Únicamente `cupertino_icons: ^1.0.8` y `flutter_test`. | No se han instalado paquetes todavía. |
| `analysis_options.yaml` | Reglas estándar de `package:flutter_lints/flutter.yaml`. | Base de linter activa y funcional. |
| `android/app/build.gradle.kts` | Namespace `com.startale.startale_mobile`, Java 17. | Requiere configurar `minSdk = 24` para habilitar ARCore opcional. |
| Estado de tareas del plan | Todas las casillas en `[ ]`. | **El plan refleja estrictamente el estado inicial: 0% de implementación realizada.** |

---

## 2. Clasificación Funcional y Delimitación de Capacidades

Para evitar confusiones entre interfaces visuales terminadas y capacidades verdaderamente operativas, cada funcionalidad se clasifica en una de cuatro categorías:

### 2.1 Capacidades Implementadas y Disponibles en el Backend

Endpoints verificados en el backend con esquemas confirmados:
- **Autenticación e Identidad (§5.3):**
  - Registro de usuario con `display_name`, `email`, `password` y `parental_pin` opcional (`POST /api/v1/auth/register`).
  - Inicio de sesión con credenciales (`POST /api/v1/auth/login`).
  - Consulta de perfil del usuario autenticado (`GET /api/v1/auth/me`).
- **Control Parental por PIN (§5.3.2):**
  - Configuración y actualización de PIN parental con contraseña actual (`PUT /api/v1/auth/parental-pin`).
  - Validación de PIN parental contra el backend (`POST /api/v1/auth/parental-pin/validate`).
- **Biblioteca de Contenidos (§5.4):**
  - Listado y filtrado por tipo (`image`, `story`, `music`), texto `q` y favorito (`GET /api/v1/library`).
  - Consulta de ítem individual (`GET /api/v1/library/{id}`).
  - Actualización de metadatos de biblioteca: nombre, descripción, favorito (`PATCH /api/v1/library/{id}`).
  - Eliminación de referencia en biblioteca (`DELETE /api/v1/library/{id}`).
- **Lectura Tradicional de Cuentos (§5.1):**
  - Consulta de historia (`GET /api/v1/stories/{id}`).
  - Listado ordenado de páginas (`GET /api/v1/stories/{id}/pages`).
  - Consulta individual de página (`GET /api/v1/stories/{id}/pages/{page_id}`).
- **Recuperación Multimedia Autenticada (§5.2):**
  - Descarga y streaming de assets de imagen y audio FLAC (`GET /api/v1/media/assets/{asset_id}` o vía storage key) mediante Bearer JWT.

### 2.2 Capacidades Pendientes de Implementación en Backend (Bloqueos / Dependencias)

Capacidades que requieren cambios o nuevas rutas en el backend:
- **Enlace `StoryPage` ↔ Ilustración Generada:** La tabla `creative_story_pages` no incluye clave foránea ni campo de identificación hacia los assets de `Generative Media`.
- **Edición de Perfil de Usuario:** No existe `/api/v1/profile` (PATCH) para actualizar nombre o correo.
- **Cambio de Contraseña General:** No existe `/api/v1/profile/password` (PUT). Solo existe cambio de PIN parental.
- **Catálogo y Contratación de Suscripciones:** No existe `/api/v1/plans` (GET) ni gestión de facturación en el backend del MVP.
- **Gestión Avanzada de Sesión:** El backend no publica endpoints de refresco de token (`POST /api/v1/auth/refresh`) ni revocación en servidor (`POST /api/v1/auth/logout`).
- **Servicio SMTP y Reseteo Real de Contraseña:** No existe servicio de envío de correos en el backend.

### 2.3 Capacidades Simuladas Mediante Mock para Desarrollo y Excepciones de Alcance

- **Recuperación de Contraseña (US04 — Excepción de Alcance Definitiva Aceptada):**  
  *Estado:* Conservada como simulación puramente informativa y tranquilizadora dentro de la aplicación móvil (`forgot_password_screen.dart`).  
  *Decisión definitiva aprobada:* Se ha definido de forma concluyente que la funcionalidad US04 **no tendrá implementación real en el backend de Tale Star**. No se implementarán endpoints de recuperación, integración SMTP ni emisión de tokens de reseteo. El criterio de actualización real de la contraseña (E02) queda formalmente descartado del alcance del MVP y se cierra como excepción aceptada, sin constituir una dependencia pendiente de resolución.
- **Visualización de Ilustraciones en Páginas de Cuento (Modo Mock / Fallback):**  
  *Estado:* En tanto el backend no integre el campo de ilustración en `StoryPage`, el lector 2D y el visor AR mostrarán un placeholder temático de Tale Star o el asset de portada de la biblioteca. Las pruebas automatizadas del lector emplearán datos mockeados.

### 2.4 Funcionalidades Futuras o Fuera del MVP Móvil

- Edición de perfil, cambio de contraseña general y pasarela de pago para planes de suscripción.
- Experiencia de Realidad Aumentada en iOS mediante ARKit (evaluación y hardware diferidos).
- Descarga completa de cuentos y assets para lectura sin conexión (offline mode).
- Autoría, redacción y generación de contenido (imágenes, cuentos, música), las cuales permanecen exclusivamente en la Web Application.

---

## 3. Decisiones Arquitectónicas y Análisis de Referencia

### 3.1 Análisis de `mecanaut-mobile` como Referencia

El repositorio [Experimentos-sw/mecanaut-mobile](https://github.com/Experimentos-sw/mecanaut-mobile) sirve como caso de estudio de buenas prácticas en Flutter:
- **Aportes positivos adoptados:** Organización por funcionalidades (`features/`), enrutamiento declarativo centralizado con `go_router`, cliente HTTP unificado con interceptores `dio`, y persistencia de credenciales mediante `flutter_secure_storage`.
- **Divergencias fundamentadas para Tale Star:**
  1. *Gestión de estado:* `mecanaut-mobile` usa Riverpod. Tale Star elige `flutter_bloc` / `Cubit` debido a la necesidad de máquinas de estados finitas estrictas para el ciclo de vida de Realidad Aumentada y el confinamiento de Modo Niño.
  2. *Capa de dominio:* `mecanaut-mobile` carece de una capa `domain/` formal (conecta data directamente con presentación). Tale Star incorpora `domain/` con entidades inmutables y puertos abstractos para desacoplar las reglas de lectura de cuentos y seguridad parental de las fuentes de datos.
  3. *Seguridad de caché:* Tale Star requiere un gestor de caché autenticado con aislamiento de archivos por usuario, aspecto no contemplado en la referencia.

---

### 3.2 Evaluación y Justificación de las Decisiones Arquitectónicas

#### Decisión 1: Arquitectura Feature-First Clean Architecture
- **Alternativas:** Layer-First horizontal vs Clean Architecture pura (con UseCases individuales) vs Feature-First Clean pragmática.
- **Evaluación:** Feature-First organiza el código por contextos (`authentication`, `library`, `reader`, `augmented_reality`, `child_mode`). Cada feature posee `domain` (entidades, puertos), `data` (datasources, modelos, repositorios) y `presentation` (cubit/bloc, pantallas). Se evitan UseCases redundantes para operaciones CRUD directas, manteniendo un diseño limpio y mantenible.
- **Compatibilidad SDK:** Compatible con Dart 3.11.5 y Flutter 3.41.9.
- **Motivo y Relación con Requisitos:** Modela directamente los Bounded Contexts del backend de Tale Star (DEC02, CT03) y facilita pruebas unitarias desacopladas de la interfaz.

#### Decisión 2: Gestión de Estado con `flutter_bloc` y `Cubit`
- **Alternativas:** `flutter_riverpod` vs `flutter_bloc` (Bloc/Cubit) vs `Provider`.
- **Evaluación:** `Cubit` proporciona simplicidad y reactividad predecible para flujos lineales (autenticación, biblioteca, reproductor de audio). `Bloc` orientado a eventos permite máquinas de estado finitas para el ciclo de vida de la sesión AR y el confinamiento del Modo Niño.
- **Compatibilidad SDK:** `flutter_bloc: ^9.0.0` requiere Dart 3.0+; plenamente compatible con Dart 3.11.5.
- **Motivo y Relación con Requisitos:** Garantiza predictibilidad estricta en las transiciones de estado de lectura (US36) y anclaje AR (US87–US90), con testing exhaustivo mediante `bloc_test`.

#### Decisión 3: Enrutamiento Declarativo con `go_router`
- **Alternativas:** Navigator 2.0 nativo vs `go_router` vs `auto_route`.
- **Evaluación:** `go_router` provee definición declarativa centralizada y soporte nativo de Guards reactivos:
  - *Auth Guard:* Redirige a `/login` si no existe token válido.
  - *Child Mode Guard:* Intercepta y bloquea cualquier navegación fuera de la pantalla de consumo cuando el modo protegido está activo.
- **Compatibilidad SDK:** `go_router: ^14.8.1` compatible con Flutter 3.41.9.
- **Motivo y Relación con Requisitos:** Soporta el confinamiento de seguridad de la US82 y navegación fluida entre pestañas y lecturas.

#### Decisión 4: Cliente HTTP `dio` con Interceptores
- **Alternativas:** `package:http` vs `dio`.
- **Evaluación:** `dio` permite implementar `AuthInterceptor`, que inyecta automáticamente el encabezado `Authorization: Bearer <token>` en todas las solicitudes (incluyendo descargas multimedia) y captura respuestas `401 Unauthorized` para forzar la expiración de sesión.
- **Compatibilidad SDK:** `dio: ^5.8.0` compatible con Dart 3.11.5.
- **Motivo y Relación con Requisitos:** Cumple con la exigencia de que los endpoints `/api/v1/media/...` requieren autenticación obligatoria (§5.2.2).

#### Decisión 5: Inyección de Dependencias con `get_it` Manual
- **Alternativas:** `get_it` manual vs `get_it` + `injectable` (code-gen) vs Riverpod providers.
- **Evaluación:** El registro manual en `injection.dart` elimina la dependencia de generadores de código pesados (`build_runner` continuo), acelera los tiempos de compilación y ofrece claridad total en la resolución de dependencias y mocks de prueba.
- **Compatibilidad SDK:** `get_it: ^8.0.3` compatible con Dart 3.11.5.
- **Motivo y Relación con Requisitos:** Simplicidad operativa y desacoplamiento sin magia de código generado.

#### Decisión 6: Serialización DTO y Modelos de Dominio
- **Alternativas:** Serialización manual vs `json_serializable` vs `freezed`.
- **Evaluación:** `json_serializable` genera código seguro en tiempo de compilación para DTOs en la capa `data`. Las entidades de `domain` se mantienen puras utilizando `equatable` para comparación estructural por valor.
- **Compatibilidad SDK:** `json_annotation: ^4.9.0` y `json_serializable: ^6.9.4` compatibles con Dart 3.11.5.
- **Motivo y Relación con Requisitos:** Garantiza congruencia estricta con los contratos JSON del backend de Tale Star.

#### Decisión 7: Almacenamiento Seguro y Estrategia de "Recordarme" (US03)
- **Alternativas:** Almacenar todo en `shared_preferences` vs todo en `flutter_secure_storage` vs modelo híbrido condicional.
- **Estrategia Corregida:**
  - **Si el usuario activa "Recordarme":** El token JWT se almacena de forma cifrada en `flutter_secure_storage` (Android Keystore / iOS Keychain). Al reabrir la app, se valida silenciosamente con `GET /api/v1/auth/me`.
  - **Si el usuario NO activa "Recordarme":** El token JWT se conserva **únicamente en memoria volátil de la sesión** (en `AuthRepository` / cliente `dio`). **No se persiste en almacenamiento seguro.** De este modo, si la app se cierra o el proceso es terminado por el sistema operativo, el token desaparece y se requerirá inicio de sesión manual en la siguiente ejecución, sin depender de eventos de ciclo de vida del SO.
  - **Preferencia de UI:** `shared_preferences` almacena únicamente flags no confidenciales (booleano `remember_me`, tema visual `theme_mode`).
  - **PIN Parental:** **No se almacena un PIN local.** El PIN reside exclusivamente en el backend y se valida mediante llamadas a la API.

#### Decisión 8: Reproducción de Audio Autenticado con `just_audio`
- **Alternativas:** `audioplayers` vs `just_audio` + `audio_session`.
- **Evaluación:** `just_audio` soporta headers HTTP (`headers: {'Authorization': 'Bearer ...'}`) en la URI del stream y maneja decodificación nativa de pistas FLAC entregadas por el backend de Generative Media.
- **Compatibilidad SDK:** `just_audio: ^0.9.46` y `audio_session: ^0.1.25` compatibles con Flutter 3.41.9.
- **Motivo y Relación con Requisitos:** Cumple con la reproducción de música generada protegida por autenticación (§5.2, US61).

#### Decisión 9: Caché Multimedia Autenticada y Aislamiento Multiusuario
- **Alternativas:** `cached_network_image` estándar sin headers vs gestor de caché personalizado.
- **Evaluación:** El gestor de caché `AuthenticatedCacheManager` (basado en `flutter_cache_manager`) inyecta el token Bearer en la descarga de imágenes y almacena los archivos en subdirectorios namespaces por identificador de usuario (`/cache/users/{user_id}/`).
- **Aislamiento Multiusuario:** Al cerrar sesión o alternar de usuario, el directorio de caché del usuario activo se desacopla o purga, impidiendo que otro usuario acceda a creaciones privadas previas en un dispositivo compartido (QAS04).
- **Compatibilidad SDK:** `flutter_cache_manager: ^3.4.1` compatible con Dart 3.11.5.

#### Decisión 10: Integración con ARCore como Feature Opcional y Protocolo de Spike
- **Alternativas:** `ar_flutter_plugin` comunitario vs `arcore_flutter_plugin` deprecado vs Bridge nativo Kotlin (`PlatformView` + ARCore SDK).
- **Estrategia y Spike:** No se declara viable ninguna librería de terceros a priori. En la Fase 0 se ejecutará un **AR Spike obligatorio en hardware Android físico**.
- **AR como Feature Opcional en Android:** La aplicación se configurará con `<meta-data android:name="com.google.ar.core" android:value="optional" />` en `AndroidManifest.xml`. Esto permite que la app se instale y funcione en dispositivos que no soporten ARCore, ofreciendo la experiencia de lectura 2D tradicional al 100% de los usuarios.
- **Aclaración de QAS07:** El requisito de rendimiento establece que el **inicio de la experiencia AR debe tomar ≤ 3 segundos con assets ya disponibles**, midiendo la inicialización de la sesión y cámara, y **no** el tiempo de detección de superficie física (el cual varía según textura, luz y sensores del entorno).

#### Decisión 11: Seguridad Robusta en Modo Niño y Manejo de Excepciones
- **Pérdida de Conexión:** Si no hay red al validar el PIN, el Modo Niño **permanece bloqueado**. Jamás se interpreta un fallo de conectividad como autorización para desbloquear. Se muestra un mensaje amigable: *"No pudimos conectar con el servidor para validar el PIN. Inténtalo de nuevo."*
- **Expiración de JWT:** El modo protegido se mantiene activo. Se solicita al adulto ingresar credenciales cuando se restablezca el servicio.
- **Error 500 / Fallo de Servidor:** El modo niño permanece bloqueado.
- **PIN Incorrecto:** Se mantiene bloqueado, se muestra mensaje constructivo y se aplica retardo progresivo tras 3 intentos fallidos locales para prevenir fuerza bruta.
- **Reinicio de la Aplicación:** Si el Modo Niño estaba activo antes del reinicio, se persiste un flag local (`child_mode_active: true`) para que la app reinicie directamente en el modo confinado.
- **Cierre de Sesión:** Deshabilitado mientras el Modo Niño esté activo.
- **Frontera de Seguridad:** Se distingue el control interno de la app (GoRouter guards, ocultar navegación, `PopScope` para botón atrás) de los controles del sistema operativo (botón Home o barra de tareas de Android, cuya contención total requeriría APIs nativas de Kiosk / Screen Pinning fuera del alcance de la app estándar).

---

## 4. Estructura de Carpetas

La estructura sigue el patrón **Feature-First Clean Architecture** con la separación estándar de pruebas:

```
lib/
├── main.dart                          # Punto de entrada e inicialización de servicios
├── app.dart                           # MaterialApp.router, temas y configuración
├── injection.dart                     # Contenedor de Inyección de Dependencias (get_it)
│
├── core/                              # Módulos transversales de infraestructura
│   ├── constants/
│   │   ├── api_constants.dart         # URLs y rutas de endpoints verificados
│   │   └── app_constants.dart         # Constantes de PIN (4 dígitos), timeouts, límites
│   ├── error/
│   │   ├── exceptions.dart            # Excepciones de infraestructura (Server, Cache, Auth)
│   │   └── failures.dart              # Fallos de dominio para gestión desacoplada
│   ├── network/
│   │   ├── dio_client.dart            # Configuración de Dio y timeouts
│   │   └── auth_interceptor.dart      # Inyección de Bearer token y captura de 401
│   ├── storage/
│   │   ├── secure_storage_service.dart# Custodia cifrada de JWT mediante flutter_secure_storage
│   │   ├── preferences_service.dart   # Preferencias de UI en shared_preferences
│   │   └── authenticated_cache.dart   # Caché multimedia autenticada con aislamiento por usuario
│   ├── theme/
│   │   ├── app_colors.dart            # Tokens de color oficiales (§6.1.1)
│   │   ├── app_typography.dart        # Escala tipográfica oficial (Inter y Nunito)
│   │   ├── app_spacing.dart           # Escala de espaciados (4, 8, 12, 16, 24, 32 px)
│   │   ├── app_radii.dart             # Radios oficiales (10, 16, 22 px, pastilla 999 px)
│   │   └── app_theme.dart             # ThemeData para modo claro y oscuro
│   └── router/
│       ├── app_router.dart            # GoRouter con Auth Guard y Child Mode Guard
│       └── route_names.dart           # Constantes de rutas
│
├── shared/                            # Widgets e interfaces compartidas
│   ├── widgets/
│   │   ├── ts_button.dart             # Botones primarios, secundarios, peligro y texto
│   │   ├── ts_text_field.dart         # Campos de texto con labels y manejo de errores
│   │   ├── ts_pin_field.dart          # Teclado y campo para PIN de 4 dígitos
│   │   ├── ts_card.dart               # Tarjetas con elevación y bordes oficiales
│   │   ├── ts_bottom_nav.dart         # Barra inferior de 5 pestañas en español
│   │   ├── ts_app_bar.dart            # Barra superior con marca Tale Star
│   │   ├── ts_empty_state.dart        # Estados vacíos con tono constructivo
│   │   ├── ts_loading_shimmer.dart    # Efectos de carga suaves
│   │   └── ts_snackbar.dart           # Mensajes breves de confirmación y alerta
│   └── utils/
│       ├── validators.dart            # Validadores de correo, contraseña y PIN
│       └── text_helpers.dart          # Formato de textos amigables
│
├── features/                          # Módulos funcionales de negocio
│   ├── authentication/                # EP01: Registro, Login, Recuperación simulada
│   │   ├── domain/
│   │   │   ├── entities/user_session.dart
│   │   │   └── repositories/auth_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/auth_remote_datasource.dart
│   │   │   ├── models/auth_response_model.dart
│   │   │   ├── models/register_request_model.dart
│   │   │   ├── models/login_request_model.dart
│   │   │   └── repositories/auth_repository_impl.dart
│   │   └── presentation/
│   │       ├── cubit/auth_cubit.dart
│   │       └── screens/
│   │           ├── login_screen.dart
│   │           ├── register_screen.dart
│   │           └── forgot_password_screen.dart
│   │
│   ├── library/                       # EP06: Catálogo de creaciones guardadas
│   │   ├── domain/
│   │   │   ├── entities/library_item.dart
│   │   │   └── repositories/library_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/library_remote_datasource.dart
│   │   │   ├── models/library_item_model.dart
│   │   │   └── repositories/library_repository_impl.dart
│   │   └── presentation/
│   │       ├── cubit/library_cubit.dart
│   │       ├── screens/
│   │       │   ├── library_screen.dart
│   │       │   └── image_viewer_screen.dart
│   │       └── widgets/
│   │           ├── library_item_card.dart
│   │           └── library_filter_tabs.dart
│   │
│   ├── reader/                        # EP04: Lectura 2D tradicional de cuentos
│   │   ├── domain/
│   │   │   ├── entities/story_detail.dart
│   │   │   ├── entities/story_page_detail.dart
│   │   │   └── repositories/reader_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/reader_remote_datasource.dart
│   │   │   ├── models/story_response_model.dart
│   │   │   ├── models/story_page_model.dart
│   │   │   └── repositories/reader_repository_impl.dart
│   │   └── presentation/
│   │       ├── cubit/reader_cubit.dart
│   │       ├── screens/story_reader_screen.dart
│   │       └── widgets/
│   │           ├── page_indicator_dots.dart
│   │           └── reader_control_bar.dart
│   │
│   ├── augmented_reality/             # EP09: Experiencia inmersiva AR
│   │   ├── domain/
│   │   │   ├── entities/ar_plane_status.dart
│   │   │   └── repositories/ar_controller_repository.dart
│   │   ├── data/
│   │   │   └── repositories/ar_controller_repository_impl.dart
│   │   └── presentation/
│   │       ├── bloc/ar_session_bloc.dart
│   │       ├── screens/
│   │       │   ├── ar_surface_scanner_screen.dart
│   │       │   └── ar_story_viewer_screen.dart
│   │       └── widgets/
│   │           ├── ar_reticle_overlay.dart
│   │           └── ar_page_card_view.dart
│   │
│   ├── child_mode/                    # EP08: Modo Niño y validación de PIN
│   │   ├── domain/
│   │   │   └── repositories/parental_pin_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/parental_pin_remote_datasource.dart
│   │   │   └── repositories/parental_pin_repository_impl.dart
│   │   └── presentation/
│   │       ├── cubit/child_mode_cubit.dart
│   │       ├── screens/
│   │       │   ├── pin_validation_screen.dart
│   │       │   └── pin_setup_screen.dart
│   │       └── widgets/child_mode_active_banner.dart
│   │
│   ├── music_player/                  # EP05: Reproducción de pistas musicales FLAC
│   │   ├── domain/
│   │   │   └── entities/audio_playback_state.dart
│   │   └── presentation/
│   │       ├── cubit/music_player_cubit.dart
│   │       └── widgets/mini_player_bar.dart
│   │
│   └── profile/                       # EP07: Perfil de usuario y tema
│       └── presentation/
│           ├── cubit/profile_cubit.dart
│           └── screens/profile_screen.dart
│
├── test/                              # Pruebas unitarias y de widgets
│   ├── unit/
│   │   ├── core/
│   │   ├── features/authentication/
│   │   ├── features/library/
│   │   ├── features/reader/
│   │   └── features/child_mode/
│   └── widget/
│       ├── shared_widgets_test.dart
│       └── reader_screen_test.dart
│
└── integration_test/                  # Pruebas de integración oficiales (Flutter SDK)
    ├── auth_flow_test.dart
    └── library_reader_flow_test.dart
```

---

## 5. Dependencias Justificadas y Compatibilidad

Las siguientes dependencias son propuestas estables para Flutter SDK 3.41.9 y Dart SDK 3.11.5. No se ha instalado ningún paquete en esta fase:

### 5.1 Dependencias de Producción (`dependencies`)

| Paquete | Versión Propuesta | Propósito | Estado de Validación |
|---|---|---|---|
| `flutter_bloc` | `^9.0.0` | Gestión de estado reactivo y máquinas de estados | Compatible con Dart 3.0+; sujeta a resolución en Fase 0. |
| `go_router` | `^14.8.1` | Navegación declarativa y Guards de sesión y modo niño | Compatible con Flutter 3.41.9; sujeta a resolución en Fase 0. |
| `dio` | `^5.8.0` | Cliente REST con interceptores para Bearer JWT y 401 | Compatible con Dart 3.11.5; sujeta a resolución en Fase 0. |
| `get_it` | `^8.0.3` | Inyector de dependencias (Service Locator) sin code-gen | Compatible con Dart 3.0+; sujeta a resolución en Fase 0. |
| `flutter_secure_storage`| `^9.2.4`| Cifrado de token JWT en Android Keystore | Compatible con Android minSdk 24+; sujeta a resolución en Fase 0. |
| `shared_preferences` | `^2.5.2` | Preferencias no confidenciales (recordar acceso, tema) | Paquete oficial de Flutter; sujeta a resolución en Fase 0. |
| `json_annotation` | `^4.9.0` | Anotaciones tipadas para DTOs | Compatible con Dart 3.11.5; sujeta a resolución en Fase 0. |
| `equatable` | `^2.0.7` | Comparación por valor en entidades y estados | Compatible con Dart 3.0+; sujeta a resolución en Fase 0. |
| `flutter_cache_manager`| `^3.4.1` | Base para caché autenticada con aislamiento de usuario | Compatible con Dart 3.0+; sujeta a resolución en Fase 0. |
| `just_audio` | `^0.9.46`| Reproducción de audio FLAC y paso de headers de auth | Compatible con Flutter 3.41.9; sujeta a resolución en Fase 0. |
| `audio_session` | `^0.1.25`| Foco de audio en el sistema operativo | Compatible con Flutter 3.41.9; sujeta a resolución en Fase 0. |
| `google_fonts` | `^6.2.1` | Fuentes oficiales Inter y Nunito | Compatible con Flutter 3.41.9; sujeta a resolución en Fase 0. |
| `shimmer` | `^3.0.0` | Efectos esqueleto para estados de carga visual | Compatible con Flutter 3.0+; sujeta a resolución en Fase 0. |
| `permission_handler` | `^11.4.0`| Solicitud de permisos en tiempo de ejecución (Cámara) | Compatible con Android minSdk 24+; sujeta a resolución en Fase 0. |

> [!NOTE]
> La dependencia de Realidad Aumentada queda expresamente **pendiente de validación**. Se seleccionará tras el AR Spike en hardware real Android.

### 5.2 Dependencias de Desarrollo (`dev_dependencies`)

| Paquete | Versión Propuesta | Propósito |
|---|---|---|
| `flutter_lints` | `^6.0.0` | Reglas oficiales de análisis de código para Flutter. |
| `build_runner` | `^2.4.15` | Ejecutor de tareas de generación de código estático. |
| `json_serializable` | `^6.9.4` | Generador de deserializadores DTO en tiempo de compilación. |
| `bloc_test` | `^10.0.0` | Utilidad de pruebas para Cubits y Blocs. |
| `mocktail` | `^1.0.4` | Mocks tipados sin code generation. |
| `integration_test` | `sdk: flutter` | Framework oficial de pruebas de integración incluido en el SDK. |

---

## 6. Sistema de Diseño, Tokens y Tono de Comunicación

### 6.1 Tokens Oficiales (README §6.1.1 y `tokens.css`)

```dart
// app_colors.dart
abstract class AppColors {
  // Marca Tale Star
  static const primary900 = Color(0xFF5B3DFA); // --ts-purple-900 (Botones primarios / Acento)
  static const primary700 = Color(0xFF7454FD); // --ts-purple-700 / --accent
  static const primary500 = Color(0xFF9974FE); // --ts-purple-500
  static const primary300 = Color(0xFFB194FE); // --ts-purple-300
  static const primary100 = Color(0xFFE6DBFE); // --ts-purple-100

  // Superficies y Fondos
  static const bgApp       = Color(0xFFF5F6F8); // --bg (Fondo de aplicación)
  static const surface     = Color(0xFFFFFFFF); // --surface (Tarjetas, modales)
  static const surface2    = Color(0xFFF0F1F4); // --surface-2 (Campos de entrada)
  static const surface3    = Color(0xFFE9EBEF); // --surface-3 (Bordes y separadores)

  // Texto
  static const textPrimary   = Color(0xFF15151B); // --text (Títulos principales)
  static const textSecondary = Color(0xFF5D606D); // --text-2 (Texto secundario)
  static const textTertiary  = Color(0xFF8D909B); // --text-3 (Placeholders y captions)

  // Semántica
  static const success = Color(0xFF22A06B);
  static const warning = Color(0xFFE99A22);
  static const danger  = Color(0xFFE05265);
}
```

### 6.2 Tono de Comunicación Oficial (Tone of Communication)

Tale Star se dirige a **padres, cuidadores y docentes** con un tono **cercano, claro y tranquilizador**:
- **Cercano:** Tuteo respetuoso y posesivos naturales (*"Entra a tu espacio creativo"*, *"Tu biblioteca aún está vacía"*).
- **Claro y Directo:** Verbos de acción concisos (*"Crear cuenta"*, *"Entrar a Tale Star"*, *"Colocar cuento"*).
- **Tranquilizador (Supervisión Adulta):** Refuerza la seguridad del menor (*"Un adulto debe ingresar el PIN parental para continuar"*, *"El niño solo ve lo que tú apruebas"*).
- **Sin Anglicismos ni Jerga:** Prohibido el uso de términos crudos de API o textos en inglés (*"Sign in"*, *"Error 500"*, *"JSON"*).

---

## 7. Pantallas y Flujos de Navegación

### 7.1 Orden Estricto de la Navegación Inferior (5 Pestañas)

De acuerdo con la especificación visual oficial del producto (§6.1.2), la barra de navegación inferior mantiene rigurosamente el siguiente orden:

| Posición | Pestaña | Icono | Etiqueta en Español | Ruta GoRouter |
|:---:|---|---|---|---|
| **1** | Imágenes | `image_outlined` | Imágenes | `/library?type=image` |
| **2** | Cuentos | `menu_book_outlined` | Cuentos | `/library?type=story` |
| **3** | Música | `music_note_outlined` | Música | `/library?type=music` |
| **4** | Biblioteca | `grid_view_outlined` | Biblioteca | `/library` |
| **5** | Perfil | `person_outline` | Perfil | `/profile` |

---

## 8. Contratos de API Verificados y Bloqueos de Integración

### 8.1 Bounded Context: Identity & Access (§5.3)

| Operación | Método y Ruta | Request Body | Response Body y Códigos |
|---|---|---|---|
| **Registro** | `POST /api/v1/auth/register` | `RegisterRequest`: `email` (str), `display_name` (str, máx 100), `password` (str), `parental_pin` (opcional str). | `201 Created` → `AuthResponse` (`access_token`, `user`). `409` si correo duplicado, `422`. |
| **Login** | `POST /api/v1/auth/login` | `LoginRequest`: `email` (str), `password` (str). | `200 OK` → `AuthResponse` (`access_token`, `user`). `401` credenciales inválidas. |
| **Perfil** | `GET /api/v1/auth/me` | Sin cuerpo (Header `Authorization: Bearer <token>`). | `200 OK` → `UserResponse`: `id` (UUID), `email` (str), `display_name` (str), `created_at` (datetime). |
| **Configurar PIN** | `PUT /api/v1/auth/parental-pin`| `SetParentalPinRequest`: `current_password` (str), `pin` (str 4 dígitos). | `200 OK` → `UserResponse` actualizado. `401` contraseña inválida. |
| **Validar PIN** | `POST /api/v1/auth/parental-pin/validate` | `ValidateParentalPinRequest`: `pin` (str 4 dígitos). | `200 OK` → `ValidateParentalPinResponse`: `{ "valid": bool }`. `401` si token ausente. |

### 8.2 Bounded Context: Creative Authoring — Modelo de `StoryPage` (§5.1)

Propiedades verificadas en la tabla `creative_story_pages`:
- `id`: UUID (Clave primaria)
- `story_id`: UUID (FK a `creative_stories`)
- `page_number`: Integer (Secuencial único por historia)
- `action`: Text (Descripción de la acción redactada)
- `text`: Text (Contenido narrativo de lectura)
- `visual_config`: JSON / Dict (Configuración visual guardada)
- `seed`: Integer nullable
- `character_ids`: List[UUID] (Personajes asociados)
- `created_at`, `updated_at`: DateTime(timezone=True)

> [!CAUTION]
> ### 🚨 BLOQUEO DE INTEGRACIÓN: Relación StoryPage ↔ Ilustración (Resuelto para Fase 3)
> **Estado:** La tabla `creative_story_pages` y los esquemas Pydantic `StoryResponse` y `StoryPageResponse` en el backend oficial (`app/creative_authoring`) **NO cuentan con una clave foránea ni campo `asset_id` o `illustration_url`** que enlace la página con su imagen generada.
> - **Verificación de esquemas Pydantic:** Se constató en código real del backend que `StoryResponse` únicamente contiene `id`, `title`, `description`, `scenario_id`, `style_profile_id`, `seed`, `created_at` y `updated_at`. No incluye la lista de páginas inline (requiere `GET /api/v1/stories/{id}/pages`). A su vez, `StoryPageResponse` contiene `id`, `story_id`, `page_number`, `action`, `text`, `visual_config`, `character_ids`, `seed`, `created_at` y `updated_at`.
> - **Hipótesis descartada:** No se inventaron campos ni se asumió que `visual_config['asset_id']` exista o sea confiable.
> - **Estrategia adoptada en Fase 3:**
>   1. *Mock Mode:* El cliente móvil inyecta ilustraciones de demostración (`assets/demo/story1_page*.png`) para validación visual de la experiencia.
>   2. *Modo Producción:* Si no existe asset gráfico enlazado, se muestra un marco ilustrado temático oficial de Tale Star (`StoryIllustrationFrame`), preservando el área de ilustración sin romper la maquetación y asegurando legibilidad total de la narrativa.
>   3. *Requerimiento de cambio formal al backend:* Para la integración multimedia real en Fase 5 (AR) y enriquecimiento del lector, se formaliza el pedido de incorporar en `StoryPageResponse` el campo `illustration_asset_id: Optional[UUID]` o `illustration_url: Optional[str]`.

---

## 9. Estrategia de Realidad Aumentada y Protocolo de AR Spike

### 9.1 Distinción Tecnológica y Evaluación

| Componente Técnico | Naturaleza | Consideración Arquitectónica |
|---|---|---|
| **ARCore SDK (Google)** | SDK oficial nativo de Android | Motor base para detección de planos y anclaje 3D en dispositivos compatibles. |
| **Plugins comunitarios Flutter** | Envoltorios de terceros (`ar_flutter_plugin`) | Riesgo elevado de desactualización con Gradle 8 y Java 17. |
| **SceneView** | Librería 3D/AR de terceros para Android | Alternativa moderna en Android; requiere evaluar viabilidad de puente hacia Flutter. |
| **Bridge Nativo Kotlin** | `MethodChannel` + `PlatformView` / `AndroidView` | Máximo control y estabilidad a largo plazo si los plugins comunitarios fallan. |

### 9.2 Realidad Aumentada como Feature Opcional en Android

Para asegurar que la app funcione en todos los dispositivos Android:
1. **Configuración en Manifest:** Se declarará `<meta-data android:name="com.google.ar.core" android:value="optional" />`.
2. **Verificación en Runtime:** Se consultará la disponibilidad de ARCore mediante `ArCoreApk.checkAvailability()`.
3. **Google Play Services for AR:** Si el dispositivo es compatible pero no tiene el servicio instalado, se solicitará su instalación con `ArCoreApk.requestInstall()`.
4. **Dispositivos incompatibles:** Se mostrará el mensaje amigable de la US86 (*"Tu dispositivo no admite Realidad Aumentada. Puedes disfrutar de la lectura tradicional."*) y el botón de AR quedará inactivo, permitiendo la lectura 2D convencional de forma transparente.

### 9.3 Corrección del Atributo de Rendimiento QAS07

- **Definición precisa:** QAS07 exige que el **inicio de la experiencia AR tome ≤ 3 segundos con assets ya disponibles**, midiendo la apertura de la cámara y la inicialización de la sesión ARCore.
- **Aclaración fundamental:** El tiempo para **detectar una superficie física plana** depende de las condiciones del entorno (iluminación, textura de la mesa o suelo y movimiento del usuario) y de los sensores del dispositivo, por lo que **no forma parte de la métrica estricta de arranque de software de QAS07**.

### 9.4 Resultado Empírico del AR Spike en Hardware Físico Real (Fase 5)

Durante la Fase 5 se ejecutó la auditoría formal y exhaustiva del hardware de pruebas conectado:

1. **Identificación del Dispositivo:**
   - **Identificador ADB:** `5c150480`
   - **Modelo de Hardware:** `23129RA5FL` (Xiaomi Redmi Note 13 4G, SoC Qualcomm Snapdragon 685, GPU Adreno 610, Android 14).
2. **Auditoría contra la Base Oficial de Google ARCore (`developers.google.com/ar/devices`):**
   - Se verificó la lista oficial de fabricantes y modelos compatibles con Google Play Services for AR.
   - En la familia Redmi Note 13, **únicamente el modelo superior *Redmi Note 13 Pro+* cuenta con certificación oficial de Google y soporte de Depth API**.
   - El modelo base **Redmi Note 13 4G (`23129RA5FL`) NO cuenta con calibración de cámara/IMU ni certificación ARCore de Google**.
3. **Comportamiento en Runtime:**
   - La consulta oficial `ArCoreApk.getInstance().checkAvailability()` retorna `UNSUPPORTED_DEVICE_NOT_CAPABLE`.
   - En Google Play Store, el paquete `com.google.ar.core` aparece como no compatible para este dispositivo.
4. **Cumplimiento de la Condición de Avance:**
   - Conforme a las directrices de arquitectura, **no se intentó forzar ARCore mediante APKs modificados** ni se eludió la validación oficial.
   - Se implementó la verificación nativa mediante `MethodChannel` (`com.startale.startale_mobile/ar_core`) consultando el SDK oficial `com.google.ar:core:1.46.0`.
   - Se construyó el diálogo de degradación elegante (`ArUnsupportedDialog`) para informar al usuario de manera clara, transparente y en español.
   - El Lector Tradicional 2D (`StoryReaderScreen`) permanece 100% operativo y accesible en todo momento.
   - Se implementó la arquitectura completa de Realidad Aumentada (`ArCubit`, `ArState`, escáner de superficies y visor 3D anclado) con soporte para simulación (`MockArService`), permitiendo verificar exhaustivamente la lógica de negocio y las interfaces sin declarar completada la validación de hardware real hasta contar con un dispositivo certificado.

---

## 10. Alineación de Historias de Usuario Críticas (US03, US04, US36)

### US03 — Recordar mi acceso (Estrategia sin dependencia de callbacks de SO)
- **Activado ("Recordarme" = true):** JWT persistido en `flutter_secure_storage`. Al reanudar la app, se valida con `GET /api/v1/auth/me`.
- **Desactivado ("Recordarme" = false):** JWT conservado **únicamente en memoria de sesión**. No se persiste en almacenamiento seguro. Al cerrar el proceso, la sesión desaparece de manera natural y sin riesgo de fallas de ciclo de vida.

### US04 — Recuperar mi contraseña (Excepción de Alcance Definitiva Aceptada)
- **Criterio E01 (Solicitud):** Simulado en UI mediante diálogo informativo con formato amigable y tranquilizador.
- **Criterio E02 (Actualización efectiva de contraseña):** **Excepción de alcance aceptada.** Decisión definitiva de arquitectura: no tendrá implementación real en el backend de Tale Star para el MVP. Queda cerrada como simulación informativa en cliente sin dependencias pendientes.

### US36 — Navegar entre páginas durante la lectura (Lectura 2D)
- Adaptación para el **Lector de Cuentos 2D**: navegación secuencial estricta, avance (E01), retroceso (E02) y control de bordes (E03). Se distingue conceptualmente de la **US90**, que corresponde a la navegación 3D en el entorno AR.

---

## 11. Matriz de Trazabilidad Completa

| Fase | Pantalla / Módulo | User Story | Criterios de Aceptación (Gherkin) | Endpoint Real Verificado | Pruebas Previstas | Dependencias y Bloqueos |
|:---:|---|---|---|---|---|---|
| **0** | Inicialización / Shell | — | Carga de DI, temas y enrutador. | N/A | Test unitario de inicialización de contenedor DI. | Ninguna |
| **0** | Spike AR | EP09 | Inicialización de ARCore y cámara en hardware real. | N/A (Local) | Prueba manual en hardware físico Android compatible. | Dispositivo Android con soporte ARCore. |
| **1** | Iniciar Sesión | **US02** | E01 (credenciales válidas), E02 (inválidas). | `POST /api/v1/auth/login` | `bloc_test` de `AuthCubit` y widget test con MockDio. | Backend activo. |
| **1** | Recordar Acceso | **US03** | E01 (preferencia activa en storage), E02 (volátil en memoria). | `GET /api/v1/auth/me` | Test unitario de `AuthRepository` con token volátil vs persistente. | Ausencia de refresh token en backend. |
| **1** | Crear Cuenta | **US01** | E01 (registro con `display_name`), E02 (passwords no coinciden). | `POST /api/v1/auth/register` | Widget test de formulario de registro y validadores. | Backend activo. |
| **1** | Recuperar Acceso | **US04** | E01 (solicitud simulada en UI). *E02 fuera de alcance.* | N/A (Simulado) | Widget test de validación de correo y modal informativo. | **Excepción aceptada.** No requiere backend SMTP para el MVP. |
| **2** | Biblioteca | **US63, US64, US67** | E01 (listado por tipo), búsqueda `q`, alternar favorito. | `GET /api/v1/library`, `PATCH /api/v1/library/{id}` | Test unitario de `LibraryCubit` y test de renderizado de lista. | Backend activo. |
| **2** | Visor de Imágenes | **US69** | E01 (visualización a pantalla completa de imagen protegida). | `GET /api/v1/media/assets/{id}` | Test de carga de imagen con mock de `AuthenticatedCacheManager`. | Bearer JWT obligatorio. |
| **3** | Lector Tradicional 2D | **US36** | E01 (avanzar página), E02 (retroceder), E03 (límites). | `GET /api/v1/stories/{id}/pages` | Test unitario de transiciones y control de límites en `ReaderCubit`. | Backend activo. |
| **3** | Previsualizar Cuento | **US40** | E01 (mostrar texto y visual de página). | `GET /api/v1/stories/{id}/pages` | Widget test del lector con datos mockeados. | **Bloqueo StoryPage–Ilustración:** fallback a placeholder. |
| **4** | Reproductor Musical | **US61, US69** | E01 (reproducción de pista FLAC protegida con headers). | `GET /api/v1/media/assets/{id}` | Test unitario de `MusicPlayerCubit` (play, pause, seek). | Bearer JWT obligatorio. |
| **5** | Apertura AR | **US85** | E01 (iniciar AR en cuento compatible), E02 (rechazo en no cuento). | `GET /api/v1/stories/{id}` | Test unitario de validación de tipo de contenido para AR. | Hardware compatible. |
| **5** | Dispositivo Incompatible| **US86** | E01 (aviso constructivo si no soporta ARCore). | N/A (Local) | Widget test verificando mensaje amigable de degradación. | Ninguna |
| **5** | Acceso a Cámara AR | **US87** | E01 (permiso concedido abre feed), E02 (permiso denegado). | N/A (Local) | Test de cubit mockeando `permission_handler`. | Permiso `CAMERA`. |
| **5** | Detección de Plano AR | **US88** | E01 (superficie detectada habilita botón), E02 (sin superficie).| N/A (Local) | Test de estados en `ArSessionBloc` (Scanning -> SurfaceDetected). | Entorno físico con luz/textura. |
| **5** | Colocación de Cuento | **US89** | E01 (anclaje de tarjeta virtual 3D sobre plano). | N/A (Local) | Prueba manual de anclaje de nodo en hardware real. | AR Spike aprobado. |
| **5** | Navegación AR | **US90** | E01 (avanzar en AR), E02 (retroceder en AR), E03 (límites AR). | `GET /api/v1/stories/{id}/pages` | Test de transición de páginas 3D en `ArSessionBloc`. | **Bloqueo StoryPage–Ilustración.** |
| **6** | Confinamiento Niño | **US82, US83** | E01 (bloqueo de barras globales, confinar visor, PopScope).| N/A (Router Guard) | Test de integración verificando intercepción de rutas y botón atrás. | Ninguna |
| **6** | Desbloqueo por PIN | **US78, US84** | E01 (PIN válido desbloquea), E02 (PIN inválido rechaza). | `POST /api/v1/auth/parental-pin/validate`| Test de integración con endpoint de validación de PIN. | Backend activo. Sin red = bloqueado. |
| **6** | Configuración de PIN | **US78** | E01 (actualización de PIN con contraseña actual). | `PUT /api/v1/auth/parental-pin` | Widget test de formulario de PIN de 4 dígitos. | Backend activo. |
| **7** | Perfil y Apariencia | **US74, US77** | E01 (lectura de display_name), alternancia tema claro/oscuro. | `GET /api/v1/auth/me` | Widget test de perfil y cambio de tema reactivo. | Backend activo. Edición pendiente backend. |

---

## 12. Riesgos Técnicos y Mitigaciones Actualizadas

| # | Riesgo Técnico | Severidad | Mitigación Planificada |
|---|---|---|---|
| 1 | **Bloqueo StoryPage–Ilustración** | Alta | La relación no existe en la API. Se define formalmente como hipótesis no verificada en `visual_config`. Se implementa fallback con placeholders temáticos en la app y mocks en tests, sin detener el avance del MVP. |
| 2 | **Incompatibilidad de plugins AR en Flutter 3.41.9 / Gradle 8** | Alta | Ejecución del **AR Spike obligatorio en Fase 0**. Evaluación de bridge nativo Kotlin conectando directamente con el SDK de ARCore. |
| 3 | **Falla de autenticación en recursos multimedia** | Alta | Uso obligatorio de `AuthenticatedCacheManager` para imágenes y headers Bearer en `just_audio`. |
| 4 | **Fuga de privacidad de caché en dispositivos compartidos** | Media | Aislamiento de subdirectorios de caché por `user_id` y desconexión/purga al cerrar sesión (QAS04). |
| 5 | **Recuperación de contraseña (US04) — Excepción de alcance** | Baja | Decisión definitiva aprobada: simulación puramente informativa en cliente para el MVP; no requiere backend SMTP. |
| 6 | **Fallo de conectividad durante validación de PIN parental** | Media | Política estricta: ante error de red o servidor, el Modo Niño **permanece bloqueado**. |

---

## 13. Fases de Implementación

> [!NOTE]
> Todas las tareas se conservan en `[ ]` reflejando el estado inicial real del proyecto.

### Fase 0 — Fundamentos, Arquitectura Base y AR Spike (Est. 3 días) — [COMPLETADA Y VERIFICADA]
- [x] Configurar `pubspec.yaml` con dependencias base y verificar compatibilidad con Flutter 3.41.9 y Dart 3.11.5 (15 dependencias resueltas, 0 conflictos).
- [x] Establecer estructura de carpetas Feature-First Clean Architecture y `integration_test/`.
- [x] Implementar `core/theme/` con tokens de `AppColors`, tipografía (Inter/Nunito), espaciados, radios y temas claro/oscuro.
- [x] Desarrollar `core/network/dio_client.dart` con `auth_interceptor.dart` para adjuntar JWT y capturar 401.
- [x] Implementar `secure_storage_service.dart` y `preferences_service.dart` con estrategia de sesión volátil/persistente (US03).
- [x] Configurar inyección de dependencias en `injection.dart` mediante `get_it`.
- [x] Crear componentes compartidos: `ts_button`, `ts_text_field`, `ts_pin_field`, `ts_card`, `ts_empty_state`, `ts_loading_shimmer`, `ts_snackbar`, `ts_app_bar`, `ts_bottom_nav`.
- [x] Configurar `go_router` con la barra inferior en el orden oficial: Imágenes, Cuentos, Música, Biblioteca, Perfil.
- [x] **Ejecutar AR Spike en Fase 0:** Evaluación de plugins vs bridge nativo, configuración de ARCore opcional y permisos de cámara en AndroidManifest.xml, y documentación de limitaciones del entorno sin dispositivo físico.

### Fase 1 — Autenticación y Acceso Seguro (Est. 2 días) — [COMPLETADA Y VERIFICADA]
- [x] Implementar modelos DTO: `RegisterRequestModel` (`display_name`), `LoginRequestModel`, `UserModel`, `AuthResponseModel`.
- [x] Implementar `AuthRemoteDataSource` conectando con `/register`, `/login` y `/me`.
- [x] Implementar `AuthRepository` con soporte para sesión recordada en storage vs sesión volátil en memoria (US03).
- [x] Desarrollar `AuthCubit` y sus estados (`AuthInitial`, `AuthLoading`, `Authenticated`, `Unauthenticated`, `AuthError`, `PasswordResetSent`).
- [x] Construir `login_screen.dart` con validación y checkbox "Recordarme".
- [x] Construir `register_screen.dart` con `display_name`, correo, contraseña, confirmación y PIN parental opcional.
- [x] Construir `forgot_password_screen.dart` con flujo simulado y aviso explicativo (US04 parcial).
- [x] Activar **Auth Guard** en `go_router` conectado reactivamente a los estados de autenticación.
- [x] Pruebas unitarias de `AuthRemoteDataSource`, `AuthRepository`, `AuthCubit` y widget tests de pantallas de autenticación (61 tests pasados en total).

### Fase 2 — Biblioteca y Exploración de Contenido (Est. 3 días) — [COMPLETADA Y VERIFICADA]
- [x] Implementar DTOs y entidad de dominio `LibraryItem` (`LibraryItemEntity`, `ContentType`, `LibraryItemModel`).
- [x] Implementar `LibraryRemoteDataSource` para `GET /api/v1/library` con filtros (`image`, `story`, `music`, `q`, `favorite`), `GET /api/v1/library/{id}` y `PATCH /api/v1/library/{id}` con mapeo de errores HTTP (401, 404, 422, timeouts).
- [x] Implementar `LibraryRepository` con soporte para favoritos (`PATCH /api/v1/library/{id}`) y conversión de excepciones a `Failure`s de dominio.
- [x] Desarrollar `LibraryCubit` con búsqueda debounced (400ms), filtro por tipo, filtro de favoritos, actualización optimista sincronizada y pull-to-refresh.
- [x] Construir pantalla principal con pestañas en orden oficial: Imágenes (`images_screen.dart`), Cuentos (`stories_tab_screen.dart`), Música (`music_tab_screen.dart`), Biblioteca general (`library_screen.dart`), Perfil (`profile_screen.dart`). Cuentos y música integran estados informativos claros hacia las Fases 3 y 4.
- [x] Implementar `AuthenticatedCacheManager` con subdirectorios y llaves de aislamiento por `user_id` (`ts_media_cache_$userId`), inyección de Bearer JWT en `AuthenticatedHttpFileService`, resolución de URLs relativas y purga en cierre de sesión (`clearAllCaches()`).
- [x] Construir visor de imágenes en pantalla completa (`image_viewer_screen.dart`) con zoom interactivo (`InteractiveViewer`), desplazamiento panorámico y alternancia de favoritos accesible (touch target ≥ 44px).
- [x] Pruebas unitarias de `LibraryItemModel`, `LibraryRemoteDataSource`, `LibraryRepository`, `LibraryCubit`, `AuthenticatedCacheManager` y widget tests de pantallas de biblioteca (117 tests pasados en total en la suite).

### Fase 3 — Lector Tradicional 2D (Est. 3 días) — [COMPLETADA Y VERIFICADA]
- [x] Implementar DTOs reales de `StoryModel` y `StoryPageModel` (sin asumir `illustration_url`).
- [x] Implementar `ReaderRemoteDataSource` para `/stories/{id}` y `/stories/{id}/pages`.
- [x] Desarrollar `ReaderCubit` gestionando navegación secuencial, página actual y límites (US36).
- [x] Construir pantalla del lector 2D (`story_reader_screen.dart`) con fallback de placeholders oficiales.
- [x] Soporte para gestos táctiles de deslizamiento (swipe).
- [x] Pruebas unitarias de navegación y límites de página (198 tests en total pasando en la suite completa, 0 issues de análisis estático).

### Fase 4 — Reproducción Musical FLAC (Est. 1 día) — [COMPLETADA Y VERIFICADA]
- [x] Configurar `just_audio` con soporte para streaming autenticado mediante headers `Authorization: Bearer <token>`, decodificación nativa FLAC/Lossless y configuración de `audio_session`.
- [x] Implementar arquitectura Feature-First en `lib/features/music/` (entidad `MusicTrack`, `AudioPlayerService`, `JustAudioPlayerServiceImpl`, `MusicRepository`, `MusicRepositoryImpl` y `MockMusicRepository`).
- [x] Desarrollar `MusicPlayerCubit` gestionando estados (`initial`, `loading`, `playing`, `paused`, `buffering`, `completed`, `error`), control de posición, duración, buffering y limpieza de sesión en logout (`clearSession`).
- [x] Construir barra de mini-reproductor persistente (`persistent_mini_player.dart`) situada sobre `TsBottomNav` visible transversalmente en las 5 pestañas oficiales.
- [x] Construir pantalla completa de reproducción musical (`music_player_screen.dart`) con carátula de disco vinilo animado (`music_waveform_visualizer.dart`), badges de calidad FLAC Lossless, slider de búsqueda y controles de reproducción (+/-10s, favorito, play/pause).
- [x] Integrar reproducción musical directamente en `music_tab_screen.dart` y `library_screen.dart`, sustituyendo los diálogos placeholder de fases previas.
- [x] Soporte para Modo Demostración sin backend con generación de asset de audio local (`assets/demo/demo_song.wav`) para validación en hardware físico Android.
- [x] Suite completa de pruebas unitarias y de widgets (230/230 tests pasando, 0 issues de análisis estático y debug APK compilado exitosamente).

### Fase 5 — Realidad Aumentada (AR) en Android — [COMPLETADA, REFINADA Y VERIFICADA EN HARDWARE REAL]
- [x] **Validación Obligatoria de Hardware (AR Spike):** Verificación de compatibilidad con Google ARCore en hardware físico. Inicialmente auditado en `23129RA5FL` (Redmi Note 13 4G) con degradación elegante. Verificado y validado en hardware certificado oficial: **Xiaomi Redmi Note 15 Pro 5G** (Modelo `25080RABDG`, Android 16 / API 36, ADB `xgpr5lfqfizxgmv8`), listado oficialmente en Google ARCore Supported Devices con soporte Depth API y paquete `com.google.ar.core` instalado.
- [x] **Diagnóstico Dinámico de Hardware sin Hardcoding:** Consulta nativa en tiempo de ejecución de `Build.MANUFACTURER`, `Build.BRAND`, `Build.MODEL`, `Build.DEVICE`, `Build.VERSION.SDK_INT` y `Build.VERSION.RELEASE`. Erradicación completa de nombres de terminales fijos. Mensajes informativos construidos dinámicamente según el estado real reportado por Google Play Services for AR.
- [x] **Desacoplamiento Arquitectónico (USE_MOCK_DATA vs USE_MOCK_AR):**
  - `USE_MOCK_DATA`: Administra exclusivamente los orígenes de datos (Auth, Library, Reader, Music).
  - `USE_MOCK_AR`: Administra exclusivamente el subsistema AR (`false` por defecto para usar hardware y sesión real).
  - Prioridad operativa habilitada: `USE_MOCK_DATA=true` con `USE_MOCK_AR=false` permite probar cuentos de demostración sobre hardware ARCore y cámara física real sin necesidad de backend en la nube.
  - Regla de seguridad: En `staging` y `production`, ambos flags están estrictamente prohibidos (siempre `false`).
- [x] **Renderizado Nativo de Feed de Cámara (OpenGL ES 2.0):** Implementación de `BackgroundRenderer.kt` con shaders GLSL externos (`GL_OES_EGL_image_external`), textura `GL_TEXTURE_EXTERNAL_OES` y transformación continua de coordenadas de visualización mediante `frame.transformCoordinates2d`.
- [x] **Sesión ARCore y Detección Optimizada de Superficies:**
  - Soporte para **Instant Placement** (`Config.InstantPlacementMode.LOCAL_Y_UP`) con fallback defensivo, permitiendo estimar superficies horizontales al instante sin esperar a la reconstrucción completa de polígonos convexos.
  - Muestreo continuo por **Hit-Testing en tiempo real** en el centro de la pantalla (`frame.hitTest(centerX, centerY)`), verificando colisión contra planos (`Plane`) con `isPoseInPolygon` o `isPoseInExtents`, así como contra puntos instantáneos (`InstantPlacementPoint`).
  - Detección y distinción rigurosa de 4 estados del subsistema AR: (1) Buscando superficies, (2) Pérdida o degradación de tracking con causa raíz (`EXCESSIVE_MOTION`, `INSUFFICIENT_LIGHT`, `INSUFFICIENT_FEATURES`), (3) Superficie detectada pero sin punto válido bajo la retícula, y (4) Punto válido listo para anclaje.
  - Telemetría en tiempo real hacia Flutter (`ArStatusUpdate` a través de EventChannel a 8 Hz) con estados de tracking, conteo de planos, distancia en metros y proyección de pantalla.
- [x] **Retícula Espacial y Colocación Intuitiva de Cuentos:**
  - Retícula central dinámica (`ArReticle`) con animaciones de pulso y perspectiva 3D sobre el plano detectado, alternando visualmente entre búsqueda (anillo sutil punteado), superficie detectada (anillo ámbar) y punto bloqueado (doble anillo violeta con estrella central de anclaje).
  - Colocación dual del cuento: mediante el botón principal "Colocar cuento" o tocando directamente cualquier coordenada de la superficie detectada en pantalla (Tap-to-place).
  - Panel de diagnóstico en tiempo real (`ArDiagnosticPanel`, activo exclusivamente en `kDebugMode`) con métricas en vivo de ARCore, FPS, conteo de planos, tracking state y distancia estimada.
- [x] **Anclaje Espacial 3D Real (World-to-Screen Projection):**
  - Creación de anclajes nativos mediante `HitResult.createAnchor()` en la posición exacta del raycast, o fallback a `plane.createAnchor(pose)`.
  - Proyección matemática en tiempo real del anclaje 3D a coordenadas de pantalla 2D mediante multiplicación de matrices OpenGL (`ViewMatrix` * `ProjectionMatrix` * `AnchorPose`).
  - La tarjeta del cuento (`ArStoryCard3d`) responde reactivamente a los movimientos de la cámara en el espacio físico (`spatialOffsetX`, `spatialOffsetY`, `spatialScaleMultiplier`), anclándose de forma fotorrealista a la mesa o suelo.
- [x] **Integración con Flutter mediante PlatformView:** Registro de fábrica `ArCorePlatformViewFactory.kt` y vista nativa `com.startale.startale_mobile/ar_view` expuesta mediante el widget `ArCameraFeedView` visible tanto en el escaneo (`ar_surface_scanner_screen.dart`) como en el lector anclado (`ar_story_viewer_screen.dart`).
- [x] **Refinamiento UX/UI Inmersivo (Mobile AR Story Reader MU-09):**
  - Transformación del visor en una tarjeta/página tridimensional (`ArStoryCard3d`) anclada en el espacio de la cámara con borde blanco físico, proporciones polaroide/hoja de libro (ancho ~310dp, alto ~470dp, ilustración ~56% del alto), radio de 22dp, sombra de oclusión ambiental multicapa (`BoxShadow`) y perspectiva física 3D (`Matrix4` con `setEntry(3, 2, 0.001)` y cabeceo/inclinación orgánica derivada de la pose relativa cámara-anclaje).
  - El fondo de la cámara real permanece despejado y brillante alrededor de la tarjeta, eliminando la sensación de pantalla plana superpuesta.
  - Controles flotantes circulares mínimos (`ArFloatingControls` con `<  3/6  >`) y chip superior flotante (`ArTopBar` con insignia de estrella, título de cuento de hasta 2 líneas para evitar elipsis como "La Pequeña Estrella P..." y número de página).
  - Resolución dinámica de ilustraciones por página (`_resolveIllustrationAsset`) enlazando `demo_forest.png`, `demo_castle.png` y `demo_space.png` desde `MockReaderRepository`.
  - Eliminación de la insignia invasiva "AR" superpuesta en la ilustración artística.
- [x] **Área Narrativa con Desplazamiento Vertical Dedicado (Sin Truncado):**
  - Causa raíz resuelta: sustitución de `maxLines: 4` y `TextOverflow.ellipsis` con tipografía itálica rígida por un contenedor scrolleable dedicado (`SingleChildScrollView` con `ScrollController` independiente).
  - Tipografía oficial Inter regular (sin cursiva, color `#1E1F27`, tamaño 13.5px, interlineado 1.48) garantizando legibilidad total de historias extensas.
  - Indicador discreto de scroll con desvanecimiento de gradiente suave y flecha tenue animada, que desaparece automáticamente al alcanzar el final del texto.
  - Reseteo automático del scroll al inicio (`animateTo(0.0)`) al avanzar o retroceder de página en el cuento.
  - Desacoplamiento de gestos táctiles: el arrastre vertical de 1 dedo sobre el texto desplaza la narrativa; el arrastre sobre la ilustración rota la tarjeta (guiñada); el pellizco con 2 dedos escala el tamaño (zoom).
- [x] **Cálculo Espacial Preciso de Anclaje 3D (Relative Pose & Perspective Tilt):**
  - En `ArCorePlatformView.kt`, cálculo de la pose relativa cámara-anclaje con `val relPose = cameraPose.inverse().compose(anchorPose)`.
  - Estimación de ángulos físicos de visión: `anchorYaw = atan2(relX, -relZ)` y `anchorPitch = atan2(relY, -relZ)` emitidos en la telemetría `statusData`.
  - Proyección de coordenadas de pantalla normalizadas (`anchorNormX`, `anchorNormY`) mapeadas dinámicamente al tamaño del viewport lógico en Flutter.
  - Escalado por distancia inversa `(0.85 / anchorDistance).clamp(0.55, 1.85)` y cabeceo/guiñada que responden al movimiento físico del usuario alrededor del objeto.
- [x] **Corrección Integral del Botón de Cierre / Salida (X):**
  - Diagnóstico de causa raíz: El botón 'X' en la versión previa era eclipsado por el área de visualización del `SingleChildScrollView` de altura completa en el `Stack`, absorbiendo los gestos del usuario antes de que alcanzaran el botón.
  - Solución implementada: Reordenamiento riguroso del `Stack` con `ArTopBar` en la cima absoluta de la jerarquía visual; touch target extendido a 44x44px; `PlatformViewHitTestBehavior.transparent` en `AndroidView` nativo; e inclusión de salidas redundantes (acción "Salir de AR" en la base, botón en escáner y cierre seguro desde el menú modal).
- [x] **Interactividad Espacial y Manipulación del Cuento:**
  - Gesto interactivo de pellizco (Pinch-to-zoom) para escalar la tarjeta (`cardScale`) y deslizamiento horizontal para rotación/guiñada (`cardRotationY`).
  - Menú modal de opciones espaciales (`...`) para "Recolocar cuento en otra superficie" (`repositionStory`) y "Restablecer tamaño y orientación" (`resetCardTransform`).
  - Limpieza segura de ciclo de vida nativo con callback `onDisposed` en `ArCorePlatformViewFactory.kt` y `MainActivity.kt` para desvincular referencias activas de forma atómica al salir.
- [x] **Ciclo de Vida Nativo Seguro:** Sincronización de pausas y reanudaciones de cámara/sesión en `MainActivity.kt` (`onResume`, `onPause`, `onDestroy`).
- [x] **Degradación Elegante:** Diálogo constructivo `ArUnsupportedDialog` para terminales sin certificación oficial, asegurando la continuidad transparente hacia el lector 2D.
- [x] **Suite de Pruebas Automatizadas y Compilación:** 267 tests unitarios y de widgets ejecutados exitosamente (100% pass, incluyendo tests de scroll del lector AR, rotación por gestos y títulos multilinea), 0 advertencias de análisis estático (`flutter analyze`) y verificación de compilación de debug APK.

### Fase 6 — Modo Niño y Seguridad por PIN Parental (Est. 2 días) — [COMPLETADA Y VERIFICADA]
- [x] **Implementación de DTOs y Fuentes de Datos:** Creación de `SetParentalPinRequestModel`, `ValidateParentalPinRequestModel` y `ValidateParentalPinResponseModel`, junto con `ParentalPinRemoteDataSource` conectado a `PUT /api/v1/auth/parental-pin` y `POST /api/v1/auth/parental-pin/validate` bajo contratos OpenAPI y schemas Pydantic verificados del backend. Mapeo estricto de códigos HTTP (400, 401, 404, 422, 500 y timeouts de Dio) a excepciones tipadas de dominio.
- [x] **Repositorio y Modo Mock Desacoplado:** `ParentalPinRepositoryImpl` con conversión a `Failure`s de dominio y `MockParentalPinRepository` para desarrollo con hash salted SHA-256 en memoria, PIN inicial por defecto `"1234"`, y soporte para simular errores de red (`error_red`) y servidor (`error_servidor`).
- [x] **Gestor de Estado (ChildModeCubit) y Resiliencia de Sesión:** Manejo de estados (`ChildModeInactive`, `ChildModeActivating`, `ChildModeActive`, `ChildModeUnlocking`, `ChildModeValidationError`, `ChildModeRestoring`). Persistencia atómica de sesión en `PreferencesService` (`child_mode_active`, `child_mode_content_type`, `child_mode_content_id`, `child_mode_content_title`, `child_mode_route_context`, `child_mode_user_id`). Restauración reactiva en arranque de aplicación asegurando confinamiento ininterrumpido.
- [x] **Configuración y Cambio de PIN Parental (`pin_setup_screen.dart`):** Formulario protegido que exige contraseña actual de la cuenta, nuevo PIN de 4 dígitos y confirmación idéntica. Indicadores de fortaleza, visualización de errores contextuales en español y actualización reactiva en `AuthCubit` (`updateUserPinConfigured`).
- [x] **Diálogo de Validación y Teclado Numérico Accesible:** `PinValidationDialog` modal con indicador de 4 dígitos enmascarados (`PinDotsIndicator`), teclado virtual táctil accesible (`PinKeypad`) con touch targets ≥ 48px, retroalimentación táctil y bloqueo por fuerza bruta con temporizador de enfriamiento de 30 segundos tras 3 intentos erróneos.
- [x] **Seguridad por Defecto (Secure by Default):** Prohibido el almacenamiento en texto plano del PIN parental en almacenamiento local o secure storage. Si ocurre una pérdida de conectividad, timeout o error 500 del servidor, el Modo Niño **permanece estrictamente activo y bloqueado**, impidiendo el escape no autorizado del menor. Cierre forzado de sesión (401 global) purga la sesión de modo niño de forma segura.
- [x] **Child Mode Guard y Confinamiento Exhaustivo en GoRouter:** Enrutador `app_router.dart` suscrito a cambios de `ChildModeCubit`. Intercepción y redirección automática hacia la pantalla de contenido confinado si el usuario intenta navegar a rutas no autorizadas (pestañas de biblioteca, perfil, configuración). Ocultamiento reactivo de la barra de navegación inferior (`TsBottomNav`) y del reproductor flotante persistente (`PersistentMiniPlayer`).
- [x] **Protección de Salida con PopScope en Todos los Visores:** Intercepción del botón físico/gestual de atrás de Android en el Lector 2D (`StoryReaderScreen`), Visor AR (`ArStoryViewerScreen` y `ArSurfaceScannerScreen`), Visor de Imágenes (`ImageViewerScreen`) y Reproductor de Música (`MusicPlayerScreen`), solicitando el PIN parental antes de permitir el retorno.
- [x] **Insignia Visual y Activación Guiada:** Botón dedicado "Activar Modo Niño" (`ActivateChildModeSheet`) con hoja modal inferior que comprueba si el adulto ya tiene PIN configurado (o redirige fluidamente a su creación), e insignia visual interactiva (`ChildModeActiveBadge`) en la cabecera del visor que permite al adulto solicitar el PIN para salir con un solo toque.
- [x] **Suite de Pruebas Automatizadas y Compilación:** 49 nuevas pruebas unitarias y de widgets exclusivas de Fase 6 (100% exitosas), alcanzando 316/316 pruebas aprobadas en la suite total del proyecto móvil, con 0 advertencias de análisis estático y verificación de compilación APK de desarrollo.

### Fase 7 — Perfil, Apariencia y Ajustes (Est. 1 día) — [COMPLETADA Y VERIFICADA]
- [x] **Alineación con el Backend (`GET /api/v1/auth/me`):** Sincronización completa con el contrato oficial. Soporte tolerante para `parental_pin_configured` y `pin_configured` en `UserModel.fromJson` y `toJson`, serialización de `created_at` seguro con fallback defensivo, e implementación de `getProfile()` en `AuthRepository`, `AuthRepositoryImpl` y `MockAuthRepository`.
- [x] **Sistema de Temas Dinámicos y Persistencia:** Creación de `ThemeCubit` y enumeración `AppThemeMode` (`system`, `light`, `dark`) sincronizado con `PreferencesService`. Integración en `AppTheme` con `ThemeContextExtension` (`isDarkMode`, superficies y paletas adaptables) e inyección en `MaterialApp.router` para reactividad inmediata a nivel de aplicación.
- [x] **Gestor de Perfil (ProfileCubit) y Resiliencia:** Estados de ciclo de vida (`ProfileInitial`, `ProfileLoading`, `ProfileLoaded`, `ProfileError`). Manejo de caché de usuario inicial para carga instantánea sin parpadeos, recarga pull-to-refresh y sincronización en tiempo real con cambios de PIN.
- [x] **Pantalla de Perfil (`profile_tab_screen.dart`):** Tarjeta de identidad del usuario con avatar con iniciales dinámicas, nombre, correo y fecha de registro en español; tarjeta de seguridad parental con acceso a configuración de PIN (`PinSetupScreen`); tarjeta informativa de Modo Niño; tarjeta de tema con selector modal (`ThemeSelectionSheet`); tarjeta informativa de membresía y suscripción (`SubscriptionPlansSheet`); y botón accesible de cierre de sesión.
- [x] **Información Transparente de Suscripciones:** Hoja modal (`SubscriptionPlansSheet`) detallando el Plan Explorador y el Plan Creador Familiar, con aviso explícito y claro de que las suscripciones y pagos se gestionan exclusivamente en la plataforma web oficial de Tale Star (sin pasarelas de pago ni cargos directos en la app móvil).
- [x] **Cierre de Sesión Seguro en Cascada:** Protocolo `_performLogout` que detiene y limpia de forma atómica: (1) `MusicPlayerCubit.clearSession()`, (2) `ArCubit.exitAr()`, (3) `LibraryCubit.clearSession()`, (4) `ChildModeCubit.clearSession()`, y (5) `AuthCubit.logout()`. Purga de tokens en `SecureStorageService`, preferencias no esenciales en `PreferencesService` y borrado de caché multimedia privada en `AuthenticatedCacheManager`, activando el `AuthGuard` de GoRouter hacia `/login` e invalidando el historial de navegación.
- [x] **Adaptabilidad Temática Global:** Refactorización de componentes y pantallas existentes (`TsAppBar`, `TsBottomNav`, `TsTextField`, `PersistentMiniPlayer`, `PinSetupScreen`, `PinValidationDialog`, `PinKeypad`, `LoginScreen`, `RegisterScreen`, `LibraryScreen`, `StoryReaderScreen`, `MusicPlayerScreen`) para garantizar legibilidad, contraste y elegancia tanto en modo claro como en modo oscuro.
- [x] **Suite de Pruebas Automatizadas y Compilación:** 35 pruebas unitarias y de widgets exclusivas de Fase 7 (100% aprobadas), alcanzando 351/351 pruebas exitosas en la suite total de la aplicación móvil, con 0 advertencias de análisis estático (`dart analyze lib test`) y verificación de compilación APK.

### Fase 8 — Pulido, Accesibilidad, Rendimiento y QA Final (Est. 2 días) — [COMPLETADA Y VERIFICADA]
- [x] **Auditoría de Textos y Tono de Comunicación:** 100% en español con tono cercano, cálido, comprensible y tranquilizador sin tecnicismos ni stack traces en UI. Erradicación de términos técnicos en mensajes de error.
- [x] **Alineación Oficial de Planes de Suscripción (README §7.1 US80):** Corrección del catálogo informativo en `subscription_plans_sheet.dart` adoptando los tres planes oficiales de Tale Star: **Plan Go** (USD 10/mes), **Plan Plus** (USD 20/mes) y **Plan Pro** (USD 100/mes), con aviso explícito y transparente de que la contratación, facturación y pagos se realizan exclusivamente en Tale Star Web (cero pasarelas ni cargos directos en la app móvil).
- [x] **Accesibilidad y Touch Targets:** Extensión de todas las áreas táctiles interactivas a ≥ 48 x 48 dp (incluyendo botones de favoritos en `LibraryItemCard`, controles multimedia y botones de acción rápida). Incorporación de semántica para lectores de pantalla TalkBack (`Semantics`) en dígitos, retroceso y limpieza de `PinKeypad`. Inclusión de tooltips descriptivos en controles iconográficos de reproducción y formularios.
- [x] **Resiliencia ante Escalado de Fuentes (Text Scaling):** Inyección de `mediaQuery.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.35)` en el builder global de `MaterialApp.router` en `app.dart`, blindando la interfaz ante desbordamientos visuales (overflows) en dispositivos configurados con tipografía gigante, manteniendo total legibilidad y flexibilidad visual.
- [x] **Optimización de Rendimiento y Prevención de Fugas de Memoria:** Erradicación de la fuga de memoria en `TsPinField` provocada por la instanciación de `FocusNode()` no gestionados dentro del método `build()`; transición a un ciclo de vida gestionado en el estado (`_keyboardFocusNodes`) con liberación atómica en `dispose()`.
- [x] **Consistencia de Temas (Modo Oscuro / Modo Claro):** Adaptación y homogeneización temática en componentes compartidos y pantallas del sistema (`TsCard`, `TsEmptyState`, `TsLoadingShimmer`, `TsButton`, `LibraryItemCard`, `LibraryScreen`, `StoryReaderScreen`, `ReaderControlBar`, `MusicPlayerScreen`, `ArUnsupportedDialog`) eliminando tokens de color estáticos y aprovechando los tokens dinámicos de `Theme.of(context)` y `AppColors`.
- [x] **Auditoría de Seguridad y Confinamiento:** Verificación de almacenamiento seguro para tokens JWT (`flutter_secure_storage`), exclusión de PIN parental de cualquier persistencia local en texto plano, aislamiento de cachés multimedia privadas por usuario autenticado, y preservación inquebrantable de los guards de Modo Niño (`PopScope`, `ChildModeGuard`, intercepción en GoRouter).
- [x] **Suite Completa de Pruebas Automatizadas:** 351 pruebas unitarias y de widgets ejecutadas exitosamente (100% pass), cubriendo arquitectura limpia, repositorios con modo mock, cubits y gestión de estados, pantallas, visores y accesibilidad.
- [x] **Análisis Estático Riguroso:** `dart analyze lib test` sin errores ni advertencias (0 issues).
- [x] **Compilación y Auditoría de Firma Release:** Compilación Debug APK verificada (`build/app/outputs/flutter-apk/app-debug.apk`). Auditoría de configuración release en Gradle confirmando preparación para firmas de distribución cuando se apruebe el pase a producción.
- [x] **Matriz de Pruebas Manuales para Hardware Físico:** Documentación de 15 casos de prueba exhaustivos listos para ejecución en hardware real (Xiaomi Redmi Note 15 Pro 5G / Android 16).

---

## 14. Definición de Terminado (Definition of Done)

Una tarea o fase se considerará **Completada (Done)** únicamente cuando:

1. **Criterios de Aceptación:** Se verifican los escenarios Gherkin especificados en la User Story correspondiente.
2. **Fronteras Arquitectónicas:** Se respeta Feature-First Clean Architecture (cero dependencias de `domain` hacia `data` o UI).
3. **Manejo de Estados Exhaustivo:** Cubits/Blocs contemplan carga, éxito, error constructivo y estado vacío.
4. **Seguridad Robusta:** JWT protegido; sin PIN parental local; caché multimedia aislada por `user_id`. Modo niño inquebrantable ante fallos de red.
5. **Tono de Comunicación:** Textos 100% en español, amables, claros y tranquilizadores, sin tecnicismos de backend.
6. **Accesibilidad:** Touch targets ≥ 44 px y contraste visual verificado.
7. **Pruebas Automatizadas:** Pruebas unitarias o de widgets asociadas ejecutadas con éxito.
8. **Sin Advertencias:** Código analizado con cero advertencias bajo `flutter_lints`.

---

> [!IMPORTANT]
> **Este Implementation Plan v2.1 requiere su aprobación formal antes de iniciar la ejecución de la Fase 0.**
