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
| *C. latrans* | Baja con calor extremo (> ~30) | Alta entre ~0 y 10; baja con inviernos cálidos | Máxima con poca lluvia; disminuye al aumentar | Poca influencia | Máxima cerca de 0; baja al aumentar |
| *L. rufus* | Alta hasta ~23; baja con más calor | Alta entre ~−3 y 10; casi cero por encima de ~11 | Máxima entre ~500 y 800; casi cero por encima de ~1,500 | Sin patrón claro | Alta por debajo de ~50; casi cero por encima de ~150 |
| *O. virginianus* | Máxima ~19; baja con más calor | Aumenta con inviernos más cálidos | Casi cero por debajo de ~450; alta en un rango amplio | Estable; cae por encima de ~125 | Casi cero en 0; alta con poca lluvia; baja lentamente al aumentar |
| *P. concolor* | Alta hasta ~26; casi cero por encima de ~38 | Aumenta hasta ~18; casi cero por encima de ~20 | Casi cero por debajo de ~400; máxima en sitios húmedos | Sin patrón claro | Máxima cerca de ~200; casi cero por encima de ~400 |
| *U. cinereoargenteus* | Alta hasta ~25; baja con más calor | Aumenta con inviernos más cálidos | Máxima con lluvia moderada (~1,000); baja gradualmente | Aumenta con lluvia más estacional (> ~120) | Alta por debajo de ~100; baja lentamente al aumentar |

El AUC y la contribución de cada variable se documentan en el Paso 4, a partir de `maxentResults.csv`.

**Salidas:** `04-maxent/results/` (archivos por especie y réplica, `maxentResults.csv`, `maxent.log` y `plots/`).

**Decisión**

Las curvas de respuesta son coherentes con la ecología conocida de las cinco especies, por lo que los modelos se consideran biológicamente razonables y se continúa con su evaluación numérica (Paso 4). Se distinguen tres patrones:

- ***L. rufus*** y ***C. latrans*** se asocian con climas secos y templados con inviernos fríos (sierras, Altiplano y norte del país). El lince es el más restringido: su idoneidad cae casi a cero con inviernos cálidos (BIO6 > ~11 °C) o lluvia abundante.
- ***O. virginianus*** y ***U. cinereoargenteus*** son generalistas: toleran un rango amplio de lluvia y aumentan su idoneidad con inviernos cálidos. El venado evita sobre todo la aridez extrema (BIO12 < ~450 mm y BIO17 cercano a 0); la zorra se asocia con lluvia muy estacional.
- ***P. concolor*** se asocia con climas templados y relativamente húmedos, y evita tanto la aridez extrema como el calor intenso. Sus curvas tienen la mayor variación entre réplicas, porque es la especie con menos registros (377 celdas). Su baja idoneidad en zonas desérticas puede reflejar el sesgo de muestreo de GBIF más que su ausencia real.

En las cinco especies, el calor extremo del verano (BIO5) reduce la idoneidad, y la disponibilidad de agua en la temporada seca (BIO12 y BIO17) separa a las especies de climas secos de las de climas húmedos. Esto apoya la justificación biológica de las variables seleccionadas (objetivo 2, Paso 9).

## Paso 4 - Desempeño de los modelos

En el Paso 3 se revisaron los reportes de Maxent de forma visual. En este paso se obtienen en R los valores numéricos de cada modelo desde la tabla resumen que genera Maxent (`maxentResults.csv`), para las cinco especies a la vez. Se evalúa:

- **AUC de entrenamiento y de prueba:** qué tan bien distingue el modelo las presencias del fondo. Un modelo al azar da 0.5; valores cercanos a 0.9 o mayores indican un buen modelo, y entre 0.7 y 0.8 puede considerarse aceptable. Importa sobre todo el **AUC de prueba**, calculado con el 10% de los puntos que el modelo no usó; si es mucho menor que el de entrenamiento, hay sobreajuste.
- **Umbral del percentil 10:** el valor de idoneidad que se usará en el Paso 5 para convertir los mapas en idóneo/no idóneo.
- **Contribución de las variables:** cuánto aporta cada variable al modelo (Paso 4.3).

### 4.1 Leer la tabla resumen de Maxent

```r
resultados_maxent <- read.csv("../04-maxent/results/maxentResults.csv",
                              check.names = FALSE)

names(resultados_maxent)
resultados_maxent$Species
```

- `check.names = FALSE` conserva los nombres originales de las columnas de Maxent, que tienen espacios y `#` (p. ej. `Test AUC`, `#Training samples`). Sin esta opción, R los cambiaría (p. ej. `Test.AUC`, `X.Training.samples`).
- `names()` muestra las columnas disponibles.
- `resultados_maxent$Species` muestra las filas de la tabla.

**Resultado**

