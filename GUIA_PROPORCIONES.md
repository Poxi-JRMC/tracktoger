# 📐 Guía de Proporciones del Dashboard

## Ubicaciones para Modificar Proporciones

### 1. **Tarjetas KPI (GridView)**
**Archivo:** `lib/ui/screens/dashboard/dashboard_screen.dart`  
**Línea:** ~523-528

```dart
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,                    // ← Número de columnas
  mainAxisSpacing: 12,                   // ← Espaciado vertical entre tarjetas
  crossAxisSpacing: 12,                  // ← Espaciado horizontal entre tarjetas
  childAspectRatio: 1.2,                 // ← Proporción ancho/alto (1.2 = más ancho que alto)
),
```

**Ajustes recomendados:**
- `childAspectRatio`: Aumentar (ej: 1.3) = tarjetas más anchas, menos altas
- `childAspectRatio`: Disminuir (ej: 1.1) = tarjetas más altas, menos anchas
- `mainAxisSpacing` / `crossAxisSpacing`: Ajustar espaciado entre tarjetas

### 2. **Padding de Tarjetas KPI**
**Archivo:** `lib/ui/screens/dashboard/dashboard_screen.dart`  
**Línea:** ~540

```dart
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
```

**Ajustes:**
- `horizontal`: Padding izquierdo/derecho (reducir si hay overflow horizontal)
- `vertical`: Padding arriba/abajo (reducir si hay overflow vertical)

### 3. **Tamaños de Fuente en KPIs**
**Archivo:** `lib/ui/screens/dashboard/dashboard_screen.dart`  
**Líneas:** ~563, 572, 586, 598

```dart
fontSize: 22,  // Valor principal
fontSize: 12,  // Título
fontSize: 10,  // Subtítulo
fontSize: 11,  // Cambio/trend
```

### 4. **Tarjetas de Estadísticas de Usuarios**
**Archivo:** `lib/ui/screens/dashboard/dashboard_screen.dart`  
**Línea:** ~763

```dart
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
```

### 5. **Espaciado entre Tarjetas de Usuarios**
**Archivo:** `lib/ui/screens/dashboard/dashboard_screen.dart`  
**Línea:** ~691, 700

```dart
const SizedBox(width: 10),  // Espaciado horizontal entre tarjetas
```

---

## 🔧 Correcciones Aplicadas

✅ **Asignación automática de rol "Operador"** en nuevos registros  
✅ **Eliminación de "Sin rol"** del dashboard  
✅ **Filtrado de roles inválidos** en estadísticas

