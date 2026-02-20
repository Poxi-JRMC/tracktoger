# Tracktoger - Sistema de Gestión de Maquinaria Industrial

## Descripción

Tracktoger es una aplicación Flutter para la gestión integral de maquinaria industrial, incluyendo inventario, alquileres, mantenimiento predictivo y reportes.

## Características Principales

### 🏗️ Gestión de Maquinaria
- Registro y actualización de equipos industriales
- Categorización por tipos de maquinaria
- Control de estado (disponible, alquilado, mantenimiento, fuera de servicio)
- Seguimiento de horas de uso y mantenimiento

### 👥 Gestión de Usuarios
- Sistema de usuarios con roles y permisos
- Registro y autenticación de usuarios
- Gestión de perfiles y configuraciones

### 📋 Gestión de Contratos
- Creación y modificación de contratos de alquiler
- Gestión de clientes
- Control de pagos y facturación
- Seguimiento de entregas y devoluciones

### 🔧 Mantenimiento Predictivo
- Análisis de maquinaria (vibración, temperatura, presión)
- Sistema de alertas automáticas
- Órdenes de trabajo
- Historial de mantenimiento

### 📊 Reportes e Indicadores
- KPIs en tiempo real
- Reportes personalizables
- Indicadores de disponibilidad, rentabilidad y eficiencia
- Exportación en múltiples formatos

## Estructura del Proyecto

```
lib/
├── models/                 # Modelos de datos
│   ├── usuario.dart
│   ├── rol.dart
│   ├── permiso.dart
│   ├── maquinaria.dart
│   ├── categoria.dart
│   ├── historial_uso.dart
│   ├── cliente.dart
│   ├── contrato.dart
│   ├── pago.dart
│   ├── entrega.dart
│   ├── devolucion.dart
│   ├── analisis.dart
│   ├── alerta.dart
│   ├── orden_trabajo.dart
│   ├── reporte.dart
│   └── indicador.dart
├── controllers/            # Controladores de lógica de negocio
│   ├── control_usuario.dart
│   ├── control_maquinaria.dart
│   ├── control_alquileres.dart
│   ├── control_mantenimiento.dart
│   └── control_reportes.dart
├── ui/
│   ├── screens/           # Pantallas de la aplicación
│   │   ├── auth/         # Autenticación
│   │   ├── home/         # Pantalla principal
│   │   ├── dashboard/    # Dashboard y métricas
│   │   ├── usuarios/     # Gestión de usuarios
│   │   ├── maquinaria/   # Gestión de maquinaria
│   │   ├── contratos/    # Gestión de contratos
│   │   ├── mantenimiento/# Mantenimiento predictivo
│   │   └── reportes/     # Reportes e indicadores
│   └── widgets/          # Widgets reutilizables
├── core/                 # Configuración central
│   ├── app_theme.dart
│   ├── app_routes.dart
│   └── constants.dart
└── main.dart
```

## Tecnologías Utilizadas

- **Flutter**: Framework de desarrollo móvil
- **Dart**: Lenguaje de programación
- **Material Design**: Sistema de diseño
- **fl_chart**: Librería para gráficos y visualizaciones

## Instalación y Configuración

### Prerrequisitos
- Flutter SDK (versión 3.8.1 o superior)
- Dart SDK
- Android Studio / VS Code
- Git
- Node.js 18+ (para el backend API)

### Modo API (recomendado)

Para evitar problemas de conexión con MongoDB Atlas desde la app móvil:

1. **Iniciar el backend**
   ```bash
   cd backend
   npm install
   # Crear backend/.env con MONGO_URI (ver backend/README.md)
   npm start
   ```

2. **Configurar la app**
   En el `.env` de la raíz, añadir:
   ```
   API_BASE_URL=http://10.0.2.2:3000
   ```
   (Emulador Android: 10.0.2.2. Dispositivo físico: IP de tu PC)