La tabla tiene 119 columnas y 55 filas: por cada especie, una fila por réplica (`Canis_latrans_0` … `Canis_latrans_9`) y una fila con el promedio de las 10 réplicas (`Canis_latrans (average)`). Las columnas incluyen el AUC de entrenamiento y de prueba, la desviación estándar del AUC, la contribución e importancia por permutación de cada variable, los resultados del jackknife y varios umbrales.

**Decisión**

Se usa solo la fila `(average)` de cada especie, porque resume las 10 réplicas y corresponde a los mapas promedio (`_avg.asc`) que se usarán en los pasos 5 y 6.

### 4.2 Tabla de desempeño

```r
promedios <- resultados_maxent[grepl("\\(average\\)", resultados_maxent$Species), ]

promedios$Species

col_umbral <- "10 percentile training presence Cloglog threshold"

resumen_maxent <- data.frame(
  especie = sub(" \\(average\\)", "", promedios$Species),
  presencias_entrenamiento = round(promedios[["#Training samples"]]),
  presencias_prueba = round(promedios[["#Test samples"]]),
  auc_entrenamiento = round(promedios[["Training AUC"]], 3),
  auc_prueba = round(promedios[["Test AUC"]], 3),
  auc_prueba_de = round(promedios[["AUC Standard Deviation"]], 3),
  umbral_p10 = round(promedios[[col_umbral]], 3)
)

resumen_maxent

write.csv(resumen_maxent, "results/tables/03_desempeno_maxent.csv", row.names = FALSE)
```

- `grepl("\\(average\\)", ...)` selecciona las filas cuyo nombre contiene `(average)`. Los `\\` son necesarios porque los paréntesis tienen un significado especial en R.
- `sub(" \\(average\\)", "", ...)` quita el texto ` (average)` del nombre, para que coincida con el de los archivos `_avg.asc` (p. ej. `Canis_latrans`).
- `[["…"]]` toma cada columna por su nombre exacto.
- `round()` redondea a tres decimales; en las presencias, a enteros, porque Maxent las promedia entre réplicas.
- `AUC Standard Deviation` es la desviación estándar del AUC de prueba entre las 10 réplicas.

**Resultado**

| Especie | Presencias entr. / prueba | AUC entrenamiento | AUC prueba (± DE) | Umbral p10 |
|---|---|---|---|---|
| *C. latrans* | 954 / 106 | 0.679 | 0.661 ± 0.025 | 0.416 |
| *L. rufus* | 487 / 54 | 0.763 | 0.732 ± 0.030 | 0.441 |
| *O. virginianus* | 1,065 / 118 | 0.715 | 0.701 ± 0.022 | 0.426 |
| *P. concolor* | 341 / 37 | 0.774 | 0.746 ± 0.040 | 0.383 |
| *U. cinereoargenteus* | 1,083 / 120 | 0.675 | 0.671 ± 0.025 | 0.397 |

Las presencias de entrenamiento y prueba suman las celdas únicas del Paso 2.3, divididas 90/10. El AUC de prueba es casi igual al de entrenamiento en todas las especies (diferencia ≤ 0.03) y varía poco entre réplicas (DE ≤ 0.04).

**Salida:** `results/tables/03_desempeno_maxent.csv`.

**Decisión**

*L. rufus*, *O. virginianus* y *P. concolor* tienen un AUC de prueba aceptable (0.70–0.75). *C. latrans* y *U. cinereoargenteus* quedan por debajo de 0.7. El AUC bajo de estas dos especies refleja su amplia distribución en México: su clima se parece al de casi todo el fondo, por lo que el modelo no puede distinguir con claridad las presencias. Esto es coherente con sus curvas de respuesta (Paso 3.3), las más amplias de las cinco especies, y con el uso de todo México como área accesible (M).

No hay sobreajuste (AUC de entrenamiento y prueba similares) y las réplicas son estables. Se usan los cinco modelos en los pasos siguientes, sin cambiar la configuración. Los resultados de *C. latrans* y *U. cinereoargenteus* se interpretan con cautela, porque su idoneidad discrimina poco entre sitios.

### 4.3 Contribución de las variables

Se obtienen dos medidas de la importancia de cada variable, promediadas entre las 10 réplicas:

| Medida | Qué indica |
|---|---|
| **Contribución** | Cuánto usó Maxent cada variable al construir el modelo. Depende del orden en que las incorporó |
| **Importancia por permutación** | Cuánto empeora el modelo si se desordenan los valores de esa variable. Es más confiable cuando hay variables correlacionadas |

