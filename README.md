# Taller Mecánico — App de Gestión

Aplicación móvil desarrollada en **Flutter** para la administración integral de un taller mecánico. Permite gestionar órdenes de servicio, clientes, catálogo de servicios y refacciones, con notificaciones locales de recordatorio y visualización estadística por mes.

---

## Características principales

### Órdenes de Servicio
- Calendario interactivo con marcadores de color por estado de la orden
- Listado con filtros por estado (Todos / Pendiente / En Progreso / Completado / Cancelado)
- Creación de órdenes con selección de cliente, servicios y refacciones (carrito)
- Edición y cancelación mediante gesto de deslizamiento (Dismissible)
- Programación de recordatorios con notificaciones locales

### Clientes
- CRUD completo: crear, editar y eliminar clientes
- Búsqueda en tiempo real por nombre, placa o teléfono
- Almacena datos personales y datos del vehículo (modelo, placa, año)

### Catálogo
- CRUD de **servicios de mano de obra**: nombre, descripción, precio estimado, duración y categoría
- CRUD de **refacciones**: nombre, código de parte, precio, stock, marca y categoría
- Indicador visual de stock por colores (verde / naranja / rojo)

### Estadísticas
- Resumen mensual navegable (mes anterior / siguiente)
- KPI de ingresos totales del mes
- KPI de total de órdenes
- Desglose por estado en tarjetas con números grandes
- Barra de progreso de tasa de completadas

### Diseño
- Tema claro y **tema oscuro** alternables desde cualquier pantalla
- Diseño Material 3 con `NavigationBar` de 4 secciones
- Colores, tipografía y elevación consistentes en ambos temas

---

## Capturas de pantalla

> *Agregar capturas de pantalla aquí.*

---

## Tecnologías y paquetes

| Paquete | Versión | Uso |
|---|---|---|
| [`sqflite`](https://pub.dev/packages/sqflite) | ^2.3.2 | Base de datos SQLite local |
| [`path`](https://pub.dev/packages/path) | ^1.9.0 | Rutas del sistema de archivos |
| [`table_calendar`](https://pub.dev/packages/table_calendar) | ^3.1.2 | Calendario interactivo |
| [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) | ^17.2.2 | Notificaciones locales programadas |
| [`timezone`](https://pub.dev/packages/timezone) | ^0.9.4 | Manejo de zonas horarias para notificaciones |
| [`flutter_timezone`](https://pub.dev/packages/flutter_timezone) | ^2.0.0 | Obtener la zona horaria del dispositivo |
| [`intl`](https://pub.dev/packages/intl) | ^0.19.0 | Formateo de fechas y moneda en español |
| [`badges`](https://pub.dev/packages/badges) | ^3.1.2 | Badge en el ícono de carrito |

**SDK:** Flutter >= 3.38.0 · Dart ^3.10.7 · Android SDK 36

---

## Arquitectura del proyecto

```
lib/
├── main.dart                      # Punto de entrada, tema claro/oscuro, TallerApp
├── database/
│   └── database_helper.dart       # Singleton SQLite, CRUD completo
├── models/
│   ├── cliente.dart
│   ├── orden_servicio.dart
│   ├── servicio_mano_obra.dart
│   ├── refaccion.dart
│   ├── categoria_servicio.dart
│   └── categoria_refaccion.dart
├── screens/
│   ├── home_screen.dart           # NavigationBar principal (4 tabs)
│   ├── ordenes_screen.dart        # Calendario + lista de órdenes con filtros
│   ├── registro_orden_screen.dart # Crear nueva orden
│   ├── editar_orden_screen.dart   # Editar orden existente
│   ├── detalle_orden_screen.dart  # Vista de detalle
│   ├── clientes_screen.dart       # Lista + busqueda de clientes
│   ├── form_cliente_screen.dart   # Crear / editar cliente
│   ├── catalogo_screen.dart       # Tabs: Servicios | Refacciones
│   ├── form_servicio_screen.dart  # Crear / editar servicio
│   ├── form_refaccion_screen.dart # Crear / editar refaccion
│   └── estadisticas_screen.dart   # KPIs y desglose mensual
├── widgets/
│   ├── filtro_header.dart         # SliverPersistentHeader con FilterChips
│   ├── status_badge.dart
│   └── vehiculo_card.dart
├── services/
│   └── notification_service.dart  # Notificaciones locales programadas
└── utils/
    ├── formateadores.dart          # Fmt.fecha / Fmt.mes / Fmt.moneda (es_MX)
    └── constants.dart
```

---

## Base de datos

La base de datos SQLite se crea automaticamente en el primer arranque con datos de ejemplo precargados.

### Tablas

| Tabla | Descripcion |
|---|---|
| `clientes` | Datos personales y del vehiculo |
| `ordenes_servicio` | Cabecera de cada orden (estado, fechas, totales) |
| `detalles_orden` | Lineas de servicios y refacciones por orden |
| `servicios_mano_obra` | Catalogo de servicios con precio y duracion |
| `refacciones` | Inventario de refacciones con stock |
| `categorias_servicio` | Categorias para agrupar servicios |
| `categorias_refaccion` | Categorias para agrupar refacciones |

### Estados de una orden

```
pendiente  ->  en_progreso  ->  completado
                           ->  cancelado
```

---

## Instalacion y ejecucion

### Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.38.0
- Android Studio con Android SDK 36
- Dispositivo fisico o emulador Android (API 21+)

### Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/<tu-usuario>/taller_mecanico.git
cd taller_mecanico

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar en modo debug
flutter run

# 4. Generar APK de release
flutter build apk --release
```

> **Nota:** El proyecto incluye un parche local de `flutter_timezone` en `packages/flutter_timezone/`
> necesario para compatibilidad con Flutter 3.38.x. No requiere configuracion adicional.

---

## Permisos de Android

Declarados en `android/app/src/main/AndroidManifest.xml`:

| Permiso | Motivo |
|---|---|
| `RECEIVE_BOOT_COMPLETED` | Restaurar notificaciones programadas al reiniciar el dispositivo |
| `SCHEDULE_EXACT_ALARM` | Programar recordatorios en hora exacta |
| `POST_NOTIFICATIONS` | Mostrar notificaciones en Android 13+ |

---

## Notas de compatibilidad tecnica

| Componente | Version |
|---|---|
| Android Gradle Plugin (AGP) | 8.7.3 |
| Gradle Wrapper | 8.9 |
| Kotlin | 2.1.21 |
| `compileSdk` | 36 |
| `minSdk` | 21 (Android 5.0 Lollipop) |
| Java / Kotlin JVM target | 17 |
| Core Library Desugaring | `com.android.tools:desugar_jdk_libs:2.0.3` |

---

## Autor

Desarrollado como proyecto de evaluacion para la materia de **Desarrollo de Aplicaciones Moviles**.

---

## Licencia

Este proyecto es de uso academico. No esta disponible para distribucion comercial.
