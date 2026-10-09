# Objetivo 3 - Modelos de nicho ecológico con Maxent y proyección de la UMA
 
Con los registros depurados (objetivo 1) y las cinco variables no correlacionadas (objetivo 2), este objetivo construye un **modelo de nicho ecológico** para cada especie con Maxent y lo proyecta en el **espacio geográfico** de México. Después se ubica la UMA Santa Cruz Nuevo sobre esos mapas para responder una primera pregunta:

**¿el clima de la UMA es idóneo para cada especie, y qué tan idóneo es comparado con los sitios donde la especie sí ha sido registrada?**

[Maxent](https://www.gbif.org/es/tool/81279/maxent), compara el clima de los sitios con presencia contra el clima de puntos de fondo (*background*) tomados de toda el área de estudio, y estima qué combinaciones de clima se asocian con la presencia. El resultado es un mapa de **idoneidad climática** de 0 a 1. No es un mapa de distribución real ni de abundancia: indica dónde el clima se parece al de los sitios con registros.

## Flujo de trabajo
 
| Paso | Qué se hace | Dónde | Origen en el curso |
|---|---|---|---|
| 0 | Preparar R e instalar Maxent | R / navegador | *Ejercicios sobre Análisis Estadístico en R* y práctica de GBIF y Maxent (Q) |
| 1 | Preparar las capas en formato `.asc` | R | Práctica 1, *Espacio geográfico y espacio ecológico* (V) |
| 2 | Unir y verificar las presencias | R | Mismo formato del objetivo 1 (Q) |
| 3 | Correr Maxent | Maxent | Práctica de GBIF y Maxent (Q) |
| 4 | Leer el desempeño de los modelos | R | Práctica de GBIF y Maxent (Q) |
| 5 | Mapas de idoneidad y binarios | R | Práctica 1 (V) |
| 6 | Proyectar la UMA en el espacio geográfico | R | Práctica 1 (V) |
| 7 | Figuras | R (y QGIS opcional) | Visualización del modelo en QGIS (Q) |

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
 
### 0.2 Maxent
 
1. Descargar Maxent (versión 3.4.x) desde la página del [American Museum of Natural History](https://biodiversityinformatics.amnh.org/open_source/maxent/).
2. Descomprimir y abrir `maxent.jar` (en Windows también `maxent.bat`).
3. Si no abre, instalar [Java](https://www.java.com) y volver a intentar.

### 0.3 Carpetas
 
Igual que en el objetivo 2, el script se corre desde el proyecto `03-analisis-uma-rstudio.Rproj`. Se agrega una carpeta nueva para todo lo que entra y sale de Maxent:
 
```r
dir.create("../04-maxent/capas_asc", recursive = TRUE, showWarnings = FALSE)
dir.create("../04-maxent/presencias", recursive = TRUE, showWarnings = FALSE)
dir.create("../04-maxent/resultados", recursive = TRUE, showWarnings = FALSE)
```