```r
col_contrib <- grep(" contribution$", names(promedios), value = TRUE)
col_perm <- grep(" permutation importance$", names(promedios), value = TRUE)

contribucion <- data.frame(
  especie = sub(" \\(average\\)", "", promedios$Species),
  round(promedios[, col_contrib], 1)
)
names(contribucion) <- c("especie", sub(" contribution", "", col_contrib))

permutacion <- data.frame(
  especie = sub(" \\(average\\)", "", promedios$Species),
  round(promedios[, col_perm], 1)
)
names(permutacion) <- c("especie", sub(" permutation importance", "", col_perm))

contribucion
permutacion

write.csv(contribucion, "results/tables/03_contribucion_variables.csv", row.names = FALSE)
write.csv(permutacion, "results/tables/03_importancia_permutacion.csv", row.names = FALSE)
```

- `grep(" contribution$", ...)` busca las columnas cuyo nombre termina en ` contribution`, una por variable; el `$` indica "al final del nombre". Lo mismo con ` permutation importance`.
- `sub(...)` acorta los nombres de las columnas a `BIO12`, `BIO15`, etc.
- `round(..., 1)` redondea a un decimal; los valores son porcentajes.

**Resultado**

Contribución (%):

| Especie | BIO5 | BIO6 | BIO12 | BIO15 | BIO17 |
|---|---|---|---|---|---|
| *C. latrans* | 29.6 | **31.1** | 28.6 | 6.0 | 4.7 |
| *L. rufus* | 24.5 | **54.3** | 7.6 | 9.1 | 4.4 |
| *O. virginianus* | 13.9 | 5.1 | **63.9** | 8.4 | 8.7 |
| *P. concolor* | 23.0 | 15.2 | **32.2** | 9.5 | 20.1 |
| *U. cinereoargenteus* | **31.4** | 29.0 | 23.0 | 7.0 | 9.6 |

Importancia por permutación (%):

| Especie | BIO5 | BIO6 | BIO12 | BIO15 | BIO17 |
|---|---|---|---|---|---|
| *C. latrans* | **33.8** | 17.0 | 27.8 | 15.1 | 6.2 |
| *L. rufus* | 20.0 | **32.2** | 21.5 | 12.9 | 13.3 |
| *O. virginianus* | 22.9 | 20.6 | **30.7** | 8.3 | 17.5 |
| *P. concolor* | 24.4 | 22.6 | **26.7** | 15.7 | 10.5 |
| *U. cinereoargenteus* | 27.7 | **40.9** | 12.8 | 7.7 | 10.9 |

**Salidas:** `results/tables/03_contribucion_variables.csv` y `results/tables/03_importancia_permutacion.csv`.

**Decisión**

BIO5, BIO6 y BIO12 son las variables principales en las cinco especies; BIO15 y BIO17 tienen un papel secundario. Las variables más importantes coinciden con las curvas de respuesta (Paso 3.3): la temperatura mínima invernal (BIO6) domina en *L. rufus* y *U. cinereoargenteus*, la precipitación anual (BIO12) en *O. virginianus* y *P. concolor*, y *C. latrans*, la especie más generalista, depende de varias variables con un peso similar.

En *O. virginianus*, la contribución de BIO12 (63.9%) es mucho mayor que su importancia por permutación (30.7%). Esto ocurre porque BIO12 comparte información con BIO6 y BIO17 (ρ = 0.58 y 0.57; objetivo 2) y Maxent la incorporó primero. Por eso la interpretación se basa en la **importancia por permutación**, que muestra que el modelo del venado depende de forma más equilibrada de BIO12, BIO5 y BIO6.

Todas las variables aportan al menos un 6% en todas las especies, así que se mantienen las cinco y no se vuelven a correr los modelos.

# Paso 5 · Mapas de idoneidad y mapas binarios ---####

# 5.1 Leer los mapas promedio de Maxent (_avg.asc)

especies <- resumen_maxent$especie   # p. ej. "Canis_latrans"

mapas <- rast(paste0("../04-maxent/results/", especies, "_avg.asc"))
names(mapas) <- especies
crs(mapas) <- "EPSG:4326"   # los .asc de Maxent no traen sistema de coordenadas

mapas

plot(mapas)

## Paso 5 - Mapas de idoneidad y mapas binarios

### 5.1 Leer los mapas promedio

Se usan los mapas promedio de las 10 réplicas (`_avg.asc`) que generó Maxent en el Paso 3.

```r
especies <- resumen_maxent$especie

mapas <- rast(paste0("../04-maxent/results/", especies, "_avg.asc"))
names(mapas) <- especies
crs(mapas) <- "EPSG:4326"

mapas

plot(mapas)
```

- `especies` toma los nombres de la tabla del Paso 4, para que los mapas queden en el mismo orden que el umbral p10 de cada especie (Paso 5.2).
- `paste0(...)` arma la ruta de cada archivo, p. ej. `../04-maxent/results/Canis_latrans_avg.asc`.
- `rast()` lee los cinco mapas y los junta en un solo objeto de 5 capas.
- `crs()` asigna WGS 84, el mismo sistema de WorldClim, porque los `.asc` de Maxent no lo guardan.

