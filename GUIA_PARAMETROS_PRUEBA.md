# 📋 Guía de Parámetros para Pruebas

Esta guía te ayudará a probar diferentes estados de la máquina (ÓPTIMO, ADVERTENCIA, CRÍTICO) registrando parámetros específicos.

## 🎯 Cómo Funciona

El sistema evalúa cada parámetro comparándolo con su **límite**:
- **NORMAL**: Valor ≤ límite
- **ADVERTENCIA**: Valor > límite pero ≤ límite × 1.2
- **CRÍTICO**: Valor > límite × 1.2

## ✅ Estado ÓPTIMO (Todos los parámetros normales)

Para obtener un estado **ÓPTIMO**, registra valores **por debajo del límite**:

### Sistema Motor
- **Temperatura del Motor**: `85°C` (límite: 90°C) ✅
- **Presión de Aceite**: `35 PSI` (límite: 40 PSI) ✅
- **Nivel de Aceite**: `95%` (límite: 100%) ✅
- **Consumo de Combustible**: `20 L/h` (límite: 25 L/h) ✅

### Sistema Hidráulico
- **Presión Hidráulica**: `2800 PSI` (límite: 3000 PSI) ✅
- **Nivel de Fluido**: `75%` (límite: 80%) ✅
- **Temperatura del Fluido**: `65°C` (límite: 70°C) ✅
- **Fugas Detectadas**: `0` (límite: 0) ✅

### Sistema de Transmisión
- **Temperatura de Transmisión**: `90°C` (límite: 100°C) ✅
- **Nivel de Aceite de Transmisión**: `75%` (límite: 80%) ✅
- **Ruidos Anormales**: `1` (límite: 3) ✅

### Sistema de Frenos
- **Presión de Frenos**: `1100 PSI` (límite: 1200 PSI) ✅
- **Desgaste de Pastillas**: `25%` (límite: 30%) ✅
- **Temperatura de Discos**: `180°C` (límite: 200°C) ✅

### Sistema de Refrigeración
- **Temperatura del Refrigerante**: `88°C` (límite: 95°C) ✅
- **Nivel de Refrigerante**: `75%` (límite: 80%) ✅
- **Presión del Sistema**: `12 PSI` (límite: 15 PSI) ✅

### Filtros
- **Estado Filtro de Aire**: `45%` (límite: 50%) ✅
- **Estado Filtro de Combustible**: `45%` (límite: 50%) ✅
- **Estado Filtro de Aceite**: `45%` (límite: 50%) ✅

### Estructura y Chasis
- **Grietas Detectadas**: `0` (límite: 0) ✅
- **Corrosión**: `5%` (límite: 10%) ✅
- **Estado de Soldaduras**: `6` (límite: 7) ✅

---

## ⚠️ Estado ADVERTENCIA (Algunos parámetros sobre el límite)

Para obtener un estado **ADVERTENCIA**, registra valores **entre el límite y límite × 1.2**:

### Sistema Motor
- **Temperatura del Motor**: `100°C` (límite: 90°C, 1.2× = 108°C) ⚠️
- **Presión de Aceite**: `35 PSI` (límite: 40 PSI) ✅
- **Nivel de Aceite**: `75%` (límite: 100%) ✅
- **Consumo de Combustible**: `28 L/h` (límite: 25 L/h, 1.2× = 30 L/h) ⚠️

### Sistema Hidráulico
- **Presión Hidráulica**: `3200 PSI` (límite: 3000 PSI, 1.2× = 3600 PSI) ⚠️
- **Nivel de Fluido**: `70%` (límite: 80%) ✅
- **Temperatura del Fluido**: `75°C` (límite: 70°C, 1.2× = 84°C) ⚠️
- **Fugas Detectadas**: `1` (límite: 0) ⚠️

### Sistema de Frenos
- **Presión de Frenos**: `1100 PSI` (límite: 1200 PSI) ✅
- **Desgaste de Pastillas**: `35%` (límite: 30%, 1.2× = 36%) ⚠️
- **Temperatura de Discos**: `220°C` (límite: 200°C, 1.2× = 240°C) ⚠️

