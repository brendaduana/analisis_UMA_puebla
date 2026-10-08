# Objetivo 2 - Selección de variables bioclimáticas no correlacionadas

Los modelos de nicho (objetivos 3 a 5) describen el nicho climático de cada especie a partir de variables bioclimáticas. WorldClim ofrece 19, pero muchas miden casi lo mismo: por ejemplo, la temperatura media anual (BIO1) y la temperatura media del trimestre más cálido (BIO10) suelen variar juntas. Si se usan variables muy correlacionadas puede que el modelo le dé el doble peso a una misma dimensión del clima (**multicolinealidad**), los resultados se vuelven difíciles de interpretar, porque no se sabe qué variable explica el patrón además, aumenta el riesgo de sobreajuste.

Este objetivo reduce las 19 variables a un subconjunto pequeño y **no redundante**, que represente las principales dimensiones del clima de México.

```
## Flujo de trabajo

| Paso | Qué se hace | Dónde | Origen en el curso |
|---|---|---|---|
| 0 | Preparar R | R | *Ejercicios sobre Análisis Estadístico en R* (Q) |
| 1 | Descargar WorldClim | Navegador | Práctica de GBIF y Maxent (Q) |
| 2 | Crear la máscara de México | QGIS | Mismo flujo del objetivo 1 |
| 3 | Cargar las capas | R | Práctica 1, *Espacio geográfico y espacio ecológico* (V) |
| 4 | Recortar a México | R | Práctica 1 (V) |
| 5 | Extraer valores y muestrear 10,000 celdas | R | Práctica 1 (V) |
| 6 | Escalar las variables | R | *Ejercicios sobre Análisis Estadístico en R* (Q) |
| 7 | Correlación de Spearman | R | *Ejercicios sobre Análisis Estadístico en R* (Q) |
| 8 | Análisis de Componentes Principales (PCA) | R | *Ejercicios sobre Análisis Estadístico en R* (Q) |
| 9 | Selección final de variables | R | *Ejercicios sobre Análisis Estadístico en R* (Q) |
```

A continuación se explican los pasos necesarios para el cumplimiento del objetivo:

## Paso 0 - Preparar el ambiente de Rstudio

### 0.1 Instalar y cargar paquetes

`require()` revisa si el paquete ya está instalado; si no lo está, `install.packages()` lo instala:

```r
if (!require("terra")) install.packages("terra")            # Capas raster y vectoriales
if (!require("ggplot2")) install.packages("ggplot2")        # Gráficas
if (!require("reshape2")) install.packages("reshape2")      # melt() para el heatmap
if (!require("factoextra")) install.packages("factoextra")  # Visualización del PCA
if (!require("psych")) install.packages("psych")            # Análisis de cargas
```

Después, cargalos en la sesión:

```r
library(terra)
library(ggplot2)
library(reshape2)
library(factoextra)
library(psych)
```

### 0.2 Directorio de trabajo*

Todas las rutas de esta guía son **relativas a la carpeta raíz del repositorio***, hay que indicarle a R que trabaje desde ahí.

```r
getwd()   # muestra en qué carpeta está trabajando R

setwd("C:/analisis_uma/03-analisis-uma-rstudio")   # cambiar por la ruta real; usar / y no \
```

*En RStudio también se puede hacer desde **Session > Set Working Directory > Choose Directory…**

### 0.3 Carpetas de resultados

```r
dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)
```

`recursive = TRUE` crea también `results/` si no existe; `showWarnings = FALSE` evita un aviso si las carpetas ya estaban creadas.

## Paso 1 - Verificar las capas WorldClim