**Resultado**

Los mapas reproducen los patrones de las curvas de respuesta (Paso 3.3):

| Especie | Idoneidad alta | Idoneidad baja |
|---|---|---|
| *C. latrans* | Centro de Baja California, Eje Neovolcánico y sierras de Puebla y Oaxaca | Sureste (Tabasco, Chiapas, Yucatán) y Sierra Madre Occidental |
| *L. rufus* | Sierras y Altiplano del centro, Sierra Madre Occidental | Sureste y costas cálidas (casi nula) |
| *O. virginianus* | Península de Yucatán, vertiente del Golfo y centro del país | Desiertos de Sonora, Chihuahua y Baja California |
| *P. concolor* | Sierra Madre Occidental, vertiente del Golfo y Chiapas | Desiertos del norte y Baja California |
| *U. cinereoargenteus* | Península de Yucatán, centro y sur del país | Desiertos del norte |

**Decisión**

Los mapas comparten la rejilla de las capas de entrada, por lo que pueden compararse entre especies y con la ubicación de la UMA (Paso 6).

### 5.2 Mapas binarios

Para clasificar cada celda como idónea o no idónea se usa el **umbral del percentil 10 de presencias de entrenamiento** (Paso 4.2): el valor de idoneidad por debajo del cual queda el 10% de las presencias. Supone que hasta un 10% de los registros pueden ser errores o sitios marginales, un supuesto razonable para datos de GBIF.

```r
binarios <- rast(lapply(seq_along(especies), function(i) {
  mapas[[i]] >= resumen_maxent$umbral_p10[i]
}))
names(binarios) <- especies

binarios

plot(binarios)
```

- `lapply(seq_along(especies), ...)` recorre las cinco especies; en cada una compara su mapa con su propio umbral, porque cada especie tiene uno distinto.
- `mapas[[i]] >= ...` devuelve `TRUE` (idóneo) o `FALSE` (no idóneo) en cada celda.
- `rast()` junta los cinco resultados en un objeto de 5 capas.

**Resultado**

`binarios`: 5 capas con valores `TRUE`/`FALSE`, en la misma rejilla que los mapas de idoneidad.

| Especie | Zonas no idóneas |
|---|---|
| *C. latrans* | Sureste, costa del Pacífico sur y parches de la Sierra Madre Occidental |
| *L. rufus* | Sureste, costas cálidas y parte de Baja California |
| *O. virginianus* | Desiertos de Sonora, Chihuahua y Baja California |
| *P. concolor* | Desiertos del norte, Altiplano y Baja California |
| *U. cinereoargenteus* | Desiertos del norte |

### 5.3 Porcentaje de México clasificado como idóneo

```r
area_idonea <- data.frame(
  especie = especies,
  umbral_p10 = resumen_maxent$umbral_p10,
  porcentaje_idoneo = round(unlist(global(binarios, "mean", na.rm = TRUE)) * 100, 1)
)

area_idonea

write.csv(area_idonea, "results/tables/03_area_idonea.csv", row.names = FALSE)
```

- `global(binarios, "mean", na.rm = TRUE)` calcula el promedio de cada capa. Como `TRUE` vale 1 y `FALSE` vale 0, el promedio es la proporción de celdas idóneas.
- `* 100` lo convierte en porcentaje.

**Resultado**

| Especie | Umbral p10 | % de México idóneo |
|---|---|---|
| *C. latrans* | 0.416 | 70.7 |
| *L. rufus* | 0.441 | 56.4 |
| *O. virginianus* | 0.426 | 64.0 |
| *P. concolor* | 0.383 | 56.8 |
| *U. cinereoargenteus* | 0.397 | 74.2 |

Las especies con mayor área idónea son las de AUC más bajo (*U. cinereoargenteus* y *C. latrans*), y las de menor área, las de AUC más alto (*L. rufus* y *P. concolor*).

**Salida:** `results/tables/03_area_idonea.csv`.

**Decisión**

Entre el 56% y el 74% de México resulta idóneo para cada especie, así que el mapa binario discrimina poco, sobre todo en las especies generalistas. Por eso, en el Paso 6 la ubicación de la UMA se evalúa principalmente con la **idoneidad continua** y su **percentil** respecto a las presencias de cada especie; la clasificación binaria se reporta solo como complemento.

## Paso 6 - Proyectar la UMA en el espacio geográfico

Con los mapas del Paso 5 se evalúa qué tan idóneo es el clima de la UMA Santa Cruz Nuevo para cada especie, y cómo se compara con los sitios donde cada especie ha sido registrada en México.

### 6.1 Ubicación de la UMA

Las coordenadas se tomaron del área de estudio de Plata-Pérez et al. (2024): 18°17'44" N y 97°48'35" W, que en grados decimales son 18.2956 y −97.8097 (la longitud es negativa por estar al oeste).

