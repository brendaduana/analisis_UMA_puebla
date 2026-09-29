# Objetivo 2 · Selección de variables bioclimáticas no correlacionadas

Guía para preparar las capas climáticas y elegir un subconjunto de variables no correlacionadas. Se divide en dos partes:

- **1. (QGIS):** descargar, recortar a México y convertir las capas al formato de Maxent.
- **2. (R):** correlación de Spearman y PCA, siguiendo el manual
  *Ejercicios sobre Análisis Estadístico en R* del curso (`scripts/02_variables_correlacion_pca.R`).

**Entrada:** los 5 archivos de presencias del objetivo 1 (`data/processed/*.csv`).
**Salida:** 19 capas `.asc` de México y una lista de variables seleccionadas.

---

## 1 · Preparación de capas en QGIS

### 1.1. Descargar WorldClim

1. [worldclim.org](https://www.worldclim.org) → **Data** → **Historical climate data** (WorldClim 2.1).
2. Fila **bio** (19 variables bioclimáticas) → resolución **2.5 minutes** (~4.5 km, ~600 MB).
   Con buena conexión puede usarse 30 s (~1 km, ~10 GB).
3. Descomprimir en `data/climate/worldclim/`. Se obtienen `wc2.1_2.5m_bio_1.tif` … `bio_19.tif`.

Periodo climático: promedio 1970–2000.

### 1.2. Crear la máscara de México

1. Cargar **World Map** (escribir `world` en el recuadro **Coordenada** y presionar Enter).
2. Herramienta **Seleccionar objetos espaciales** → clic sobre México.
3. Clic derecho en la capa → **Exportar → Guardar objetos seleccionados como…**
   → ESRI Shapefile · `data/climate/mexico.shp` · EPSG:4326.

### 1.3. Recortar las 19 capas a México

1. **Ráster → Extracción → Cortar ráster por capa de máscara**.
2. Clic en **Ejecutar como proceso por lotes** (abajo a la izquierda).
3. Agregar las 19 capas como entrada, `mexico.shp` como máscara y marcar
   **Ajustar la extensión del ráster recortado a la de la capa de máscara**.
4. Salidas: `data/climate/recortes/bio_1.tif` … `bio_19.tif`.

### 1.4. Convertir a formato ASCII (.asc) para Maxent

1. **Ráster → Conversión → Traducir (convertir formato)**, también en **proceso por lotes**.
2. Entrada: los 19 recortes. Salida: `data/climate/asc/bio_1.asc` … `bio_19.asc`.

Maxent exige que todas las capas tengan **la misma extensión, resolución y nombre sin espacios**.
Como todas vienen de la misma fuente y la misma máscara, esto se cumple.

---

## 2 · Correlación y PCA en R

Ejecutar `scripts/02_variables_correlacion_pca.R` desde la carpeta raíz del repositorio.
El script hace lo siguiente:

| Paso | Qué hace | Salida |
|---|---|---|
| 1 | Une las presencias de las 5 especies y extrae el valor de las 19 capas en cada punto | `data/processed/valores_climaticos_puntos.csv` |
| 2 | Escala las variables y calcula la correlación de Spearman | `results/figures/02_heatmap_spearman.png` |
| 3 | Lista los pares con correlación alta (\|ρ\| > 0.8) | `results/tables/02_pares_correlacionados.csv` |
| 4 | PCA: varianza explicada, biplot y cargas | `results/figures/02_pca_*.png`, `results/tables/02_cargas_pca.csv` |
| 5 | Guarda la lista final de variables elegidas | `results/tables/02_variables_seleccionadas.csv` |

Se usan las presencias de **las cinco especies juntas** para que todas compartan el mismo conjunto
de variables; esto es necesario para comparar sus nichos en los objetivos 4 y 5.

### 2.1 Criterios de selección

1. De cada par con **|ρ| > 0.8**, conservar solo una variable.
2. Para decidir cuál, preferir la que tenga **cargas altas en el PCA** (> 0.3 en los primeros
   componentes, como en el manual) y mayor **sentido biológico** para mamíferos de zona semiárida
   (p. ej. estacionalidad, extremos de temperatura, precipitación en la temporada seca).
3. Buscar un conjunto final que combine variables de **temperatura** y de **precipitación**.
4. Opcional: excluir BIO8, BIO9, BIO18 y BIO19, que combinan temperatura y precipitación por
   trimestres y pueden mostrar discontinuidades espaciales artificiales.

La selección final es una decisión documentada: se escribe a mano en el paso 5 del script.

### 2.2 Variables bioclimáticas

| Variable | Descripción | Tipo |
|---|---|---|
| BIO1 | Temperatura media anual | T |
| BIO2 | Rango medio diurno de temperatura | T |
| BIO3 | Isotermalidad (BIO2/BIO7 × 100) | T |
| BIO4 | Estacionalidad de la temperatura | T |
| BIO5 | Temperatura máxima del mes más cálido | T |
| BIO6 | Temperatura mínima del mes más frío | T |
| BIO7 | Rango anual de temperatura (BIO5 − BIO6) | T |
| BIO8 | Temperatura media del trimestre más húmedo | T/P |
| BIO9 | Temperatura media del trimestre más seco | T/P |
| BIO10 | Temperatura media del trimestre más cálido | T |
| BIO11 | Temperatura media del trimestre más frío | T |
| BIO12 | Precipitación anual | P |
| BIO13 | Precipitación del mes más húmedo | P |
| BIO14 | Precipitación del mes más seco | P |
| BIO15 | Estacionalidad de la precipitación | P |
| BIO16 | Precipitación del trimestre más húmedo | P |
| BIO17 | Precipitación del trimestre más seco | P |
| BIO18 | Precipitación del trimestre más cálido | P/T |
| BIO19 | Precipitación del trimestre más frío | P/T |

### 2.3 Registro de resultados

| Variables iniciales | Pares con \|ρ\| > 0.8 | Variables seleccionadas | Varianza explicada por PC1 + PC2 |
|---|---|---|---|
| 19 | | | |

---

## 2.4 Estructura resultante

```
data/climate/
├── worldclim/        # 19 .tif originales (no se suben a GitHub por su tamaño)
├── mexico.shp        # máscara de México
├── recortes/         # 19 .tif recortados
└── asc/              # 19 .asc para Maxent
data/processed/
└── valores_climaticos_puntos.csv
results/
├── figures/02_*.png
└── tables/02_*.csv
```

## Notas de limitaciones

- La correlación se calcula sobre los puntos de presencia, no sobre todo el territorio; refleja
  las condiciones donde se registraron las especies.
- La resolución de 2.5 min (~4.5 km) es más gruesa que la UMA; es adecuada para describir el nicho
  a escala nacional, no para variaciones dentro de la UMA.