Las 19 capas bioclimáticas de WorldClim 2.1 (2.5 min, promedio 1970–2000) se descargaron en el **objetivo 1, paso 5** ([`01_objetivo.md`](https://github.com/brendaduana/analisis_UMA_puebla/blob/main/01-objetivo.md#5-descarga-de-worldclim)) y están en la carpeta `00-data-worldclim/`. 
 
Antes de continuar, verificar que la carpeta contenga los 19 archivos `.tif` sueltos (`wc2.1_2.5m_bio_1.tif` … `wc2.1_2.5m_bio_19.tif`), sin subcarpetas.

### Variables bioclimáticas

| Variable | Descripción | Tipo |
|---|---|---|
| BIO1 | Temperatura media anual | Temperatura |
| BIO2 | Rango diurno medio | Temperatura |
| BIO3 | Isotermalidad (BIO2/BIO7 × 100) | Temperatura |
| BIO4 | Estacionalidad de la temperatura | Temperatura |
| BIO5 | Temperatura máxima del mes más cálido | Temperatura |
| BIO6 | Temperatura mínima del mes más frío | Temperatura |
| BIO7 | Rango de temperatura anual (BIO5 − BIO6) | Temperatura |
| BIO8 | Temperatura media del trimestre más húmedo | Temperatura |
| BIO9 | Temperatura media del trimestre más seco | Temperatura |
| BIO10 | Temperatura media del trimestre más cálido | Temperatura |
| BIO11 | Temperatura media del trimestre más frío | Temperatura |
| BIO12 | Precipitación anual | Precipitación |
| BIO13 | Precipitación del mes más lluvioso | Precipitación |
| BIO14 | Precipitación del mes más seco | Precipitación |
| BIO15 | Estacionalidad de la precipitación | Precipitación |
| BIO16 | Precipitación del trimestre más húmedo | Precipitación |
| BIO17 | Precipitación del trimestre más seco | Precipitación |
| BIO18 | Precipitación del trimestre más cálido | Precipitación |
| BIO19 | Precipitación del trimestre más frío | Precipitación |

## Paso 2 - Crear la máscara de México (CONABIO)

El análisis se limita a México, igual que los registros de presencia (objetivo 1). Para recortar las capas climáticas se necesita un polígono del país. Se usa la capa oficial **División política estatal 1:1,000,000** del Geoportal de CONABIO (`destdv1gw`).

1. Entrar a la ficha de la capa en el [Geoportal de CONABIO](http://geoportal.conabio.gob.mx/metadatos/doc/html/destdv1gw.html) y descargarla en formato shapefile.
2. Descomprimir y guardar **todos** los archivos en `00-data-map-mex/`, sin cambiarles el nombre.El shapefile necesita estos cuatro juntos para abrir:
   
   | Archivo | Contenido |
   |---|---|
   | `destdv1gw.shp` | Geometría (los polígonos) |
   | `destdv1gw.shx` | Índice de la geometría |
   | `destdv1gw.dbf` | Tabla de atributos (nombre de cada estado) |
   | `destdv1gw.prj` | Sistema de coordenadas |

   También vienen los metadatos (`.html`, `.xml`) y dos imágenes de vista previa (`.png`).
   
## Paso 3 - Cargar las capas en Rstudio

### 3.1 Listar los archivos

`list.files()` busca en la carpeta todos los archivos que terminan en `.tif`.
`full.names = TRUE` devuelve la ruta completa de cada uno, necesaria para leerlos.

```r
bios <- list.files(
  path = "../00-data-worldclim",
  pattern = "\\.tif$",
  full.names = TRUE
)
 
bios
```

**Resultado** 

19 rutas. El orden es alfabético (`bio_1`, `bio_10`, `bio_11`… `bio_2`); no afecta el análisis porque cada capa conserva su nombre.

### 3.2 Leer las capas

`rast()` lee los 19 archivos y los junta en un solo objeto de 19 capas, una por variable.

```r
bios <- rast(bios)

bios
```

**Resultado** 

Un resumen con `dimensions` (`nlyr = 19`), `resolution` (~0.0417 grados = 2.5 min), `extent` (todo el mundo) y `coord. ref.` (WGS 84).

### 3.3 Acortar los nombres

`sub()` reemplaza el texto `wc2.1_2.5m_bio_` por `BIO`, para que en tablas y gráficas se lea `BIO1`, `BIO2`, etc.

```r
names(bios) <- sub("wc2.1_2.5m_bio_", "BIO", names(bios))

names(bios)
```

**Resultado** 

"BIO1"  "BIO10" "BIO11" "BIO12" "BIO13" "BIO14" "BIO15" "BIO16" "BIO17" "BIO18" "BIO19" "BIO2"  "BIO3"  "BIO4"  "BIO5" "BIO6"  "BIO7"  "BIO8"  "BIO9"

## Paso 4 - Recortar a México

Las capas cubren todo el mundo, pero el área de estudio es México. Se recortan en dos pasos, como en la Práctica 1 se recortó por bioma:
 
- `crop()` reduce las capas al **rectángulo** que contiene a México (menos celdas, cálculos más rápidos).
- `mask()` deja **sin valor (NA)** las celdas de ese rectángulo que quedan fuera del polígono (mar, EE. UU., Centroamérica).

```r
mexico <- vect("../00-data-map-mex/destdv1gw.shp")
 
nrow(mexico)   # número de polígonos (un estado por fila)
plot(mexico)   # revisar que se vea la República completa
 
bios_mx <- mask(
  crop(bios, mexico),
  mexico
)
 
plot(bios_mx[["BIO1"]])
plot(mexico, add = TRUE)
```
 
`vect()` lee el shapefile. La capa tiene **un polígono por estado**, por eso `nrow(mexico)` da alrededor de 32 (puede ser algo más si algunas islas vienen como polígonos separados); `plot(mexico)` permite revisar que se vea la República completa. No es necesario unir los estados: `mask()` usa todos los polígonos juntos, así que el recorte equivale al contorno del país.

Las dos últimas líneas grafican la temperatura media anual (BIO1) con la división estatal encima.

**Resultado**

El recorte aísla correctamente el territorio mexicano: no quedan celdas con valor fuera del contorno nacional (mar, EE. UU., Centroamérica), y la división estatal se superpone sin huecos ni bordes irregulares, lo que confirma que `mask()` funcionó bien. Se observa el gradiente esperado de temperatura media anual, con valores más bajos en las zonas montañosas y del norte, y más altos en las costas y depresiones del sur.

## Paso 5 - Extraer valores y muestrear 10,000 celdas

### 5.1 Convertir las capas en tabla

Para calcular correlaciones, R necesita una tabla: una **fila por celda** y una **columna por variable**. `as.data.frame()` hace esa conversión.

- `xy = TRUE` agrega las coordenadas de cada celda (columnas `x` y `y`).
- `na.rm = TRUE` descarta las celdas sin valor (las que quedaron fuera de México).

```r
bios_mx_extract <- as.data.frame(
  bios_mx,
  xy = TRUE,
  na.rm = TRUE
)

dim(bios_mx_extract)
```

**Resultado** 

102, 2316 filas y 21 columnas (`x`, `y` y las 19 variables).

### 5.2 Tomar una muestra aleatoria

Trabajar con todas las celdas hace lento el análisis sin cambiar el resultado. Se toma una muestra aleatoria de **10,000 celdas** con la función `sample_df()` de la Práctica 1: si la tabla tiene menos de 10,000 filas la deja igual; si tiene más, elige 10,000 al azar.

`set.seed(123)` fija el punto de partida del generador aleatorio, para que la muestra sea **siempre la misma** cada vez que se corre el código (reproducibilidad).

```r
set.seed(123)

sample_df <- function(x, n = 10000) {
  if (nrow(x) <= n) {
    return(x)
  }
  x[sample(nrow(x), n), ]
}

clima <- sample_df(bios_mx_extract)

dim(clima)
```

**Resultado** 

10000 21

> **¿Por qué celdas de todo México y no los puntos de las especies?** La correlación entrevariables describe cómo se relacionan en el territorio de estudio.
> Usar el mismo conjunto de celdas para todas garantiza que las cinco especies compartan las mismas variables, requisito para comparar sus nichos en los
> objetivos 4 y 5.

## Paso 6 - Seleccionar y escalar las variables

Primero se separan las 19 variables bioclimáticas de las coordenadas (`x`, `y`), que no son variables ambientales. Se seleccionan **por nombre** y no por posición, para evitar incluir una columna equivocada.

Después, `scale()` transforma cada variable a **valores Z** (media 0 y desviación estándar 1). Es necesario porque las variables tienen unidades y rangos muy distintos: la temperatura está en °C (decenas) y la precipitación en mm (cientos o miles). Sin escalar, las variables con números más grandes dominarían el PCA.

```r
clima_variables <- clima[, names(bios)]

clima_variables <- scale(clima_variables)
```

## Paso 7 - Correlación de Spearman

### 7.1 Matriz de correlación

La correlación de **Spearman** se basa en rangos: mide si dos variables aumentan o disminuyen juntas, **sin asumir una relación lineal ni normalidad** en los datos. Va de −1 (relación inversa perfecta) a 1 (relación directa perfecta); 0 indica que no hay relación.

```r
cor_clima <- cor(clima_variables, method = "spearman")

cor_clima_2dec <- round(cor_clima, 2)

write.csv(cor_clima_2dec, "results/tables/02_matriz_spearman.csv")
```

`round(..., 2)` redondea a dos decimales para facilitar la lectura. La matriz se guarda como tabla completa en `results/tables/02_matriz_spearman.csv` (19×19); aquí se documentan los bloques más relevantes identificados en ella.

### 7.2 Preparar la matriz para el heatmap

La matriz es **simétrica** (la correlación BIO1–BIO12 es igual a BIO12–BIO1), así que basta con graficar la mitad. `get_upper_tri()` convierte en `NA` el triángulo inferior.

```r
get_upper_tri <- function(cor_clima_2dec) {
  cor_clima_2dec[lower.tri(cor_clima_2dec)] <- NA
  return(cor_clima_2dec)
}
```

`reorder_cor_clima()` reordena las variables con un **agrupamiento jerárquico** (`hclust()`), para que en el heatmap aparezcan juntas las variables relacionadas y se vean como **bloques**, en lugar del orden arbitrario original.

`hclust()` necesita distancias, no correlaciones. La transformación `(1 − correlación) / 2` convierte una correlación de 1 en distancia 0 (variables "iguales"), una de 0 en distancia 0.5 y una de −1 en distancia 1 (máxima distancia).

```r
reorder_cor_clima <- function(cor_clima_2dec) {
  dd <- as.dist((1 - cor_clima_2dec) / 2)
  hc <- hclust(dd)
  cor_clima_2dec <- cor_clima_2dec[hc$order, hc$order]
  return(cor_clima_2dec)
}

cor_clima_2dec <- reorder_cor_clima(cor_clima_2dec)

upper_tri <- get_upper_tri(cor_clima_2dec)
```

### 7.3 Graficar el heatmap

`melt()` convierte la matriz en una tabla larga (una fila por par de variables), el formato que necesita `ggplot()`. `na.rm = TRUE` elimina las celdas vacías del triángulo inferior.

```r
melted_tri_cor_clima <- melt(upper_tri, na.rm = TRUE)

ggheatmap <- ggplot(data = melted_tri_cor_clima, aes(Var2, Var1, fill = value)) +
  geom_tile(color = "#f7f7f7") +
  scale_fill_gradient2(low = "#6baed6", mid = "white", high = "#084594",
                       midpoint = 0, limits = c(-1, 1),
                       space = "Lab",
                       name = "Spearman\nCorrelation") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, vjust = 1, size = 10, hjust = 1)) +
  coord_fixed()

print(ggheatmap)

ggsave("results/figures/02_heatmap_spearman.png", plot = ggheatmap,
       width = 8, height = 6, dpi = 300)
```

**Resultado**

El heatmap agrupa visualmente las variables en tres bloques amplios (temperatura, precipitación y rango/estacionalidad térmica), pero revisar la matriz numérica (`02_matriz_spearman.csv`) muestra que dos de esos bloques tienen estructura interna que el heatmap no distingue a simple vista:

| Bloque | Variables | Dimensión climática | Correlación interna |
|---|---|---|---|
| 1a | BIO1, BIO6, BIO9, BIO11 | Temperatura — frío / media anual | 0.83–0.98 |
| 1b | BIO5, BIO8, BIO10 | Temperatura — calor | 0.83–0.93 |
| 2a | BIO12, BIO13, BIO16, BIO18 | Precipitación — temporada húmeda | 0.88–0.99 |
| 2b | BIO14, BIO17 | Precipitación — temporada seca | 0.97 |
| 3 | BIO4, BIO7 | Rango / estacionalidad térmica | 0.91 |

BIO2, BIO3, BIO15 y BIO19 no se agrupan con fuerza (|ρ| < 0.8) dentro de ningún bloque.

Un dato clave para el Paso 9: aunque el heatmap agrupa visualmente 1a y 1b como un solo bloque de "temperatura", **BIO5 (1b) y BIO6 (1a) solo correlacionan 0.29 entre sí** — no son redundantes. Lo mismo ocurre entre 2a y 2b: **BIO12 (2a) y BIO17 (2b) correlacionan 0.57**, por debajo del umbral de 0.8. Esto es lo que permite seleccionar más adelante una variable de cada sub-bloque sin violar el criterio de redundancia.

**Cómo leerlo:** los cuadros azul oscuro indican correlación positiva fuerte y los azul claro, negativa; los blancos, sin relación. Los **bloques oscuros** son grupos de variables redundantes.

**Salidas:** `results/figures/02_heatmap_spearman.png` y `results/tables/02_matriz_spearman.csv`.

**Decisión**

El heatmap no elige variables por sí solo; identifica **qué variables son redundantes entre sí**, y la matriz numérica afina esa identificación a nivel de sub-bloque. Esta información se usa en el Paso 9 para elegir una variable por cada sub-bloque no redundante, apoyándose en las cargas del PCA (Paso 8) para decidir cuál dentro de cada uno.

## Paso 8 - Análisis de Componentes Principales (PCA)

El PCA transforma las 19 variables correlacionadas en nuevas variables **independientes** entre sí, llamadas componentes principales (PC1, PC2…). PC1 resume la mayor parte de la variación del clima, PC2 la siguiente mayor parte, y así sucesivamente. Sirve para ver qué variables comparten información y cuáles aportan algo distinto.

### 8.1 Calcular el PCA

- `center = TRUE` resta la media de cada variable, para que todas queden centradas en 0.
- `scale. = TRUE` divide entre la desviación estándar, para que todas tengan varianza 1.

```r
pca_result <- prcomp(clima_variables, center = TRUE, scale. = TRUE)

summary(pca_result)

eig <- get_eigenvalue(pca_result)

round(eig, 2)
```

**Resultado** 

Una tabla con el eigenvalor, la proporción de varianza y la proporción acumulada de cada componente.

| Componente | PC1 | PC2 | PC3 | PC4 | PC5 |
|---|---|---|---|---|---|
| Eigenvalor | 8.88 | 4.39 | 2.66 | 1.52 | 0.59 |
| Proporción de varianza | 46.71% | 23.08% | 14.01% | 8.02% | 3.09% |
| Proporción acumulada | 46.71% | 69.80% | 83.80% | 91.82% | 94.91% |

**Decisión**

- PC1 + PC2 explican **69.80%** de la varianza.
- Aplicando el criterio de Kaiser (eigenvalor > 1): PC1, PC2, PC3 y PC4 lo cumplen; PC5 (0.59) ya no.
- **Se interpretan los primeros 4 componentes (91.82% de la varianza acumulada).**

### 8.2 Scree plot

Muestra el **porcentaje de varianza** explicado por cada componente. Ayuda a decidir cuántos componentes vale la pena interpretar: normalmente los que están antes de que la curva se aplane. 

```r
screen_plot <- fviz_eig(pca_result, addlabels = TRUE, ylim = c(0, 50))

print(screen_plot)

ggsave("results/figures/02_screen_plot.png", plot = screen_plot,
       width = 8, height = 6, dpi = 300)
```

**Decisión**

Confirma visualmente la decisión del Paso 8.1: la curva se aplana después de PC4. No se toma ninguna decisión adicional en este paso, solo se corrobora el número de componentes a interpretar.

### 8.3 Biplot

Muestra las celdas como puntos y las variables como **flechas** sobre PC1 y PC2:

- flechas que apuntan en la **misma dirección** → variables correlacionadas (redundantes),
- flechas **opuestas** → correlación negativa,
- flechas **perpendiculares** → variables independientes,
- flechas **largas** → variables que aportan mucho a esos dos componentes.

```r
biplot <- fviz_pca_biplot(pca_result, repel = TRUE, label = "var",
                          col.var = "#084594",
                          col.ind = "#6baed6")

print(biplot)

ggsave("results/figures/02_biplot.png", plot = biplot,
       width = 8, height = 6, dpi = 300)
```

`label = "var"` muestra solo el nombre de las variables; con 10,000 celdas, las etiquetas de los puntos taparían la gráfica.

**Decisión**

Este plot es solo ilustrativo y **no se usa para tomar la decisión final**, porque solo representa el 69.80% de la varianza (PC1+PC2) y con 4 componentes relevantes deja fuera información importante. La selección real se basa en la tabla de cargas (Paso 8.4).

### 8.4 Cargas de las variables

Las **cargas** indican cuánto contribuye cada variable a cada componente (de −1 a 1). Una carga alta en valor absoluto significa que esa variable pesa mucho en ese componente.

```r
pca_loadings <- data.frame(pca_result$rotation)

print(round(pca_loadings[, 1:4], 2))

write.csv(round(pca_loadings, 3), "results/tables/02_cargas_pca.csv")
```

**Resultado**

| Variable | PC1 | PC2 | PC3 | PC4 |
|---|---|---|---|---|
| BIO1 | 0.24 | -0.32 | -0.12 | -0.06 |
| BIO10 | 0.10 | -0.45 | 0.02 | 0.04 |
| BIO11 | 0.29 | -0.14 | -0.22 | -0.13 |
| BIO12 | 0.30 | 0.13 | 0.11 | 0.18 |
| BIO13 | 0.29 | 0.14 | 0.00 | 0.32 |
| BIO14 | 0.23 | 0.05 | 0.40 | -0.05 |
| BIO15 | -0.03 | 0.07 | -0.42 | 0.50 |
| BIO16 | 0.28 | 0.15 | -0.02 | 0.31 |
| BIO17 | 0.24 | 0.05 | 0.41 | -0.04 |
| BIO18 | 0.23 | 0.14 | 0.02 | 0.42 |
| BIO19 | 0.21 | 0.04 | 0.39 | 0.08 |
| BIO2 | -0.26 | -0.01 | -0.05 | 0.29 |
| BIO3 | 0.17 | 0.23 | -0.34 | -0.13 |
| BIO4 | -0.23 | -0.23 | 0.26 | 0.19 |
| BIO5 | 0.03 | -0.46 | 0.00 | 0.15 |
| BIO6 | 0.30 | -0.13 | -0.15 | -0.20 |
| BIO7 | -0.28 | -0.15 | 0.15 | 0.29 |
| BIO8 | 0.11 | -0.40 | 0.00 | 0.17 |
| BIO9 | 0.23 | -0.27 | -0.17 | -0.02 |

**Decisión**

Se interpreta cada componente por sus mayores cargas:

- **PC1** (gradiente húmedo-templado vs. seco-continental): BIO12 y BIO6 con mayor carga.
- **PC2** (calor): BIO5 con la mayor carga (-0.46).
- **PC3** (lluvia en temporada seca): BIO17 con la mayor carga positiva (0.41).
- **PC4** (concentración de lluvia): BIO15 con la mayor carga (0.50).

Variables candidatas, una por componente: **BIO5, BIO6, BIO12, BIO15, BIO17**.

### 8.5 Variables importantes por componente

Se marcan como "importantes" las variables con carga mayor a **0.3** (en valor absoluto) en cada componente. Se muestran los primeros cuatro componentes.

```r
pca_importance <- apply(abs(pca_result$rotation), 2, function(x) which(x > 0.3))

print(pca_importance[1:4])
```

**Resultado**

| PC | Variables con carga > 0.3 (valor absoluto) |
|---|---|
| PC1 | BIO12, BIO6 |
| PC2 | BIO1, BIO10, BIO5, BIO8 |
| PC3 | BIO14, BIO15, BIO17, BIO19, BIO3 |
| PC4 | BIO13, BIO15, BIO16, BIO18 |

**Salidas:** `results/figures/02_screen_plot.png`, `results/figures/02_biplot.png` y `results/tables/02_cargas_pca.csv`.

**Decisión**

Confirma las variables candidatas del Paso 8.4: en cada grupo, BIO6 (PC1), BIO5 (PC2), BIO17 (PC3) y BIO15 (PC4, también aparece en PC3) tienen la mayor carga dentro de su respectivo grupo. Se mantiene la selección: **BIO5, BIO6, BIO12, BIO15, BIO17**.

## Paso 9 - Selección final de variables

Igual que en el ejercicio de clase, se eligen variables que representen **grupos no redundantes** según la correlación y el PCA.

**Criterios**

1. En el heatmap, identificar los **bloques** de variables muy correlacionadas entre sí (como referencia, |ρ| > 0.8).
2. Elegir **una variable por bloque**, preferentemente la que tenga mayor carga en los primeros componentes del PCA.
3. Procurar que el conjunto final combine variables de **temperatura** y de **precipitación**, y de ser posible alguna de **estacionalidad**.
4. Preferir variables con sentido biológico claro para mamíferos de zonas semiáridas (por ejemplo, extremos de temperatura o precipitación de la temporada seca).

**Resultado**

A partir de las cargas del PCA (Paso 8.4–8.5), se preseleccionó una variable por cada uno de los 4 componentes interpretados: BIO6 y BIO12 (PC1), BIO5 (PC2), BIO17 (PC3) y BIO15 (PC4). La matriz de correlación de Spearman entre estas 5 variables fue:

|       | BIO5  | BIO6  | BIO12 | BIO15 | BIO17 |
|-------|-------|-------|-------|-------|-------|
| BIO5  |  1.00 |  0.29 | -0.20 | -0.06 | -0.17 |
| BIO6  |  0.29 |  1.00 |  0.58 | -0.06 |  0.17 |
| BIO12 | -0.20 |  0.58 |  1.00 |  0.12 |  0.57 |
| BIO15 | -0.06 | -0.06 |  0.12 |  1.00 | -0.55 |
| BIO17 | -0.17 |  0.17 |  0.57 | -0.55 |  1.00 |

Ningún par supera el umbral de referencia (|ρ| > 0.8); la correlación más alta es BIO6–BIO12 (ρ = 0.58).

**Salida:** `results/tables/02_variables_seleccionadas.csv`, que se usará en los objetivos 3 a 5.

**Decisión**

Se confirma el conjunto final, sin necesidad de sustituciones: **BIO5** (temperatura máxima del mes más cálido), **BIO6** (temperatura mínima del mes más frío), **BIO12** (precipitación anual), **BIO15** (estacionalidad de la precipitación) y **BIO17** (precipitación del trimestre más seco). Las correlaciones moderadas entre BIO6–BIO12 (0.58), BIO12–BIO17 (0.57) y BIO15–BIO17 (-0.55) son esperables —reflejan el mismo patrón de invierno frío-seco visto desde variables distintas— y no alcanzan el umbral fijado para considerarse redundancia.

Las cinco especies registradas en la UMA (*Odocoileus virginianus*, *Urocyon cinereoargenteus*, *Canis latrans*, *Lynx rufus* y *Puma concolor*) son mamíferos de tamaño medio a grande sin adaptaciones fisiológicas extremas al calor o la sequía, por lo que su distribución y actividad dependen principalmente de dos factores: el estrés térmico directo y la disponibilidad de agua y forraje/presas en la temporada seca.

- **BIO5 y BIO6** capturan el estrés térmico directo. El venado cola blanca y sus depredadores regulan su actividad conductualmente frente a temperaturas extremas (p. ej., mayor actividad crepuscular/nocturna en los meses más calurosos), y el frío invernal limita el gasto energético disponible para forrajeo y reproducción. Estos extremos son más informativos para el nicho fisiológico que una temperatura media anual, que diluye ambos eventos.
- **BIO12, BIO15 y BIO17** capturan la disponibilidad de agua y, de forma indirecta, de forraje. En la Mixteca Poblana, la vegetación y por tanto la presa base (venado) dependen de la duración e intensidad de la temporada seca; esto repercute en cascada sobre los depredadores (coyote, zorra gris, gato montés, puma), cuya abundancia relativa publicada (IAR) varía entre especies posiblemente en relación con su tolerancia a esta limitación estacional de recursos.

Se excluyó deliberadamente el eje de **rango/estacionalidad térmica** (BIO4, BIO7), identificado como sub-bloque independiente en el Paso 7. Aunque estadísticamente no redundante con BIO5/BIO6, su interpretación fisiológica es menos directa para este grupo de mamíferos homeotermos de tamaño medio-grande, que responden más claramente a los extremos absolutos de temperatura y a la disponibilidad hídrica que a la amplitud del rango térmico en sí. Esta decisión prioriza la interpretabilidad biológica del modelo final sobre la exhaustividad estadística.

### Registro de resultados

| Variables iniciales | Varianza explicada por PC1 + PC2 | Variables seleccionadas | Justificación |
|---|---|---|---|
| 19 | 69.80% | BIO5, BIO6, BIO12, BIO15, BIO17 | Una variable por bloque de correlación (Paso 7), con mayor carga en su componente del PCA (Paso 8.4–8.5); |ρ| ≤ 0.58 entre todas las seleccionadas (Paso 9); sentido fisiológico para mamíferos semiáridos (estrés térmico y disponibilidad hídrica) |

## Estructura resultante

```
00-data-worldclim/            # 19 .tif de WorldClim
00-data-map-mex/destdv1gw.shp    # máscara de México
03-analisis-uma-rstudio/results/
├── figures/                  # 02_heatmap_spearman.png; 02_screen_plot.png; 02_biplot.png
└── tables/                   # 02_matriz_spearman.csv; 02_cargas_pca.csv; 02_variables_seleccionadas.csv
```

## Limitaciones

- **Resolución:** 2.5 min (~4.5 km) describe el clima a escala nacional; es más gruesa que la UMA.
- **Periodo climático:** WorldClim resume 1970–2000, mientras que los registros de presencia van de
  1980 a 2020 (ver objetivo 1).
- **Muestreo:** la correlación se calcula con 10,000 celdas y no con todas; `set.seed(123)` asegura
  que la muestra sea siempre la misma.
- **Selección:** la elección final combina criterios estadísticos y biológicos, por lo que se
  documenta su justificación en el registro de resultados.