```r
uma <- data.frame(
  sitio = "UMA Santa Cruz Nuevo",
  longitude = -97.8097,
  latitude = 18.2956
)

uma_vect <- vect(uma, geom = c("longitude", "latitude"), crs = "EPSG:4326")

uma_vect
```

- `uma` guarda las coordenadas en una tabla, con los mismos nombres de columna que las presencias (`longitude`, `latitude`).
- `vect(...)` convierte la tabla en un punto con el sistema de coordenadas WGS 84, el mismo de los mapas.

### 6.2 Idoneidad en la UMA

```r
idoneidad_uma <- unlist(extract(mapas, uma_vect)[, especies])
binario_uma <- unlist(extract(binarios, uma_vect)[, especies])

uma_buffer <- buffer(uma_vect, width = 5000)
idoneidad_buffer <- unlist(extract(mapas, uma_buffer, fun = mean, na.rm = TRUE)[, especies])

round(idoneidad_uma, 3)
binario_uma
round(idoneidad_buffer, 3)
```

- `extract(mapas, uma_vect)` obtiene la idoneidad de cada especie en la celda donde cae la UMA (~4.5 km de lado).
- `extract(binarios, uma_vect)` indica si esa celda es idónea según el umbral p10.
- `buffer(uma_vect, width = 5000)` crea un círculo de 5 km alrededor de la UMA, y `fun = mean` promedia la idoneidad de las celdas dentro de él. Así el resultado no depende de que el punto caiga justo en el borde de una celda.

### 6.3 Percentil respecto a las presencias

La idoneidad de 0 a 1 no es del todo comparable entre especies, porque cada modelo tiene su propia escala (por ejemplo, sus umbrales p10 van de 0.383 a 0.441). Para compararlas se calcula el **percentil**: el porcentaje de presencias de cada especie con una idoneidad igual o menor que la de la UMA.

```r
percentil_uma <- sapply(especies, function(sp) {
  pts <- presencias_maxent[gsub(" ", "_", presencias_maxent$species) == sp,
                           c("longitude", "latitude")]
  idoneidad_pts <- extract(mapas[[sp]], as.matrix(pts))[[sp]]
  mean(idoneidad_pts <= idoneidad_uma[sp], na.rm = TRUE) * 100
})

round(percentil_uma, 1)
```

- `gsub(" ", "_", ...)` convierte `Canis latrans` en `Canis_latrans`, para que coincida con el nombre del mapa.
- `pts` toma los puntos de presencia de cada especie (Paso 2).
- `extract(...)` obtiene la idoneidad del mapa en cada uno de esos puntos.
- `mean(idoneidad_pts <= idoneidad_uma[sp]) * 100` calcula qué porcentaje de esos puntos tiene una idoneidad igual o menor que la de la UMA.

Un percentil de 80 significa que la UMA es más idónea que el 80% de los sitios donde se ha registrado la especie (un sitio muy favorable); un percentil de 20, que es un sitio climáticamente marginal para ella.

### 6.4 Tabla final

Se junta todo en una tabla y se agrega la abundancia relativa publicada para la UMA (IAR; Plata-Pérez et al. 2024), solo como referencia.

```r
tabla_uma <- data.frame(
  especie = especies,
  idoneidad_uma = round(idoneidad_uma, 3),
  idoneidad_buffer_5km = round(idoneidad_buffer, 3),
  umbral_p10 = resumen_maxent$umbral_p10,
  uma_idonea = ifelse(as.logical(binario_uma), "Si", "No"),
  percentil_presencias = round(percentil_uma, 1)
)

iar <- data.frame(
  especie = c("Urocyon_cinereoargenteus", "Odocoileus_virginianus",
              "Canis_latrans", "Lynx_rufus", "Puma_concolor"),
  IAR = c(23.85, 7.22, 3.44, 2.34, 0.14)
)

tabla_uma <- merge(tabla_uma, iar, by = "especie")
tabla_uma <- tabla_uma[order(-tabla_uma$IAR), ]

tabla_uma

write.csv(tabla_uma, "results/tables/03_idoneidad_uma.csv", row.names = FALSE)
```

- `ifelse(...)` convierte `TRUE`/`FALSE` en "Si"/"No".
- `merge(..., by = "especie")` une la tabla con el IAR por el nombre de la especie.
- `order(-tabla_uma$IAR)` ordena de mayor a menor abundancia.

**Resultado**

| Especie | IAR (%) | Idoneidad (celda) | Idoneidad (5 km) | Umbral p10 | ¿Idónea? | Percentil |
|---|---|---|---|---|---|---|
| *U. cinereoargenteus* | 23.85 | 0.659 | 0.649 | 0.397 | Sí | 47.8 |
| *O. virginianus* | 7.22 | 0.610 | 0.568 | 0.426 | Sí | 22.0 |
| *C. latrans* | 3.44 | 0.616 | 0.612 | 0.416 | Sí | 35.0 |
| *L. rufus* | 2.34 | 0.570 | 0.562 | 0.441 | Sí | 27.5 |
| *P. concolor* | 0.14 | 0.530 | 0.504 | 0.383 | Sí | 15.8 |

