# Análisis y Mejoras para el Dataset de Mantenimiento Predictivo

## ✅ Estado Actual - CORRECTO

Tu dataset tiene **15 características** que coinciden perfectamente con el código Flutter:
- ✅ Nombres de columnas en formato `snake_case` (correcto)
- ✅ Todas las columnas requeridas están presentes
- ✅ La columna `falla` está incluida para entrenamiento
- ✅ Rangos de valores realistas

## 🎯 Mejoras Recomendadas

### 1. **Agregar Correlaciones Realistas** ⭐ (IMPORTANTE)

**Problema actual:** Los datos son completamente aleatorios, pero en la realidad hay correlaciones.

**Mejora sugerida:**
```python
# Agregar correlaciones realistas
# Más horas de uso → más temperatura
temp_refrigerante_motor = 70 + (horas_uso_total / 12000) * 30 + rng.normal(0, 5, n)
temp_aceite_motor = 70 + (horas_uso_total / 12000) * 40 + rng.normal(0, 5, n)

# Más horas desde último mantenimiento → presión más baja
presion_aceite_motor = 6.0 - (horas_desde_ultimo_mantenimiento / 1000) * 2.0 + rng.normal(0, 0.5, n)
presion_aceite_motor = presion_aceite_motor.clip(0.5, 6.0)

# Más horas → niveles de aceite más bajos
nivel_aceite_motor = 1.0 - (horas_desde_ultimo_mantenimiento / 2000).clip(0, 0.5) + rng.normal(0, 0.1, n)
nivel_aceite_motor = nivel_aceite_motor.clip(0.0, 1.0)

# Más horas → filtros más sucios (mayor diferencial de presión)
diferencial_presion_filtro_aceite = (horas_desde_ultimo_mantenimiento / 1000) * 50 + rng.uniform(0, 50, n)
diferencial_presion_filtro_aceite = diferencial_presion_filtro_aceite.clip(0, 200)
```

### 2. **Agregar Variables Adicionales** (Opcional pero recomendado)

```python
# 16) Vibración del motor (mm/s, 0 a 20)
vibracion_motor = rng.uniform(0, 20, n)
# Más horas → más vibración
vibracion_motor = (horas_uso_total / 12000) * 15 + rng.normal(0, 2, n)
vibracion_motor = vibracion_motor.clip(0, 20)

# 17) Consumo de combustible (L/h, 5 a 50)
consumo_combustible = rng.uniform(5, 50, n)
# Más desgaste → más consumo
consumo_combustible = 10 + (horas_uso_total / 12000) * 30 + rng.normal(0, 5, n)
consumo_combustible = consumo_combustible.clip(5, 50)

# 18) Estado del filtro de aire (0.0 a 1.0, 1.0 = nuevo)
estado_filtro_aire = rng.uniform(0.0, 1.0, n)
# Más horas → filtro más sucio
estado_filtro_aire = 1.0 - (horas_desde_ultimo_mantenimiento / 2000).clip(0, 0.8) + rng.normal(0, 0.1, n)
estado_filtro_aire = estado_filtro_aire.clip(0.0, 1.0)

# 19) Temperatura ambiente (°C, 10 a 45)
temp_ambiente = rng.uniform(10, 45, n)
# Afecta las temperaturas del motor
temp_refrigerante_motor += (temp_ambiente - 25) * 0.3

# 20) Tipo de trabajo (0 = ligero, 1 = medio, 2 = pesado)
tipo_trabajo = rng.integers(0, 3, n)
# Trabajo pesado → más desgaste
factor_desgaste = 1.0 + tipo_trabajo * 0.3
```

### 3. **Mejorar el Score de Riesgo con Interacciones**

```python
# Agregar interacciones entre variables
score_riesgo = (
    # Factores base (tu código actual)
    (horas_uso_total / 12000) * 2.0 +
    (horas_desde_ultimo_mantenimiento / 1000) * 2.0 +
    # ... resto de tu código ...
    
    # NUEVAS INTERACCIONES:
    # Alta temperatura + baja presión = MUY PELIGROSO
    ((temp_aceite_motor > 100) & (presion_aceite_motor < 2.0)).astype(float) * 3.0 +
    
    # Bajo nivel de aceite + alta temperatura = CRÍTICO
    ((nivel_aceite_motor < 0.3) & (temp_aceite_motor > 110)).astype(float) * 4.0 +
    
    # Muchas horas + muchas alertas = RIESGO ALTO
    ((horas_uso_total > 8000) & (alertas_criticas_30d > 5)).astype(float) * 2.0 +
    
    # Filtros sucios + alta presión hidráulica = PROBLEMA
    ((diferencial_presion_filtro_hidraulico > 150) & (presion_linea_hidraulica > 350)).astype(float) * 1.5
)
```

### 4. **Agregar Patrones Temporales** (Simular desgaste progresivo)