---

## 🔴 Estado CRÍTICO (Parámetros muy altos)

Para obtener un estado **CRÍTICO**, registra valores **superiores a límite × 1.2**:

### Sistema Motor
- **Temperatura del Motor**: `115°C` (límite: 90°C, 1.2× = 108°C) 🔴
- **Presión de Aceite**: `25 PSI` (límite: 40 PSI) ✅ (bajo, pero no crítico)
- **Nivel de Aceite**: `50%` (límite: 100%) ✅
- **Consumo de Combustible**: `35 L/h` (límite: 25 L/h, 1.2× = 30 L/h) 🔴

### Sistema Hidráulico
- **Presión Hidráulica**: `3800 PSI` (límite: 3000 PSI, 1.2× = 3600 PSI) 🔴
- **Nivel de Fluido**: `50%` (límite: 80%) ✅
- **Temperatura del Fluido**: `90°C` (límite: 70°C, 1.2× = 84°C) 🔴
- **Fugas Detectadas**: `3` (límite: 0) 🔴

### Sistema de Frenos
- **Presión de Frenos**: `1000 PSI` (límite: 1200 PSI) ✅
- **Desgaste de Pastillas**: `40%` (límite: 30%, 1.2× = 36%) 🔴
- **Temperatura de Discos**: `250°C` (límite: 200°C, 1.2× = 240°C) 🔴

### Sistema de Refrigeración
- **Temperatura del Refrigerante**: `110°C` (límite: 95°C, 1.2× = 114°C) 🔴
- **Nivel de Refrigerante**: `60%` (límite: 80%) ✅
- **Presión del Sistema**: `18 PSI` (límite: 15 PSI, 1.2× = 18 PSI) ⚠️

---

## 🔧 Ejemplo: Probar Frenos en Estado ÓPTIMO

Si quieres que los **frenos** aparezcan en estado **ÓPTIMO** (0% de riesgo):

1. Ve a **"Registrar Parámetros"**
2. Expande **"Sistema de Frenos"**
3. Ingresa:
   - **Presión de Frenos**: `1100` (por debajo de 1200)
   - **Desgaste de Pastillas**: `25` (por debajo de 30)
   - **Temperatura de Discos**: `180` (por debajo de 200)
4. Guarda los parámetros
5. El diagnóstico se actualizará automáticamente
6. Los frenos deberían mostrar **0% de riesgo** o no aparecer en el diagnóstico

---

## 📊 Notas Importantes

1. **Prioridad de Análisis Recientes**: El sistema prioriza análisis de los **últimos 7 días**. Si registras nuevos parámetros normales, estos **sobrescriben** los análisis antiguos críticos.

2. **Actualización Automática**: Después de registrar parámetros, el diagnóstico se actualiza automáticamente. Si no se actualiza, presiona el botón **"Análisis"** para ver el diagnóstico completo.

3. **Sincronización ML**: El ML (Machine Learning) usa los mismos valores de parámetros que el diagnóstico, por lo que ambos deberían estar sincronizados.

4. **Valores por Sistema**: Cada sistema se evalúa independientemente. Puedes tener un sistema crítico y otros normales.

---

## 🎯 Resumen Rápido

| Estado | Condición | Ejemplo (Temperatura Motor) |
|--------|-----------|------------------------------|
| ✅ **ÓPTIMO** | Valor ≤ límite | `85°C` (límite: 90°C) |
| ⚠️ **ADVERTENCIA** | Límite < Valor ≤ límite × 1.2 | `100°C` (límite: 90°C, 1.2× = 108°C) |
| 🔴 **CRÍTICO** | Valor > límite × 1.2 | `115°C` (límite: 90°C, 1.2× = 108°C) |

---

## 💡 Consejos

- **Para limpiar datos antiguos**: Registra nuevos parámetros normales para todos los sistemas. Los análisis recientes (últimos 7 días) tienen prioridad.
- **Para probar un sistema específico**: Solo registra parámetros de ese sistema y deja los demás vacíos o normales.
- **Para ver el diagnóstico completo**: Usa el botón **"Análisis"** que muestra todos los sistemas evaluados.