- La UMA es idónea para las cinco especies, como se esperaba, porque todas fueron registradas ahí por fototrampeo.
- La idoneidad en la celda y en el radio de 5 km es casi igual (diferencias ≤ 0.04), así que el resultado no depende de la ubicación exacta del punto.
- Todos los percentiles están por debajo de 50: para ninguna especie la UMA está entre sus sitios climáticamente más favorables.

**Salida:** `results/tables/03_idoneidad_uma.csv`.

**Decisión**

Como entre el 56% y el 74% de México es idóneo para cada especie (Paso 5.3), que la UMA sea idónea dice poco por sí solo. La comparación entre especies se basa en el **percentil**.

La UMA resulta un sitio climáticamente típico para *U. cinereoargenteus* (percentil 47.8), poco favorable para *C. latrans*, *L. rufus* y *O. virginianus* (22.0–35.0) y marginal para *P. concolor* (15.8). Que ningún percentil supere 50 es coherente con el carácter semiárido y de transición de la zona (selva baja caducifolia y matorral xerófilo), donde ninguna de las cinco especies tiene el centro de su nicho climático. La marcada estacionalidad de las lluvias en la UMA (Plata-Pérez et al. 2024) coincide además con la preferencia de *U. cinereoargenteus* por lluvia muy estacional (BIO15; Paso 3.3).

De forma descriptiva, los extremos coinciden con la abundancia relativa publicada: la especie para la que la UMA es más típica (*U. cinereoargenteus*) es la más abundante, y aquella para la que es más marginal (*P. concolor*), la menos abundante. *O. virginianus* es la excepción: es la segunda especie más abundante aunque la UMA le resulta poco favorable climáticamente, lo que puede explicarse porque la UMA se maneja para el aprovechamiento del venado y su abundancia depende más del manejo que del clima.

Esta comparación es solo exploratoria: con cinco especies no es posible una prueba estadística, y los modelos de *C. latrans* y *U. cinereoargenteus* discriminan poco (Paso 4.2). Los percentiles se retoman en el objetivo 4, que evalúa la posición de la UMA en el espacio ambiental.

## Paso 6 - Proyectar la UMA en el espacio geográfico

Con los mapas del Paso 5 se evalúa qué tan idóneo es el clima de la UMA Santa Cruz Nuevo para cada especie, y cómo se compara con los sitios donde cada especie ha sido registrada en México.

### 6.1 Ubicación de la UMA

Las coordenadas se tomaron del área de estudio de Plata-Pérez et al. (2024): 18°17'44" N y 97°48'35" W, que en grados decimales son 18.2956 y −97.8097 (la longitud es negativa por estar al oeste).

```r
uma <- data.frame(
  sitio = "UMA Santa Cruz Nuevo",
  longitude = -97.8097,
  latitude = 18.2956
)

uma_vect <- vect(uma, geom = c("longitude", "latitude"), crs = "EPSG:4326")

uma_vect
```

- `uma` guarda las coordenadas en una tabla, con los mismos nombres de columna que las presencias (`longitude`, `latitude`).
- `vect(...)` convierte la tabla en un punto con el sistema de coordenadas WGS 84, el mismo de los mapas.

### 6.2 Idoneidad en la UMA

```r
idoneidad_uma <- unlist(extract(mapas, uma_vect)[, especies])
binario_uma <- unlist(extract(binarios, uma_vect)[, especies])

uma_buffer <- buffer(uma_vect, width = 5000)
idoneidad_buffer <- unlist(extract(mapas, uma_buffer, fun = mean, na.rm = TRUE)[, especies])

round(idoneidad_uma, 3)
binario_uma
round(idoneidad_buffer, 3)
```

- `extract(mapas, uma_vect)` obtiene la idoneidad de cada especie en la celda donde cae la UMA (~4.5 km de lado).
- `extract(binarios, uma_vect)` indica si esa celda es idónea según el umbral p10.
- `buffer(uma_vect, width = 5000)` crea un círculo de 5 km alrededor de la UMA, y `fun = mean` promedia la idoneidad de las celdas dentro de él. Así el resultado no depende de que el punto caiga justo en el borde de una celda.

### 6.3 Percentil respecto a las presencias

La idoneidad de 0 a 1 no es del todo comparable entre especies, porque cada modelo tiene su propia escala (por ejemplo, sus umbrales p10 van de 0.383 a 0.441). Para compararlas se calcula el **percentil**: el porcentaje de presencias de cada especie con una idoneidad igual o menor que la de la UMA.

