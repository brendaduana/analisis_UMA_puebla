# Objetivo 3 - Modelos de nicho ecológico con Maxent y proyección de la UMA
 
Con los registros depurados (objetivo 1) y las cinco variables seleccionadas en el objetivo 2 (BIO5, BIO6, BIO12, BIO15, BIO17), este objetivo construye un **modelo de nicho ecológico** por especie con Maxent y lo proyecta en el **espacio geográfico** de México. Después se ubica la UMA Santa Cruz Nuevo sobre esos mapas para responder: 

**¿el clima de la UMA es idóneo para cada especie, y qué tan idóneo es comparado con los sitios donde la especie ha sido registrada?**

[Maxent](https://biodiversityinformatics.amnh.org/open_source/maxent/), compara el clima de los sitios con presencia contra el clima de puntos de fondo (*background*) tomados de toda el área de estudio, y estima qué combinaciones de clima se asocian con la presencia. El resultado es un mapa de **idoneidad climática** de 0 a 1. No es un mapa de distribución real ni de abundancia: indica dónde el clima se parece al de los sitios con registros.

## Flujo de trabajo
 
| Paso | Qué se hace | Dónde | Origen en el curso |
|---|---|---|---|
| 0 | Preparar R e instalar Maxent | R / navegador | Práctica de GBIF y Maxent (Q) |
| 1 | Preparar las capas en formato `.asc` | R | Práctica 1, *Espacio geográfico y espacio ecológico* (V) |
| 2 | Unir y verificar las presencias | R | Formato del objetivo 1 (Q) |
| 3 | Correr Maxent | Maxent | Práctica de GBIF y Maxent (Q) |
| 4 | Desempeño de los modelos | R | Práctica de GBIF y Maxent (Q) |
| 5 | Mapas de idoneidad y binarios | R | Práctica 1 (V) |
| 6 | Proyectar la UMA en el espacio geográfico | R | Práctica 1 (V) |
| 7 | Figuras | R (QGIS opcional) | Visualización del modelo en QGIS (Q) |

## Paso 0 - Preparar el ambiente
 
### 0.1 Paquetes de R
 
```r
if (!require("terra")) install.packages("terra")        # Capas raster y vectoriales
if (!require("ggplot2")) install.packages("ggplot2")    # Mapas
if (!require("reshape2")) install.packages("reshape2")  # melt() para los paneles
 
library(terra)
library(ggplot2)
library(reshape2)
```

Se agrega una carpeta para archivos de entrada y salida de Maxent:
 
```r
dir.create("../04-maxent/capas_asc", recursive = TRUE, showWarnings = FALSE)
dir.create("../04-maxent/presencias", recursive = TRUE, showWarnings = FALSE)
dir.create("../04-maxent/resultados", recursive = TRUE, showWarnings = FALSE)
```
 
### 0.2 Maxent
 
1. Descargar Maxent (versión 3.4.x) desde la página del [American Museum of Natural History](https://biodiversityinformatics.amnh.org/open_source/maxent/).
2. Descomprimir y abrir `maxent.jar` (en Windows también `maxent.bat`).
3. Si no abre, instalar [Java](https://www.java.com) y volver a intentar.

## Paso 1 - Preparar las capas climáticas para Maxent
 
### 1.1 Variables del objetivo 2

Las variables se leen desde el archivo que generó el objetivo 2, en lugar de escribirlas a mano, para garantizar que los modelos usen exactamente las mismas.
 
```r
variables_seleccionadas <- read.csv("results/tables/02_variables_seleccionadas.csv")$variable

variables_seleccionadas
```

### 1.2 Cargar y recortar
 
Es el mismo procedimiento de los [pasos 3 y 4 del objetivo 2](02-objetivo.md#paso-3---cargar-las-capas-en-rstudio)
 
```r
bios <- list.files(
  path = "../00-data-worldclim",
  pattern = "\\.tif$",
  full.names = TRUE
)

bios <- rast(bios)

names(bios) <- sub("wc2.1_2.5m_bio_", "BIO", names(bios))

mexico <- vect("../00-data-map-mex/destdv1gw.shp")
```

Pero solo con las cinco variables seleccionadas:

```r
bios_mx_sel <- mask(
  crop(bios[[variables_seleccionadas]], mexico),
  mexico
)

bios_mx_sel

png("results/figures/03_variables_seleccionadas.png", width = 2000, height = 1200, res = 200)

plot(bios_mx_sel)

dev.off()
```
 
### 1.3 Exportar a `.asc`
 
Maxent no lee `.tif`: necesita capas **ASCII grid (`.asc`)** con la misma extensión, resolución y número de celdas.
 
```r
for (v in variables_seleccionadas) {
  writeRaster(
    bios_mx_sel[[v]],
    filename = paste0("../04-maxent/capas_asc/", v, ".asc"),
    filetype = "AAIGrid",
    NAflag = -9999,
    overwrite = TRUE
  )
}
```
 
- `filetype = "AAIGrid"` es el nombre del formato ASCII grid.
- `NAflag = -9999` es el valor que Maxent reconoce como "sin dato" (fuera de México).
- El **nombre del archivo** es el que Maxent dará a la variable (`BIO5`, `BIO6`…).

**Resultado**
 
Cinco archivos en `04-maxent/capas_asc/`: `BIO5.asc`, `BIO6.asc`, `BIO12.asc`, `BIO15.asc` y `BIO17.asc` (pueden aparecer `.prj` o `.aux.xml`; Maxent los ignora).
 
> **¿Por qué recortar a México?** Maxent toma los puntos de fondo de toda el área que cubren las capas. Esa área representa lo que la especie pudo haber ocupado: el **área accesible (M)** vista con V. Aquí M = México, la misma región de los registros y de la selección de variables.

## Paso 2 - Unir y verificar las presencias
 
### 2.1 Un solo archivo para las cinco especies
 
Maxent acepta un archivo con varias especies (`Species, Longitude, Latitude`) y hace un modelo independiente para cada una. Se unen los cinco CSV del objetivo 1:
 
```r
archivos_presencias <- list.files("../02-data-clean-qgis", pattern = "\\.csv$", full.names = TRUE)

archivos_presencias

presencias <- do.call(rbind, lapply(archivos_presencias, read.csv))

names(presencias)

table(presencias$species)
```
 
### 2.2 Puntos sin valor climático
 
Algunos puntos válidos en QGIS pueden caer en celdas sin dato (costa, islas pequeñas), porque una celda de ~4.5 km no coincide exactamente con la línea de costa. Se quitan antes de Maxent para saber cuántos son.
 
```r
valores_presencias <- extract(bios_mx_sel, as.matrix(presencias[, c("longitude", "latitude")]))
 
fuera <- !complete.cases(valores_presencias)
 
presencias_maxent <- presencias[!fuera, ]
```
 
### 2.3 Celdas únicas
 
Maxent elimina por defecto los registros repetidos **dentro de una misma celda**, así que el número real de presencias que usa es el de celdas únicas.

 
**Resultado** (completar)
 
| Especie | Registros (objetivo 1) | Sin dato climático | Registros para Maxent | Celdas únicas |
|---|---|---|---|---|
| *U. cinereoargenteus* | | | | |
| *O. virginianus* | | | | |
| *C. latrans* | | | | |
| *L. rufus* | | | | |
| *P. concolor* | | | | |
 
**Salidas:** `04-maxent/presencias/presencias_5spp.csv` y `results/tables/03_registros_maxent.csv`.

