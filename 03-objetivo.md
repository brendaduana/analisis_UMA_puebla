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

png("results/figures/03_variables_seleccionadas.png", width = 2600, height = 1400, res = 200)

plot(bios_mx_sel, nc = 3)

dev.off()
```

**Resultado**

`bios_mx_sel`: 5 capas (BIO5, BIO6, BIO12, BIO15, BIO17), 436 × 760 celdas, resolución 0.0417° y sistema de coordenadas WGS 84.

| Variable | Mínimo | Máximo | Unidad |
|---|---|---|---|
| BIO5 | 12.0 | 42.8 | °C |
| BIO6 | −5.7 | 22.4 | °C |
| BIO12 | 45 | 4,655 | mm |
| BIO15 | 40.4 | 139.8 | coef. de variación |
| BIO17 | 0 | 542 | mm |

En `results/figures/03_variables_seleccionadas.png`, las cinco capas cubren solo el territorio mexicano y muestran los gradientes esperados: temperaturas máximas más altas en el noroeste y la Depresión del Balsas, mínimas más bajas en las sierras, y precipitación concentrada en el sureste húmedo.

**Decisión**

Los rangos de valores son realistas para México (sin valores como −9999 que indicarían celdas mal recortadas), así que el recorte es correcto y se puede exportar.

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

list.files("../04-maxent/capas_asc", pattern = "\\.asc$")
```

- `filetype = "AAIGrid"` es el nombre del formato ASCII grid.
- `NAflag = -9999` es el valor que Maxent reconoce como "sin dato" (fuera de México).
- El **nombre del archivo** es el que Maxent dará a la variable (`BIO5`, `BIO6`…).
- `list.files()` confirma que se crearon los cinco archivos.

**Resultado**

"BIO12.asc" "BIO15.asc" "BIO17.asc" "BIO5.asc" "BIO6.asc"

Las cinco capas comparten la misma rejilla, porque salen del mismo recorte (Paso 1.2): 436 × 760 celdas, resolución 0.0417° (2.5 min) y extensión −118.38 a −86.71 de longitud y 14.54 a 32.71 de latitud.

**Salida:** `04-maxent/capas_asc/` (5 archivos `.asc`; pueden aparecer `.prj` o `.aux.xml`, que Maxent ignora).

**Decisión**

Las capas cumplen lo que exige Maxent (mismo formato, extensión, resolución y número de celdas), así que quedan listas para el Paso 3. No hace falta ningún ajuste.

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
sum(fuera) #11
table(presencias$species[fuera])
 