```python
# Simular que las máquinas con más horas tienen más problemas
# Agregar un factor de "edad" que afecte múltiples variables
factor_edad = horas_uso_total / 12000

# Temperaturas aumentan con la edad
temp_refrigerante_motor += factor_edad * 10
temp_aceite_motor += factor_edad * 15

# Presiones disminuyen con la edad
presion_aceite_motor -= factor_edad * 1.5
presion_aceite_motor = presion_aceite_motor.clip(0.5, 6.0)

# Niveles de aceite disminuyen
nivel_aceite_motor -= factor_edad * 0.2
nivel_aceite_motor = nivel_aceite_motor.clip(0.0, 1.0)
```

### 5. **Mejorar la Distribución de Fallas**

```python
# En lugar de un umbral fijo, usar una función más realista
# Máquinas con score_riesgo > 8 tienen 80% probabilidad de falla
# Máquinas con score_riesgo < 3 tienen 5% probabilidad de falla

probabilidad_falla = np.clip(
    (score_riesgo - 3) / 5.0,  # Normalizar entre 0 y 1
    0.05,  # Mínimo 5%
    0.95   # Máximo 95%
)

# Agregar ruido aleatorio
falla = (rng.random(n) < probabilidad_falla).astype(int)
```

### 6. **Agregar Valores Faltantes (Opcional para robustez)**

```python
# Simular que algunos sensores fallan ocasionalmente (5% de los datos)
indices_faltantes = rng.choice(n, size=int(n * 0.05), replace=False)
temp_refrigerante_motor[indices_faltantes] = np.nan
# El modelo debe manejar NaN o valores por defecto
```

## 📊 Código Mejorado Completo