```r
percentil_uma <- sapply(especies, function(sp) {
  pts <- presencias_maxent[gsub(" ", "_", presencias_maxent$species) == sp,
                           c("longitude", "latitude")]
  idoneidad_pts <- extract(mapas[[sp]], as.matrix(pts))[[sp]]
  mean(idoneidad_pts <= idoneidad_uma[sp], na.rm = TRUE) * 100
})

round(percentil_uma, 1)
```

- `gsub(" ", "_", ...)` convierte `Canis latrans` en `Canis_latrans`, para que coincida con el nombre del mapa.
- `pts` toma los puntos de presencia de cada especie (Paso 2).
- `extract(...)` obtiene la idoneidad del mapa en cada uno de esos puntos.
- `mean(idoneidad_pts <= idoneidad_uma[sp]) * 100` calcula qué porcentaje de esos puntos tiene una idoneidad igual o menor que la de la UMA.

Un percentil de 80 significa que la UMA es más idónea que el 80% de los sitios donde se ha registrado la especie (un sitio muy favorable); un percentil de 20, que es un sitio climáticamente marginal para ella.

### 6.4 Tabla final

Se junta todo en una tabla y se agrega la abundancia relativa publicada para la UMA (IAR; Plata-Pérez et al. 2024), solo como referencia.

```r
tabla_uma <- data.frame(
  especie = especies,
  idoneidad_uma = round(idoneidad_uma, 3),
  idoneidad_buffer_5km = round(idoneidad_buffer, 3),
  umbral_p10 = resumen_maxent$umbral_p10,
  uma_idonea = ifelse(as.logical(binario_uma), "Si", "No"),
  percentil_presencias = round(percentil_uma, 1)
)

iar <- data.frame(
  especie = c("Urocyon_cinereoargenteus", "Odocoileus_virginianus",
              "Canis_latrans", "Lynx_rufus", "Puma_concolor"),
  IAR = c(23.85, 7.22, 3.44, 2.34, 0.14)
)

tabla_uma <- merge(tabla_uma, iar, by = "especie")
tabla_uma <- tabla_uma[order(-tabla_uma$IAR), ]

tabla_uma

write.csv(tabla_uma, "results/tables/03_idoneidad_uma.csv", row.names = FALSE)
```

- `ifelse(...)` convierte `TRUE`/`FALSE` en "Si"/"No".
- `merge(..., by = "especie")` une la tabla con el IAR por el nombre de la especie.
- `order(-tabla_uma$IAR)` ordena de mayor a menor abundancia.

**Resultado**

| Especie | IAR (%) | Idoneidad (celda) | Idoneidad (5 km) | Umbral p10 | ¿Idónea? | Percentil |
|---|---|---|---|---|---|---|
| *U. cinereoargenteus* | 23.85 | 0.659 | 0.649 | 0.397 | Sí | 47.8 |
| *O. virginianus* | 7.22 | 0.610 | 0.568 | 0.426 | Sí | 22.0 |
| *C. latrans* | 3.44 | 0.616 | 0.612 | 0.416 | Sí | 35.0 |
| *L. rufus* | 2.34 | 0.570 | 0.562 | 0.441 | Sí | 27.5 |
| *P. concolor* | 0.14 | 0.530 | 0.504 | 0.383 | Sí | 15.8 |

- La UMA es idónea para las cinco especies, como se esperaba, porque todas fueron registradas ahí por fototrampeo.
- La idoneidad en la celda y en el radio de 5 km es casi igual (diferencias ≤ 0.04), así que el resultado no depende de la ubicación exacta del punto.
- Todos los percentiles están por debajo de 50: para ninguna especie la UMA está entre sus sitios climáticamente más favorables.

**Salida:** `results/tables/03_idoneidad_uma.csv`.

**Decisión**

Como entre el 56% y el 74% de México es idóneo para cada especie (Paso 5.3), que la UMA sea idónea dice poco por sí solo. La comparación entre especies se basa en el **percentil**.

La UMA resulta un sitio climáticamente típico para *U. cinereoargenteus* (percentil 47.8), poco favorable para *C. latrans*, *L. rufus* y *O. virginianus* (22.0–35.0) y marginal para *P. concolor* (15.8). Que ningún percentil supere 50 es coherente con el carácter semiárido y de transición de la zona (selva baja caducifolia y matorral xerófilo), donde ninguna de las cinco especies tiene el centro de su nicho climático. La marcada estacionalidad de las lluvias en la UMA (Plata-Pérez et al. 2024) coincide además con la preferencia de *U. cinereoargenteus* por lluvia muy estacional (BIO15; Paso 3.3).