3. **Ejecutar la app**
   ```bash
   flutter pub get
   flutter run
   ```

### Modo MongoDB directo (alternativo)

1. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

2. **Configurar `.env`** con `MONGO_DB_URL` (sin `API_BASE_URL`)

3. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## Funcionalidades por Módulo

### 🏠 Pantalla Principal
- Vista general del sistema
- Acceso rápido a todos los módulos
- Métricas principales en tiempo real
- Navegación intuitiva

### 👤 Gestión de Usuarios
- **Lista de Usuarios**: Visualización de todos los usuarios registrados
- **Registro de Usuario**: Formulario completo para nuevos usuarios
- **Gestión de Roles**: Administración de roles y permisos
- **Perfil de Usuario**: Edición de información personal

### 🏗️ Gestión de Maquinaria
- **Inventario**: Lista completa de maquinaria con filtros
- **Registro**: Formulario para nueva maquinaria
- **Estadísticas**: Métricas de disponibilidad y uso
- **Categorías**: Gestión de tipos de equipos

### 📋 Gestión de Contratos
- **Contratos**: Lista de contratos activos y finalizados
- **Nuevo Contrato**: Creación de contratos de alquiler
- **Pagos**: Gestión de pagos y facturación
- **Estadísticas**: Métricas de rentabilidad

### 🔧 Mantenimiento Predictivo
- **Análisis**: Historial de análisis técnicos
- **Alertas**: Sistema de notificaciones automáticas
- **Órdenes de Trabajo**: Gestión de tareas de mantenimiento
- **Filtros**: Por prioridad y estado

### 📊 Reportes e Indicadores
- **Indicadores**: KPIs en tiempo real
- **Reportes**: Generación de reportes personalizados
- **Generar**: Formulario para nuevos reportes
- **Exportación**: Múltiples formatos (PDF, Excel, CSV)

## Características Técnicas

### Arquitectura
- **Patrón MVC**: Separación clara de responsabilidades
- **Controladores**: Lógica de negocio centralizada
- **Modelos**: Estructura de datos consistente
- **Vistas**: Interfaz de usuario reactiva

### Almacenamiento
- **Datos en Memoria**: Para desarrollo y pruebas
- **Preparado para BD**: Estructura lista para SQLite o API REST
- **Serialización**: Métodos toMap/fromMap en todos los modelos

### Navegación
- **Bottom Navigation**: Acceso rápido a módulos principales
- **Tab Navigation**: Organización interna de cada módulo
- **Routing**: Sistema de rutas centralizado

## Datos de Prueba

El sistema incluye datos de prueba preconfigurados:

- **Usuarios**: Administrador por defecto
- **Roles**: Administrador y Operador
- **Permisos**: Sistema completo de permisos
- **Maquinaria**: Equipos de ejemplo
- **Categorías**: Tipos de maquinaria industrial
- **Contratos**: Contratos de ejemplo
- **Clientes**: Clientes de prueba
- **Análisis**: Datos de mantenimiento predictivo
- **Alertas**: Notificaciones de ejemplo
- **Indicadores**: KPIs con valores realistas

## Personalización

### Temas
- **Tema Oscuro**: Activado por defecto
- **Colores Industriales**: Paleta amarillo/negro
- **Material Design**: Componentes consistentes

### Configuración
- **Rutas**: Centralizadas en `app_routes.dart`
- **Temas**: Configuración en `app_theme.dart`
- **Constantes**: Valores globales en `constants.dart`

## Próximas Funcionalidades

- [ ] Integración con base de datos SQLite
- [ ] API REST para sincronización
- [ ] Notificaciones push
- [ ] Modo offline
- [ ] Exportación de datos
- [ ] Dashboard personalizable
- [ ] Sistema de backup
- [ ] Multi-idioma

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## Contacto

Para preguntas o sugerencias, contacta al equipo de desarrollo.

---

**Tracktoger** - Gestión Industrial Inteligente 🏗️