```python
import numpy as np
import pandas as pd

# cantidad de muestras sinteticas
n = 5000
rng = np.random.default_rng(42)

# 1) horas de uso total (0 a 12000 h)
horas_uso_total = rng.uniform(0, 12000, n)

# 2) horas desde ultimo mantenimiento (0 a 1000 h)
horas_desde_ultimo_mantenimiento = rng.uniform(0, 1000, n)

# 3) temperatura refrigerante motor (°C, 70 a 120)
# MEJORADO: Correlación con horas de uso
temp_refrigerante_motor = 70 + (horas_uso_total / 12000) * 30 + rng.normal(0, 5, n)
temp_refrigerante_motor = temp_refrigerante_motor.clip(70, 120)

# 4) temperatura aceite motor (°C, 70 a 130)
# MEJORADO: Correlación con horas de uso y mantenimiento
temp_aceite_motor = 70 + (horas_uso_total / 12000) * 40 + (horas_desde_ultimo_mantenimiento / 1000) * 10 + rng.normal(0, 5, n)
temp_aceite_motor = temp_aceite_motor.clip(70, 130)

# 5) presion aceite motor (bar, 0.5 a 6.0)
# MEJORADO: Disminuye con horas desde último mantenimiento
presion_aceite_motor = 6.0 - (horas_desde_ultimo_mantenimiento / 1000) * 2.0 + rng.normal(0, 0.5, n)
presion_aceite_motor = presion_aceite_motor.clip(0.5, 6.0)

# 6) temperatura aceite hidraulico (°C, 30 a 90)
temp_aceite_hidraulico = 30 + (horas_uso_total / 12000) * 40 + rng.normal(0, 5, n)
temp_aceite_hidraulico = temp_aceite_hidraulico.clip(30, 90)

# 7) presion linea hidraulica (bar, 100 a 400)
presion_linea_hidraulica = rng.uniform(100, 400, n)

# 8) nivel aceite motor (0.0 vacio, 1.0 lleno)
# MEJORADO: Disminuye con horas desde último mantenimiento
nivel_aceite_motor = 1.0 - (horas_desde_ultimo_mantenimiento / 2000).clip(0, 0.5) + rng.normal(0, 0.1, n)
nivel_aceite_motor = nivel_aceite_motor.clip(0.0, 1.0)

# 9) nivel aceite hidraulico (0.0 a 1.0)
nivel_aceite_hidraulico = 1.0 - (horas_desde_ultimo_mantenimiento / 2000).clip(0, 0.5) + rng.normal(0, 0.1, n)
nivel_aceite_hidraulico = nivel_aceite_hidraulico.clip(0.0, 1.0)

# 10) diferencial presion filtro aceite (kPa, 0 a 200)
# MEJORADO: Aumenta con horas desde último mantenimiento
diferencial_presion_filtro_aceite = (horas_desde_ultimo_mantenimiento / 1000) * 50 + rng.uniform(0, 50, n)
diferencial_presion_filtro_aceite = diferencial_presion_filtro_aceite.clip(0, 200)

# 11) diferencial presion filtro hidraulico (kPa, 0 a 200)
diferencial_presion_filtro_hidraulico = (horas_desde_ultimo_mantenimiento / 1000) * 50 + rng.uniform(0, 50, n)
diferencial_presion_filtro_hidraulico = diferencial_presion_filtro_hidraulico.clip(0, 200)

# 12) porcentaje tiempo al ralenti (0 a 1)
porcentaje_tiempo_ralenti = rng.uniform(0.0, 1.0, n)

# 13) promedio horas diarias de uso (0 a 24)
promedio_horas_diarias_uso = rng.uniform(0.0, 24.0, n)

# 14) alertas criticas ultimos 30 dias (0 a 10)
# MEJORADO: Más alertas si hay problemas
alertas_criticas_30d = rng.integers(0, 11, n)
# Aumentar alertas si hay problemas reales
factor_problemas = ((temp_aceite_motor > 110) | (presion_aceite_motor < 2.0)).astype(int)
alertas_criticas_30d = np.minimum(alertas_criticas_30d + factor_problemas * 3, 10)

# 15) alertas medias ultimos 30 dias (0 a 15)
alertas_medias_30d = rng.integers(0, 16, n)

# Score de riesgo MEJORADO con interacciones
score_riesgo = (
    # Factores base
    (horas_uso_total / 12000) * 2.0 +
    (horas_desde_ultimo_mantenimiento / 1000) * 2.0 +
    ((temp_refrigerante_motor - 80) / 40).clip(0, None) * 1.5 +
    ((temp_aceite_motor - 90) / 40).clip(0, None) * 1.5 +
    ((2.0 - presion_aceite_motor).clip(0, None) / 1.5) * 1.5 +
    ((temp_aceite_hidraulico - 60) / 30).clip(0, None) * 1.5 +
    ((presion_linea_hidraulica - 300).clip(0, None) / 100) * 1.0 +
    (1.0 - nivel_aceite_motor) * 1.5 +
    (1.0 - nivel_aceite_hidraulico) * 1.2 +
    (diferencial_presion_filtro_aceite / 200) * 1.0 +
    (diferencial_presion_filtro_hidraulico / 200) * 1.0 +
    (porcentaje_tiempo_ralenti) * 0.5 +
    (promedio_horas_diarias_uso / 24) * 1.0 +
    alertas_criticas_30d * 0.4 +
    alertas_medias_30d * 0.2 +
    # NUEVAS INTERACCIONES
    ((temp_aceite_motor > 100) & (presion_aceite_motor < 2.0)).astype(float) * 3.0 +
    ((nivel_aceite_motor < 0.3) & (temp_aceite_motor > 110)).astype(float) * 4.0 +
    ((horas_uso_total > 8000) & (alertas_criticas_30d > 5)).astype(float) * 2.0
)

# Probabilidad de falla más realista
probabilidad_falla = np.clip((score_riesgo - 3) / 5.0, 0.05, 0.95)
falla = (rng.random(n) < probabilidad_falla).astype(int)

# DataFrame final
df = pd.DataFrame({
    "horas_uso_total": horas_uso_total,
    "horas_desde_ultimo_mantenimiento": horas_desde_ultimo_mantenimiento,
    "temp_refrigerante_motor": temp_refrigerante_motor,
    "temp_aceite_motor": temp_aceite_motor,
    "presion_aceite_motor": presion_aceite_motor,
    "temp_aceite_hidraulico": temp_aceite_hidraulico,
    "presion_linea_hidraulica": presion_linea_hidraulica,
    "nivel_aceite_motor": nivel_aceite_motor,
    "nivel_aceite_hidraulico": nivel_aceite_hidraulico,
    "diferencial_presion_filtro_aceite": diferencial_presion_filtro_aceite,
    "diferencial_presion_filtro_hidraulico": diferencial_presion_filtro_hidraulico,
    "porcentaje_tiempo_ralenti": porcentaje_tiempo_ralenti,
    "promedio_horas_diarias_uso": promedio_horas_diarias_uso,
    "alertas_criticas_30d": alertas_criticas_30d,
    "alertas_medias_30d": alertas_medias_30d,
    "falla": falla
})

# Guardar CSV
df.to_csv('mantenimiento_maquinaria_sintetico.csv', index=False)
print(f"Dataset generado: {len(df)} registros")
print(f"Tasa de fallas: {falla.mean():.2%}")
```

## 🎯 Resumen de Mejoras

1. ✅ **Correlaciones realistas** - Las variables se relacionan entre sí
2. ✅ **Interacciones** - Combinaciones peligrosas aumentan el riesgo
3. ✅ **Distribución de fallas mejorada** - Más realista que umbral fijo
4. ✅ **Patrones de desgaste** - Simula el envejecimiento de las máquinas

## 📝 Notas Importantes

- **Mantén los nombres de columnas** en `snake_case` (ya están correctos)
- **No cambies el orden** de las columnas (el modelo ML lo espera así)
- **La columna `falla`** debe ser la última
- Si agregas nuevas columnas, actualiza el modelo Flutter también

## 🚀 Próximos Pasos

1. Genera el CSV mejorado con el código de arriba
2. Reemplaza el archivo en `assets/datasets/mantenimiento_maquinaria_sintetico.csv`
3. Si agregas nuevas columnas, actualiza `RegistroDatasetMantenimiento` en Flutter
4. Reentrena el modelo ML con el nuevo dataset