De forma descriptiva, los extremos coinciden con la abundancia relativa publicada: la especie para la que la UMA es más típica (*U. cinereoargenteus*) es la más abundante, y aquella para la que es más marginal (*P. concolor*), la menos abundante. *O. virginianus* es la excepción: es la segunda especie más abundante aunque la UMA le resulta poco favorable climáticamente, lo que puede explicarse porque la UMA se maneja para el aprovechamiento del venado y su abundancia depende más del manejo que del clima.

Esta comparación es solo exploratoria: con cinco especies no es posible una prueba estadística, y los modelos de *C. latrans* y *U. cinereoargenteus* discriminan poco (Paso 4.2). Los percentiles se retoman en el objetivo 4, que evalúa la posición de la UMA en el espacio ambiental.

## Paso 7 - Figuras

Se generan dos figuras de cinco paneles (uno por especie), con la UMA marcada en naranja. Los mapas se convierten a tabla larga con `melt()`, igual que el heatmap del objetivo 2, y el contorno de México se dibuja a partir de `geom(mexico)`.

```r
mexico_lineas <- as.data.frame(geom(mexico))
mexico_lineas$grupo <- paste(mexico_lineas$geom, mexico_lineas$part, mexico_lineas$hole)
```

- `geom(mexico)` extrae las coordenadas de los bordes de cada estado.
- `grupo` identifica cada polígono, para que `ggplot()` no una con líneas los bordes de estados distintos.

### 7.1 Mapas de idoneidad

```r
melted_mapas <- melt(
  as.data.frame(mapas, xy = TRUE, na.rm = TRUE),
  id.vars = c("x", "y"),
  variable.name = "especie",
  value.name = "idoneidad"
)
melted_mapas$especie <- gsub("_", " ", melted_mapas$especie)

fig_idoneidad <- ggplot() +
  geom_raster(data = melted_mapas, aes(x, y, fill = idoneidad)) +
  geom_path(data = mexico_lineas, aes(x, y, group = grupo),
            color = "grey40", linewidth = 0.1) +
  geom_point(data = uma, aes(longitude, latitude),
             shape = 21, fill = "#e6550d", color = "black", size = 2) +
  scale_fill_gradient(low = "#f7fbff", high = "#084594", limits = c(0, 1),
                      name = "Idoneidad\n(cloglog)") +
  facet_wrap(~ especie, ncol = 3) +
  coord_fixed() +
  labs(x = "Longitud", y = "Latitud") +
  theme_minimal() +
  theme(strip.text = element_text(face = "italic"))

print(fig_idoneidad)

ggsave("results/figures/03_mapas_idoneidad.png", plot = fig_idoneidad,
       width = 10, height = 6, dpi = 300)
```

- `geom_raster()` dibuja la idoneidad de cada celda.
- `geom_path()` dibuja los bordes estatales.
- `geom_point()` marca la UMA.
- `facet_wrap(~ especie)` hace un panel por especie.
- `coord_fixed()` mantiene la misma escala en ambos ejes, para que México no se vea deformado.

### 7.2 Mapas binarios

Mismo procedimiento con los mapas del Paso 5.2. Los valores `TRUE`/`FALSE` se convierten en las categorías "Idoneo" y "No idoneo" con `factor()`.

```r
melted_binarios <- melt(
  as.data.frame(binarios, xy = TRUE, na.rm = TRUE),
  id.vars = c("x", "y"),
  variable.name = "especie",
  value.name = "idoneo"
)
melted_binarios$especie <- gsub("_", " ", melted_binarios$especie)
melted_binarios$idoneo <- factor(as.logical(melted_binarios$idoneo),
                                 levels = c(FALSE, TRUE),
                                 labels = c("No idoneo", "Idoneo"))

fig_binarios <- ggplot() +
  geom_raster(data = melted_binarios, aes(x, y, fill = idoneo)) +
  geom_path(data = mexico_lineas, aes(x, y, group = grupo),
            color = "grey40", linewidth = 0.1) +
  geom_point(data = uma, aes(longitude, latitude),
             shape = 21, fill = "#e6550d", color = "black", size = 2) +
  scale_fill_manual(values = c("No idoneo" = "#deebf7", "Idoneo" = "#084594"),
                    name = "Umbral p10") +
  facet_wrap(~ especie, ncol = 3) +
  coord_fixed() +
  labs(x = "Longitud", y = "Latitud") +
  theme_minimal() +
  theme(strip.text = element_text(face = "italic"))

print(fig_binarios)

ggsave("results/figures/03_mapas_binarios.png", plot = fig_binarios,
       width = 10, height = 6, dpi = 300)
```

**Resultado**

`03_mapas_idoneidad.png` muestra la idoneidad continua de cada especie y `03_mapas_binarios.png`, la clasificación idóneo/no idóneo con el umbral p10. En ambas figuras la UMA aparece en el sur de Puebla y cae en zona idónea para las cinco especies.

**Salidas:** `results/figures/03_mapas_idoneidad.png` y `results/figures/03_mapas_binarios.png`.
