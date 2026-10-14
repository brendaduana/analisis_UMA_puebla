# Objetivo 4. Posición de la UMA dentro del nicho climático de cada especie
 
Con las presencias (objetivo 1), las cinco variables (objetivo 2) y los modelos de Maxent (objetivo 3), este objetivo pasa del espacio geográfico al **espacio ambiental** (dualidad de Hutchinson, V) para responder:
 
**¿La UMA ocupa una posición central o marginal dentro del nicho climático de cada especie?**
 
Para cada especie se construye un **elipsoide de nicho** con el clima de sus registros (5 variables = elipsoide de 5 dimensiones). Después se mide qué tan lejos queda el clima de la UMA del **centroide** del elipsoide. Según la hipótesis de la posición del nicho (V; Martínez-Meyer et al. 2013), las especies que encuentran en un sitio condiciones cercanas al centro de su nicho deberían ser más abundantes ahí. Con la abundancia relativa publicada (IAR; Plata-Pérez et al. 2024) se hace una comparación exploratoria.
 
En el objetivo 3 se midió la idoneidad del clima de la UMA **en el espacio geográfico**; aquí se mide su **posición en el espacio ambiental**. Son preguntas relacionadas pero distintas: Maxent estima una idoneidad relativa a todo México, mientras que la distancia al centroide describe qué tan típico es el clima de la UMA para la especie.
 
## Flujo de trabajo
 
| Paso | Qué se hace | Dónde | Origen en el curso |
|---|---|---|---|
| 0 | Preparar paquetes (`ellipsenm`) | R | Práctica 4, comparación de nicho climático (V) |
| 1 | Cargar variables, capas `.asc` y presencias | R | Objetivos 2 y 3 |
| 2 | Clima de las presencias (una por celda) | R | Objetivo 3, paso 2.3 |
| 3 | Clima de la UMA | R | Práctica 1 (V) |
| 4 | Elipsoide de nicho de cada especie | R | Práctica 4 (V) |
| 5 | Distancia de la UMA al centroide | R | Práctica 2.1, posición del nicho (V) |
| 6 | Posición de nicho y abundancia relativa | R | Hipótesis de la posición del nicho (V) |
| 7 | Figuras | R | PCA del objetivo 2 (Q) |
 
## Paso 0. Preparar el ambiente

```r
if (!require("terra")) install.packages("terra")
if (!require("raster")) install.packages("raster")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("devtools")) install.packages("devtools")
if (!require("ellipsenm")) {
  devtools::install_github("marlonecobos/ellipsenm")
}
 
library(terra)
library(ggplot2)
library(ellipsenm)
```
 
- `ellipsenm` (Cobos et al.) construye elipsoides de nicho; se instala desde GitHub como en la práctica de V.
- `raster` se necesita porque `ellipsenm` lee las capas como `raster::stack`, igual que en la práctica.

```r
dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)
```
 
## Paso 1. Cargar los insumos de los objetivos 2 y 3
 
### 1.1 Variables
 
```r
variables_seleccionadas <- read.csv("results/tables/02_variables_seleccionadas.csv")$variable
 
variables_seleccionadas
```

### 1.2 Capas climáticas
 
Se usan los `.asc` que se exportaron para Maxent (objetivo 3, paso 1.3). Así el nicho se estima con la misma rejilla y el mismo recorte a México que los modelos.
 
```r
archivos_asc <- file.path("../04-maxent/capas_asc",
                          paste0(variables_seleccionadas, ".asc"))
 
file.exists(archivos_asc)   # deben ser 5 TRUE
 
capas <- rast(archivos_asc)
names(capas) <- variables_seleccionadas
crs(capas) <- "EPSG:4326"
 
capas_stack <- raster::stack(archivos_asc)
names(capas_stack) <- variables_seleccionadas
```
 
- `paste0(variables_seleccionadas, ".asc")` arma el nombre de cada archivo en el orden de las variables.
- `rast()` carga las capas con `terra`, para extraer valores en los pasos 2 y 3.
- `crs()` asigna WGS 84, porque los `.asc` no guardan el sistema de coordenadas.
- `raster::stack()` carga las mismas capas en el formato que usa `ellipsenm` (paso 4).

### 1.3 Presencias
 
```r
presencias <- read.csv("../04-maxent/presence/presencias_5spp.csv")
 
presencias$species <- gsub(" ", "_", presencias$species)
 
especies <- sort(unique(presencias$species))
 
especies
nrow(presencias)   # 7947
```
 
- Se usa el mismo archivo que Maxent (7,947 registros), para que el nicho y los modelos se basen exactamente en los mismos datos.
- `gsub(" ", "_", ...)` pone los nombres con guion bajo, igual que los archivos de Maxent y la tabla de IAR.

**Resultado**
 
> Pendiente de correr: `especies` debe dar las 5 especies y `nrow(presencias)`, 7,947.