presencias_maxent <- presencias[!fuera, ]
```

**Resultado**

11 de 7,958 registros (0.14%) cayeron en celdas sin dato climático: *C. latrans* 2, *L. rufus* 1, *O. virginianus* 3, *P. concolor* 2 y *U. cinereoargenteus* 3. Quedaron 7,947 registros para Maxent.

**Salida:** `04-maxent/presence/presencias_5spp.csv`.

**Decisión**

Se eliminaron los 11 puntos. Son muy pocos (entre 1 y 3 por especie, menos del 0.4% en todas) y su pérdida no cambia la representación del nicho; dejarlos solo haría que Maxent los descartara con una advertencia.
 
### 2.3 Celdas únicas
 
Maxent elimina por defecto los registros repetidos **dentro de una misma celda**, así que el número real de presencias que usa es el de celdas únicas.

**Resultado**

| Especie | Registros para Maxent | Celdas únicas | % conservado |
|---|---|---|---|
| *C. latrans* | 1,797 | 1,060 | 59.0% |
| *L. rufus* | 1,012 | 541 | 53.5% |
| *O. virginianus* | 2,678 | 1,183 | 44.2% |
| *P. concolor* | 589 | 377 | 64.0% |
| *U. cinereoargenteus* | 1,871 | 1,203 | 64.3% |

Entre el 36% y el 56% de los registros comparten celda con otro de la misma especie. *O. virginianus* es la más agrupada: sus registros se concentran en pocos sitios muy muestreados.

**Salida:** `results/tables/03_registros_maxent.csv`.

**Decisión**

No se eliminan duplicados en R: Maxent lo hace solo con la opción *Remove duplicate presence records*. Las celdas únicas son las presencias efectivas de cada modelo; con el 25% reservado para prueba, *P. concolor* tendrá unas 283 presencias de entrenamiento y 94 de prueba, suficientes para Maxent. El agrupamiento de los registros se reporta como posible sesgo de muestreo en las limitaciones.

## Paso 3 - Correr Maxent

Este paso se hace en la interfaz de Maxent, siguiendo la práctica de clase. Maxent no requiere instalación: se abre `maxent.jar` desde la carpeta descomprimida. Si no abre, hay que instalar Java.

La ventana de Maxent tiene tres secciones: arriba a la izquierda, las presencias (*Samples*); arriba a la derecha, las capas ambientales (*Environmental layers*); y abajo, la configuración.

### 3.1 Ventana principal

| Opción | Valor | Por qué |
|---|---|---|
| **Samples** | `04-maxent/presence/presencias_5spp.csv` | Archivo del Paso 2; aparecen las 5 especies marcadas |
| **Environmental layers** | carpeta `04-maxent/capas_asc` | Se selecciona la **carpeta** que contiene las capas, no un archivo |
| Tipo de variable | **Continuous** (las 5) | Temperatura y precipitación son valores numéricos continuos; *Categorical* sería para capas como tipo de vegetación |
| Create response curves | ✓ | Muestra cómo cambia la idoneidad a lo largo de cada variable |
| Make pictures of predictions | ✓ | Genera los mapas de cada modelo con los puntos de entrenamiento y prueba |
| Do jackknife to measure variable importance | ✓ | Mide cuánto aporta cada variable al modelo |
| Output format | **Cloglog** (predeterminado) | Idoneidad de 0 a 1, más fácil de interpretar que la salida cruda |
| Output file type | **asc** | Mismo formato que las capas de entrada; se lee en R y QGIS |
| **Output directory** | `04-maxent/results` | |
| Projection layers directory | vacío | Solo se usa para proyectar a otro tiempo o región |

### 3.2 Settings

| Opción | Valor | Por qué |
|---|---|---|
| Random test percentage | **10** | 90% de los puntos para construir el modelo y 10% para evaluarlo, como en la práctica de clase |
| Replicates | **10** | Varias réplicas permiten obtener un modelo promedio y su variación; en clase se usaron 3 como ejemplo y se recomendaron más |
| Replicated run type | **Bootstrap** | Cada réplica remuestrea los puntos de entrenamiento, como en clase |
| Random seed | ✓ (Maxent lo activa automáticamente con réplicas) | Cada réplica usa una partición distinta de los datos; sin esto, las réplicas serían idénticas |
| Show warnings / Ask questions | sin marcar | Evita ventanas emergentes durante la corrida, como en clase |
| Remove duplicate presence records | ✓ (predeterminado) | Una presencia por celda (Paso 2.3) |
| Max number of background points | 10000 (predeterminado) | |
| Regularization multiplier | 1 (predeterminado) | |
| Pestañas *Advanced* y *Experimental* | sin cambios | Se usan los valores predeterminados |

Clic en **Run**. Maxent construye las 10 réplicas de cada especie, una especie tras otra, y al final calcula los modelos resumen (promedio, mediana, mínimo, máximo y desviación estándar).

**Resultado**

Maxent 3.4.4 leyó las 5 capas (102,316 celdas con datos, las mismas del objetivo 2) y construyó 10 réplicas para cada especie (50 modelos en total). La configuración queda registrada en `04-maxent/results/maxent.log`:

```
java density.MaxEnt nowarnings noprefixes responsecurves jackknife outputdirectory=C:\analisis_uma\04-maxent\results samplesfile=C:\analisis_uma\04-maxent\presence\presencias_5spp.csv environmentallayers=C:\analisis_uma\04-maxent\capas_asc randomseed randomtestpoints=10 replicates=10 replicatetype=bootstrap
```

Las opciones que no aparecen en esa línea se dejaron en su valor predeterminado (salida cloglog, 10,000 puntos de fondo, eliminación de duplicados por celda, regularización 1).

Archivos generados en `04-maxent/results/`, por especie (con guion bajo en lugar del espacio):

| Archivo | Contenido |
|---|---|
| `Puma_concolor_0.asc` … `Puma_concolor_9.asc` | Mapa de idoneidad de cada réplica |
| `Puma_concolor_avg.asc` | **Mapa promedio de las 10 réplicas** (el que se usa en los pasos 5 y 6) |
| `Puma_concolor_stddev.asc` | Desviación estándar entre réplicas |
| `Puma_concolor_median.asc`, `_min.asc`, `_max.asc` | Otros resúmenes de las réplicas |
| `Puma_concolor.html` | **Reporte general** de las 10 réplicas: curva ROC, mapas resumen, curvas de respuesta y jackknife |
| `Puma_concolor_0.html` … `_9.html` | Reporte de cada réplica |

Además: `maxentResults.csv` (una fila por réplica y una fila `(average)` por especie), `maxent.log` y la carpeta `plots/` con las imágenes que aparecen en los reportes.

### 3.3 Revisión de los reportes

Para cada especie se abre en el navegador el reporte **general**, el que no tiene número (p. ej. `Puma_concolor.html`). Resume las 10 réplicas: la línea roja de cada gráfica es el promedio y la franja azul, la variación entre réplicas.

**1. Curva ROC y AUC**

El AUC mide qué tan bien distingue el modelo los sitios con presencia del resto del área. Un modelo al azar da 0.5 (la línea diagonal de la gráfica). Valores cercanos a 0.9 o mayores indican un buen modelo; entre 0.7 y 0.8 puede considerarse aceptable.

Dónde está: debajo de la curva ROC, en la frase *"The average test AUC for the replicate runs is …, and the standard deviation is …"*. Ese es el AUC promedio de prueba y su desviación estándar.

**2. Contribución de variables y jackknife**

Indican cuánto aporta cada variable al modelo.

Dónde está: en la sección *Analysis of variable contributions*. La tabla muestra *Percent contribution* (cuánto aportó cada variable al construir el modelo) y *Permutation importance* (cuánto empeora el modelo si se desordenan los valores de esa variable). La variable con mayor *Percent contribution* es la más importante.

Las gráficas del jackknife muestran qué pasa si se omite cada variable (barra verde clara) y si se usa sola (barra azul). Una barra azul larga indica que la variable por sí sola explica bien la distribución; si la barra verde clara se acorta mucho, esa variable aporta información que ninguna otra tiene.

**3. Curvas de respuesta**

Muestran cómo cambia la idoneidad a lo largo de cada variable e indican las preferencias climáticas de la especie.

Dónde está: hay dos juegos de curvas. Se usa el segundo, *each of the following curves shows… a Maxent model created using only the corresponding variable*, porque muestra el efecto de cada variable sola y es el más fácil de interpretar. En cada gráfica, el eje X es la variable y el eje Y la idoneidad (0 a 1).

Para cada especie se describe dónde está el pico de la curva, o hacia dónde sube, en la variable de mayor contribución y en las que tengan una respuesta clara (BIO5 y BIO6 en °C; BIO12 y BIO17 en mm; BIO15 sin unidad).

**4. Puntos de entrenamiento y prueba**

En el reporte de una réplica individual (p. ej. `Puma_concolor_0.html`), el mapa muestra los puntos de **entrenamiento en blanco** y los de **prueba en morado**. Si los puntos de prueba caen en zonas de idoneidad alta, el modelo predice bien sitios que no usó para construirse.

**Resultado** (completar)

| Especie | AUC de prueba (promedio ± DE) | Variable con mayor contribución | Curvas de respuesta |
|---|---|---|---|
| *C. latrans* | | | |
| *L. rufus* | | | |
| *O. virginianus* | | | |
| *P. concolor* | | | |
| *U. cinereoargenteus* | | | |

Los valores de AUC y contribución se obtienen también en R (Paso 4) desde `maxentResults.csv`, lo que permite verificar los que se leen en los reportes.

**Salidas:** `04-maxent/results/` (archivos por especie y réplica, `maxentResults.csv`, `maxent.log` y `plots/`).

**Decisión** (completar)

> **Modelo BAM y área accesible.** Maxent estima dónde el clima es adecuado (la **A** del modelo BAM), pero no considera las interacciones bióticas (**B**) ni la capacidad de dispersión (**M**). Por eso puede marcar como idóneas zonas de México a las que la especie no ha podido llegar. Lo ideal sería delimitar M a la provincia biogeográfica donde se distribuye cada especie; aquí se usó todo México (ver Limitaciones).
