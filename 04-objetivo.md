# Objetivo 4 - Posición y amplitud del nicho climático, y posición de la UMA

Con las presencias (objetivo 1), las cinco variables (objetivo 2) y los modelos de Maxent (objetivo 3), este objetivo pasa del espacio geográfico al **espacio ambiental** (dualidad de Hutchinson, V) para responder:

**¿Qué posición y qué amplitud tiene el nicho climático de cada especie, y qué tan cerca del centro de su nicho queda el clima de la UMA?**

Se sigue la Práctica 2.1 de V (análisis OMI, *Outlying Mean Index*; Dolédec et al. 2000), que calcula para cada especie:

| Parámetro | Qué mide |
|---|---|
| **OMI** (posición) | Qué tan lejos está el clima promedio que usa la especie del clima promedio de toda el área de estudio. Valores altos = nicho **marginal**; valores bajos = nicho **central** (condiciones comunes) |
| **Tol** (amplitud) | Qué tan variado es el clima que ocupa la especie. Valores altos = **generalista** (nicho amplio); valores bajos = **especialista** (nicho estrecho) |

Con estos parámetros se exploran, de forma descriptiva, dos hipótesis vistas con V sobre la abundancia. La hipótesis de la amplitud del nicho (Brown, 1984) espera mayor abundancia en especies generalistas. La hipótesis de la posición del nicho o de disponibilidad de hábitat (Venier y Fahrig, 1996) la espera en especies de nicho central. No es una prueba estadística: con cinco especies solo se revisa si el patrón va en la dirección que predice cada una. La abundancia es el IAR publicado por Plata-Pérez et al. (2024).

En el objetivo 3 se midió la idoneidad del clima de la UMA en el espacio geográfico; aquí se mide su posición en el espacio ambiental. Son preguntas relacionadas pero distintas: Maxent estima una idoneidad relativa a todo México, con una escala propia para cada especie, mientras que este objetivo mide a todas las especies en el mismo espacio ambiental y describe qué tan típico es el clima de la UMA para el nicho de cada una.

## Flujo de trabajo

| Paso | Qué se hace | Dónde | Origen en el curso |
|---|---|---|---|
| 0 | Preparar paquetes (`ade4`) | R | Práctica 2.1 (V) |
| 1 | Cargar variables, capas `.asc` y presencias | R | Objetivos 2 y 3 |
| 2 | Sitios y tabla de especies | R | Práctica 2.1, base `drome` (V) |
| 3 | PCA del ambiente | R | Práctica 2.1 (V) y PCA del objetivo 2 (Q) |
| 4 | Posición (OMI) y amplitud (Tol) de cada especie | R | Práctica 2.1 (V) |
| 5 | Posición de la UMA en el espacio de la PCA | R | Paso propio (ver nota) |
| 6 | Posición, amplitud y abundancia relativa | R | Hipótesis de V; Spearman (Q) |
| 7 | Figuras | R | Práctica 2.1 (V) |

## Paso 0 - Preparar el ambiente

```r
if (!require("terra")) install.packages("terra")
if (!require("ade4")) install.packages("ade4")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("ggrepel")) install.packages("ggrepel")

library(terra)
library(ade4)
library(ggplot2)
library(ggrepel)

dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)
```

- `ade4` es el paquete que usa la práctica de V para el análisis OMI.
- `ggrepel` separa las etiquetas de la figura para que no se encimen (es el mismo que usa `repel = TRUE` en el biplot del objetivo 2).

## Paso 1 - Cargar los insumos de los objetivos 2 y 3

### 1.1 Variables

```r
variables_seleccionadas <- read.csv("results/tables/02_variables_seleccionadas.csv")$variable

variables_seleccionadas
```

### 1.2 Capas climáticas

Se usan los `.asc` que se exportaron para Maxent (objetivo 3, paso 1.3). Así el análisis usa la misma rejilla y el mismo recorte a México que los modelos.

```r
archivos_asc <- file.path("../04-maxent/capas_asc",
                          paste0(variables_seleccionadas, ".asc"))

file.exists(archivos_asc)   # deben ser 5 TRUE

capas <- rast(archivos_asc)
names(capas) <- variables_seleccionadas
crs(capas) <- "EPSG:4326"

capas
```

- `paste0(variables_seleccionadas, ".asc")` arma el nombre de cada archivo en el orden de las variables.
- `rast()` carga las cinco capas en un solo objeto.
- `crs()` asigna WGS 84, porque los `.asc` no guardan el sistema de coordenadas.

**Resultado**

`capas`: 5 capas (BIO5, BIO6, BIO12, BIO15, BIO17), 436 × 760 celdas, resolución 0.0417° y WGS 84, con los mismos rangos de valores del objetivo 3 (por ejemplo, BIO5 de 12.0 a 42.8 °C y BIO12 de 45 a 4,655 mm).

### 1.3 Presencias

```r
presencias <- read.csv("../04-maxent/presence/presencias_5spp.csv")

presencias$species <- gsub(" ", "_", presencias$species)

especies <- sort(unique(presencias$species))

especies
nrow(presencias)
```

- Se usa el mismo archivo que Maxent, para que el análisis se base exactamente en los mismos datos.
- `gsub(" ", "_", ...)` pone los nombres con guion bajo, igual que los archivos de Maxent y la tabla de IAR.

**Resultado**

Las cinco especies (*Canis latrans*, *Lynx rufus*, *Odocoileus virginianus*, *Puma concolor* y *Urocyon cinereoargenteus*) y 7,947 registros, los mismos del objetivo 3.

## Paso 2 - Sitios y tabla de especies

La práctica de V usa la base `drome`, que tiene dos tablas con las mismas filas: `drome$env` (las variables ambientales de cada sitio) y `drome$fish` (la abundancia de cada especie en cada sitio). Aquí se arman las dos equivalentes:

| Práctica de V | Este análisis |
|---|---|
| Sitio (localidad de muestreo) | Celda de México (~4.5 km) |
| `drome$env` | Las 5 variables climáticas de cada celda |
| `drome$fish` | 1 si hay un registro de la especie en la celda, 0 si no |

### 2.1 Una presencia por celda

Maxent usa una presencia por celda (objetivo 3, paso 2.3). Se hace lo mismo aquí.

```r
presencias$celda <- cellFromXY(
  capas,
  as.matrix(presencias[, c("longitude", "latitude")])
)

presencias_u <- presencias[!duplicated(presencias[, c("species", "celda")]), ]

table(presencias_u$species)
```

**Resultado**

| Especie | Celdas únicas |
|---|---|
| *C. latrans* | 1,060 |
| *L. rufus* | 541 |
| *O. virginianus* | 1,183 |
| *P. concolor* | 378 |
| *U. cinereoargenteus* | 1,203 |

**Decisión**

Las celdas únicas coinciden con las del objetivo 3, excepto *P. concolor*: 378 aquí y 377 en el objetivo 3. Es una sola celda de diferencia, probablemente de un registro justo en el borde de una celda, y no cambia el análisis de forma apreciable. En este objetivo se usa 378, que es el número calculado con las capas `.asc` que se leen aquí.

### 2.2 Sitios: las celdas de México

```r
sitios <- as.data.frame(capas, cells = TRUE, na.rm = TRUE)

nrow(sitios)

rownames(sitios) <- paste0("celda_", sitios$cell)

env_sitios <- sitios[, variables_seleccionadas]

head(env_sitios)
```

- `as.data.frame(..., cells = TRUE, na.rm = TRUE)` convierte las capas en una tabla con una fila por celda con dato y una columna `cell` con su número.
- Se usan **todas** las celdas de México, no una muestra: el OMI compara el clima de cada especie con el promedio del área de estudio, y ese promedio debe ser el de todo México (el área que usó Maxent).
- Los nombres de fila (`celda_…`) sirven para que las dos tablas queden alineadas, como en la práctica.

**Resultado**

102,316 celdas con dato, las mismas del objetivo 3. Las primeras filas son celdas desérticas del noroeste (BIO5 ≈ 41 °C, BIO12 ≈ 70 mm, BIO17 ≈ 3 mm).

### 2.3 Tabla de especies

```r
tabla_spp <- as.data.frame(sapply(especies, function(sp) {
  as.numeric(sitios$cell %in% presencias_u$celda[presencias_u$species == sp])
}))
rownames(tabla_spp) <- rownames(sitios)

colSums(tabla_spp)
head(tabla_spp)
```

- Para cada especie, marca con 1 las celdas donde hay un registro y con 0 las demás.
- `colSums()` debe dar las celdas únicas del paso 2.1.

> **Los 0 no son ausencias.** Una celda sin registro no significa que la especie no viva ahí. En el OMI, los sitios con 0 no pesan en el cálculo del centro del nicho de la especie (solo cuentan las celdas con presencia); su función es definir el clima disponible en México, contra el que se mide la posición.

**Resultado**

`colSums(tabla_spp)` da 1,060; 541; 1,183; 378 y 1,203, igual que las celdas únicas del paso 2.1: ninguna presencia quedó fuera de las celdas con dato. Casi toda la tabla son ceros, como se espera.

## Paso 3 - PCA del ambiente

```r
pca_mx <- dudi.pca(env_sitios, scale = TRUE, scannf = FALSE, nf = 5)

round(100 * pca_mx$eig / sum(pca_mx$eig), 1)

round(pca_mx$c1, 2)
```

- `dudi.pca()` es la versión de la PCA que usa `ade4`; `scale = TRUE` estandariza las variables (media 0 y DE 1), como en el objetivo 2.
- `nf = 5` conserva los cinco ejes, para que las distancias del paso 5 usen todo el espacio ambiental.
- `pca_mx$eig` guarda la varianza de cada eje y `pca_mx$c1` las cargas de las variables.

**Resultado**

Varianza explicada: 47.2%, 23.0%, 21.3%, 7.1% y 1.4% (los tres primeros ejes suman 91.5%).

| Variable | Eje 1 | Eje 2 | Eje 3 | Eje 4 | Eje 5 |
|---|---|---|---|---|---|
| BIO5 | −0.05 | **0.85** | 0.32 | 0.40 | 0.12 |
| BIO6 | −0.49 | 0.42 | −0.22 | −0.69 | −0.23 |
| BIO12 | −0.57 | −0.10 | −0.40 | 0.25 | 0.67 |
| BIO15 | 0.28 | 0.23 | **−0.82** | 0.31 | −0.32 |
| BIO17 | −0.59 | −0.22 | 0.15 | 0.45 | −0.62 |

**Decisión**

Cada uno de los tres primeros ejes corresponde a una dimensión distinta del clima, como se esperaba de las 5 variables elegidas en el objetivo 2:

- **Eje 1 (humedad):** BIO12, BIO17 y BIO6 tienen carga negativa. Valores bajos del eje = más lluvia anual y de la temporada seca e inviernos más templados; valores altos = clima árido.
- **Eje 2 (calor):** BIO5 (0.85) y BIO6 (0.42). Valores altos = veranos más calurosos.
- **Eje 3 (estacionalidad de la lluvia):** BIO15 (−0.82).

Las figuras del paso 7 muestran solo los ejes 1 y 2 (70.2% de la varianza), así que la estacionalidad de la lluvia (eje 3) no se ve en ellas; por eso las distancias del paso 5 usan los cinco ejes.

## Paso 4 - Posición y amplitud del nicho de cada especie

```r
niche_description <- niche(pca_mx, tabla_spp, scannf = FALSE)

niche_description$nf

params <- niche.param(niche_description)

colnames(params)

round(params, 2)

write.csv(round(params, 3), "results/tables/04_parametros_nicho.csv")
```

- `niche()` calcula, para cada especie, el centro de su nicho: el promedio del clima de las celdas donde se registró.
- `niche.param()` entrega los parámetros de cada especie. Con mayúscula son los valores absolutos (`OMI`, `Tol`, `Rtol`) e `inertia`, la variabilidad total; con minúscula (`omi`, `tol`, `rtol`) son los mismos valores como porcentaje de la inercia.
- `niche_description$nf` muestra cuántos ejes conserva `niche()`: **2**, el valor predeterminado, que es el que usa la práctica de V. `Tol` mide la dispersión de la especie en esos 2 ejes, y `Rtol` (tolerancia residual) la dispersión en el resto.

**Resultado**

| Especie | OMI | Tol | Rtol | Inercia | OMI % | Tol % | Rtol % |
|---|---|---|---|---|---|---|---|
| *C. latrans* | 0.33 | 1.21 | 2.97 | 4.50 | 7.4 | 26.8 | 65.9 |
| *L. rufus* | **0.67** | **0.80** | 2.82 | 4.29 | 15.5 | 18.7 | 65.7 |
| *O. virginianus* | 0.30 | 1.52 | 4.00 | 5.81 | 5.1 | 26.1 | 68.8 |
| *P. concolor* | **0.65** | **2.66** | 3.50 | 6.81 | 9.5 | 39.1 | 51.4 |
| *U. cinereoargenteus* | **0.20** | 1.20 | 3.81 | 5.21 | 3.9 | 23.1 | 73.0 |

**Salida:** `results/tables/04_parametros_nicho.csv`.

**Decisión**

Se responden las preguntas de la práctica de V:

- **Posición:** *U. cinereoargenteus* (0.20), *O. virginianus* (0.30) y *C. latrans* (0.33) tienen nichos centrales, con clima parecido al promedio de México. *L. rufus* (0.67) y *P. concolor* (0.65) son claramente marginales y se comportan distinto al resto.
- **Amplitud:** *L. rufus* es la especie más especialista (Tol 0.80) y *P. concolor* la más generalista (2.66); *O. virginianus* queda en segundo lugar (1.52). *C. latrans* y *U. cinereoargenteus* son casi iguales (1.21 y 1.20), por lo que no se interpreta su diferencia.
- Esto es coherente con las curvas de respuesta del objetivo 3: *L. rufus*, con la idoneidad más restringida a climas secos y templados, es la más especialista.

Como `Tol` solo usa 2 ejes, la dispersión total de cada especie es `Tol + Rtol`. Con esa medida los extremos no cambian (*L. rufus* la más estrecha, 3.62; *P. concolor* la más amplia, 6.16), pero *U. cinereoargenteus* (5.01) pasa por encima de *C. latrans* (4.18). Se mantiene `Tol`.

## Paso 5 - Posición de la UMA en el espacio de la PCA

Este es el único paso que no está en la práctica de V. La práctica ubica a las especies en el espacio ambiental; aquí se ubica además a la UMA en **ese mismo espacio**, como un punto más, para medir qué tan lejos queda del centro del nicho de cada especie.

### 5.1 Clima de la UMA

Mismas coordenadas del objetivo 3 (Plata-Pérez et al. 2024: 18°17'44" N y 97°48'35" W; confirmadas en la sección de área de estudio del artículo).

```r
uma <- data.frame(
  sitio = "UMA Santa Cruz Nuevo",
  longitude = -97.8097,
  latitude = 18.2956
)

uma_vect <- vect(uma, geom = c("longitude", "latitude"), crs = "EPSG:4326")

clima_uma <- extract(capas, uma_vect)[, variables_seleccionadas]

clima_uma_buffer <- extract(
  capas, buffer(uma_vect, width = 5000),
  fun = mean, na.rm = TRUE
)[, variables_seleccionadas]

clima_uma_tabla <- rbind(
  data.frame(medida = "celda", round(clima_uma, 1)),
  data.frame(medida = "buffer_5km", round(clima_uma_buffer, 1))
)

clima_uma_tabla

write.csv(clima_uma_tabla, "results/tables/04_clima_uma.csv", row.names = FALSE)
```

- Se calcula igual que en el objetivo 3 (celda de ~4.5 km y promedio en 5 km), para comprobar que el resultado no depende de la ubicación exacta del punto.

**Resultado**

| Medida | BIO5 (°C) | BIO6 (°C) | BIO12 (mm) | BIO15 | BIO17 (mm) |
|---|---|---|---|---|---|
| Celda | 31.4 | 10.6 | 494 | 97.9 | 12.0 |
| Radio de 5 km | 31.8 | 10.7 | 469 | 97.7 | 11.8 |

**Salida:** `results/tables/04_clima_uma.csv`.

**Decisión**

La celda y el radio de 5 km tienen un clima casi igual, así que el resultado no depende de la ubicación exacta del punto. El clima de la UMA es cálido (BIO5 ≈ 31 °C), con invierno templado (BIO6 ≈ 11 °C), poca lluvia anual (~480 mm) y una estación seca muy marcada (BIO17 ≈ 12 mm), lo que concuerda con su carácter semiárido.

### 5.2 Proyectar la UMA en la PCA

```r
uma_pca <- as.numeric(suprow(pca_mx, clima_uma)$lisup)
uma_buffer_pca <- as.numeric(suprow(pca_mx, clima_uma_buffer)$lisup)

round(uma_pca, 2)
```

- `suprow()` calcula las coordenadas de un sitio **adicional** en la PCA ya hecha, usando el mismo centrado y la misma escala. Así la UMA no influye en el análisis; solo se ubica en él.

**Resultado**

Coordenadas de la UMA en los 5 ejes: 0.48, 0.12, −0.60, −0.83 y −0.32.

### 5.3 Centro del nicho de cada especie

```r
pesos <- sweep(as.matrix(tabla_spp), 2, colSums(tabla_spp), "/")

centroides_pca <- t(pesos) %*% as.matrix(pca_mx$li)

round(centroides_pca, 2)

round(rowSums(centroides_pca^2), 2)
round(params[, "OMI"], 2)
```

- `sweep(..., "/")` divide cada columna entre su suma, para que cada especie sume 1; así `t(pesos) %*% pca_mx$li` es el promedio de las coordenadas de las celdas donde hay registros, es decir, el centro de su nicho.
- Las dos últimas líneas son una **comprobación**: la distancia al cuadrado de cada centro al origen de la PCA debe coincidir con el OMI que calculó `niche.param()` (el origen es el clima promedio de México).

**Resultado**

Centro del nicho en los dos primeros ejes:

| Especie | Eje 1 | Eje 2 |
|---|---|---|
| *C. latrans* | 0.45 | −0.32 |
| *L. rufus* | 0.66 | −0.48 |
| *O. virginianus* | −0.39 | −0.30 |
| *P. concolor* | −0.65 | −0.42 |
| *U. cinereoargenteus* | −0.28 | −0.18 |

La comprobación coincide exactamente: `rowSums(centroides_pca^2)` da 0.33, 0.67, 0.30, 0.65 y 0.20, igual que el OMI del paso 4.

**Decisión**

El cálculo del centro del nicho es correcto y el espacio de la PCA es el mismo del análisis OMI, por lo que las distancias del paso 5.4 son comparables con el OMI. En el Eje 1, *C. latrans* y *L. rufus* se ubican del lado seco y *P. concolor* y *O. virginianus* del lado húmedo.

### 5.4 Distancia de la UMA al centro de cada especie

```r
posicion <- do.call(rbind, lapply(especies, function(sp) {
  centro <- centroides_pca[sp, ]
  li_sp <- as.matrix(pca_mx$li[tabla_spp[[sp]] == 1, ])

  d_registros <- sqrt(rowSums(sweep(li_sp, 2, centro)^2))
  d_uma <- sqrt(sum((uma_pca - centro)^2))
  d_buffer <- sqrt(sum((uma_buffer_pca - centro)^2))
  d_p95 <- unname(quantile(d_registros, 0.95))

  data.frame(
    especie = sp,
    celdas_unicas = nrow(li_sp),
    d_uma = d_uma,
    d_buffer_5km = d_buffer,
    d_mediana_registros = median(d_registros),
    d_p95_registros = d_p95,
    percentil_uma = mean(d_registros <= d_uma) * 100,
    uma_dentro_95 = ifelse(d_uma <= d_p95, "Si", "No")
  )
}))

posicion[, -1] <- lapply(posicion[, -1], function(x) {
  if (is.numeric(x)) round(x, 2) else x
})

posicion

write.csv(posicion, "results/tables/04_posicion_uma.csv", row.names = FALSE)
```

- Las distancias son **euclidianas** en el espacio de la PCA con los 5 ejes. Equivalen a la distancia entre el clima de la UMA y el clima promedio de la especie, en unidades de desviación estándar del clima de México.
- `d_mediana_registros` es la distancia de un registro típico de la especie a su propio centro; sirve para ver si la UMA está más cerca o más lejos que un registro típico.
- `d_p95_registros` es la distancia por debajo de la cual queda el 95% de los registros de la especie.
- `percentil_uma` es el porcentaje de registros de la especie que están más cerca del centro que la UMA. Un valor de 50 significa que la UMA está tan lejos del centro como el registro mediano; cerca de 100, que es marginal.
- `uma_dentro_95` indica si la UMA queda dentro del 95% de los registros (es decir, `percentil_uma` de 95 o menos).

**Resultado**

| Especie | Celdas únicas | Distancia UMA | Distancia 5 km | Mediana de registros | P95 de registros | Percentil UMA | ¿Dentro del 95%? |
|---|---|---|---|---|---|---|---|
| *C. latrans* | 1,060 | 1.12 | 1.13 | 1.68 | 3.26 | 10.75 | Sí |
| *L. rufus* | 541 | 1.17 | 1.19 | 1.70 | 3.05 | 21.26 | Sí |
| *O. virginianus* | 1,183 | 1.30 | 1.32 | 2.06 | 3.59 | 9.30 | Sí |
| *P. concolor* | 378 | 1.56 | 1.59 | 2.15 | 4.55 | 16.40 | Sí |
| *U. cinereoargenteus* | 1,203 | 1.12 | 1.14 | 1.97 | 3.26 | 6.82 | Sí |

**Salida:** `results/tables/04_posicion_uma.csv`.

**Decisión**

La UMA queda dentro del 95% de los registros de las cinco especies, y más cerca del centro del nicho que entre el 79% y el 93% de sus registros (percentil de 7 a 21). Su distancia al centro es menor que la distancia mediana de los registros en todos los casos, y casi no cambia entre la celda y el radio de 5 km (diferencias de 0.01 a 0.03).

Este resultado es esperable, porque las cinco especies se eligieron justamente por haberse registrado en la UMA; la información útil es el **orden** entre especies. Para ordenarlas se usa el **percentil** y no la distancia: la distancia está en unidades absolutas, así que una especie de nicho amplio como *P. concolor* tiene distancias grandes aun en su centro, mientras que el percentil la compara con la dispersión de cada especie.

## Paso 6 - Posición, amplitud y abundancia relativa

### 6.1 Tabla final

```r
iar <- data.frame(
  especie = c("Urocyon_cinereoargenteus", "Odocoileus_virginianus",
              "Canis_latrans", "Lynx_rufus", "Puma_concolor"),
  IAR = c(23.85, 7.22, 3.44, 2.34, 0.14)
)

tabla_nicho <- data.frame(
  especie = especies,
  OMI = round(params[especies, "OMI"], 2),
  Tol = round(params[especies, "Tol"], 2)
)

tabla_nicho <- merge(tabla_nicho, posicion[, c("especie", "d_uma", "percentil_uma",
                                               "uma_dentro_95")], by = "especie")
tabla_nicho <- merge(tabla_nicho, iar, by = "especie")
tabla_nicho <- tabla_nicho[order(-tabla_nicho$IAR), ]

tabla_nicho

write.csv(tabla_nicho, "results/tables/04_nicho_vs_iar.csv", row.names = FALSE)
```

### 6.2 Correlaciones de Spearman con el IAR

```r
cor(tabla_nicho$OMI, tabla_nicho$IAR, method = "spearman")
cor(tabla_nicho$Tol, tabla_nicho$IAR, method = "spearman")
cor(tabla_nicho$d_uma, tabla_nicho$IAR, method = "spearman")
cor(tabla_nicho$percentil_uma, tabla_nicho$IAR, method = "spearman")
```

| Correlación | Hipótesis (V) | Se esperaría |
|---|---|---|
| OMI con IAR | Posición del nicho: las especies de nicho central son más abundantes | Negativa |
| Tol con IAR | Amplitud del nicho: las especies generalistas son más abundantes | Positiva |
| Distancia o percentil de la UMA con IAR | Una UMA más cerca del centro del nicho favorece la abundancia local | Negativa |

- Con 5 especies, las correlaciones son solo descriptivas: no se interpretan como prueba estadística.

**Resultado**

| Especie | IAR (%) | OMI | Tol | Distancia UMA | Percentil UMA |
|---|---|---|---|---|---|
| *U. cinereoargenteus* | 23.85 | 0.20 | 1.20 | 1.12 | 6.82 |
| *O. virginianus* | 7.22 | 0.30 | 1.52 | 1.30 | 9.30 |
| *C. latrans* | 3.44 | 0.33 | 1.21 | 1.12 | 10.75 |
| *L. rufus* | 2.34 | 0.67 | 0.80 | 1.17 | 21.26 |
| *P. concolor* | 0.14 | 0.65 | 2.66 | 1.56 | 16.40 |

| Correlación de Spearman con el IAR | ρ |
|---|---|
| OMI | −0.90 |
| Tol | −0.30 |
| Distancia de la UMA | −0.62 |
| Percentil de la UMA | −0.90 |

**Salida:** `results/tables/04_nicho_vs_iar.csv`.

**Decisión**

Decisión

Posición: el orden de las especies por OMI y por percentil de la UMA es el mismo (de más central a más marginal: U. cinereoargenteus, O. virginianus, C. latrans, P. concolor, L. rufus) y coincide casi por completo con el orden del IAR; solo se intercambian L. rufus y P. concolor. Las correlaciones son negativas (−0.90), en la dirección que predice la hipótesis de la posición del nicho. OMI y percentil ordenan igual a las especies, así que son un solo resultado medido de dos formas, no dos confirmaciones independientes.
Amplitud: la amplitud no acompaña a la abundancia. La hipótesis de Brown esperaría que las especies más generalistas fueran las más abundantes, pero P. concolor es la más generalista (Tol 2.66) y la menos abundante, y U. cinereoargenteus, la más abundante, tiene una amplitud intermedia. Por eso la correlación es débil y en dirección contraria a la predicha (ρ = −0.30), y estos datos no apoyan la hipótesis de la amplitud del nicho. Este resultado depende casi solo del puma: sin él, la correlación de las otras cuatro especies sería positiva (ρ = 0.40), aunque con cuatro especies eso no tiene peso. Además, el IAR del puma (0.14%) viene de solo 2 registros, y un depredador tope suele vivir en densidades bajas por sus requerimientos de presas y territorio, aunque tolere muchos climas; esto último es una explicación posible que este proyecto no pone a prueba.
Con 5 especies, ni una correlación de −0.90 alcanza significancia (p = 0.083), así que el resultado es un patrón descriptivo y no una prueba de las hipótesis.

## Paso 7 - Figuras

### 7.1 Espacio del nicho

Como en la práctica de V, las flechas son las variables ambientales y los puntos azules son los centros del nicho de cada especie, con tamaño proporcional a la tolerancia. Se agregan las celdas de México (fondo gris) y la UMA (naranja).

```r
set.seed(123)
fondo_pc <- as.data.frame(pca_mx$li[sample(nrow(sitios), 10000), 1:2])
colnames(fondo_pc) <- c("Axis1", "Axis2")

vars_coords <- as.data.frame(pca_mx$c1[, 1:2])
colnames(vars_coords) <- c("CS1", "CS2")

species_plot <- data.frame(
  Axis1 = centroides_pca[especies, 1],
  Axis2 = centroides_pca[especies, 2],
  Tol = params[especies, "Tol"],
  especie = gsub("_", " ", especies)
)

uma_plot <- data.frame(Axis1 = uma_pca[1], Axis2 = uma_pca[2])

varianza_pc <- round(100 * pca_mx$eig / sum(pca_mx$eig), 1)

fig_nicho <- ggplot() +
  geom_point(data = fondo_pc, aes(Axis1, Axis2), color = "grey88", size = 0.3) +
  geom_segment(data = vars_coords,
               aes(x = 0, y = 0, xend = CS1 * 3, yend = CS2 * 3),
               arrow = arrow(length = unit(0.2, "cm")), color = "red") +
  geom_text(data = vars_coords,
            aes(x = CS1 * 3.3, y = CS2 * 3.3, label = rownames(vars_coords)),
            color = "red", fontface = "bold", size = 3.5) +
  geom_point(data = species_plot, aes(Axis1, Axis2, size = Tol),
             color = "#084594", alpha = 0.8) +
  geom_text_repel(data = species_plot, aes(Axis1, Axis2, label = especie),
                  fontface = "italic", color = "#084594", size = 3.5,
                  box.padding = 0.8, min.segment.length = 0) +
  geom_point(data = uma_plot, aes(Axis1, Axis2),
             shape = 21, fill = "#e6550d", color = "black", size = 3.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray") +
  scale_size_continuous(name = "Tolerancia") +
  coord_fixed(xlim = c(-2.6, 2), ylim = c(-1.5, 3)) +
  labs(x = paste0("Eje 1 (", varianza_pc[1], "%)"),
       y = paste0("Eje 2 (", varianza_pc[2], "%)")) +
  theme_minimal()

ggsave("results/figures/04_nicho_omi.png", plot = fig_nicho,
       width = 9, height = 7, dpi = 300)
```

- El origen (0, 0) es el clima promedio de México; cuanto más lejos del origen está una especie, mayor es su OMI.
- `geom_text_repel()` separa las etiquetas de las especies, que quedan muy juntas cerca del origen.
- `coord_fixed(xlim, ylim)` acerca el encuadre a donde están las especies; el fondo gris se extiende más allá de ese encuadre (celdas muy húmedas o muy cálidas que no se ven en la figura).
- Solo se muestran los dos primeros ejes; las distancias del paso 5 usan los cinco.

### 7.2 Distancia de la UMA al centro del nicho

```r
distancias <- merge(posicion, iar, by = "especie")
distancias <- distancias[order(-distancias$IAR), ]
distancias$especie <- factor(gsub("_", " ", distancias$especie),
                             levels = gsub("_", " ", distancias$especie))

fig_distancias <- ggplot(distancias, aes(x = especie)) +
  geom_col(aes(y = d_uma), fill = "#e6550d", width = 0.6) +
  geom_point(aes(y = d_p95_registros), shape = 18, size = 4) +
  labs(x = NULL, y = "Distancia al centro del nicho (espacio de la PCA)") +
  theme_minimal() +
  theme(axis.text.x = element_text(face = "italic", angle = 20, hjust = 1))

ggsave("results/figures/04_distancia_uma.png", plot = fig_distancias,
       width = 8, height = 5, dpi = 300)
```

- Las especies se ordenan de mayor a menor IAR. La barra es la distancia de la UMA al centro del nicho y el rombo, el límite del 95% de los registros de esa especie: si la barra queda por debajo del rombo, la UMA está dentro del 95% de los registros.

Resultado

04_nicho_omi.png: los centros del nicho de las cinco especies quedan agrupados cerca del origen, en una zona pequeña del espacio climático de México. C. latrans y L. rufus quedan hacia el lado seco del Eje 1 (derecha), P. concolor y O. virginianus hacia el lado húmedo (izquierda), y U. cinereoargenteus es la más cercana al origen. P. concolor tiene el punto más grande (mayor tolerancia) y L. rufus el más pequeño. La UMA (naranja, sin etiqueta) queda a la derecha del origen, justo encima de C. latrans (misma posición en el Eje 1, algo más cálida en el Eje 2). Las flechas muestran las tres dimensiones del paso 3: BIO12 y BIO17 apuntan a la izquierda (húmedo), BIO5 hacia arriba (calor) y BIO15 hacia la derecha.

04_distancia_uma.png: en las cinco especies la barra queda muy por debajo del rombo (distancia de la UMA entre 1.12 y 1.56; límite del 95% entre 3.05 y 4.55). P. concolor tiene la barra más alta y el rombo más alto; L. rufus, el rombo más bajo.

Salidas: results/figures/04_nicho_omi.png y results/figures/04_distancia_uma.png.

Decisión
La UMA ocupa una posición central en el nicho climático de las cinco especies: queda dentro del 95% de sus registros y más cerca del centro que el 79% al 93% de ellos. Es esperable, porque las especies se eligieron por haberse registrado ahí.
La posición del nicho sigue el orden del IAR (ρ = −0.90 para OMI y para el percentil de la UMA), salvo el cambio entre L. rufus y P. concolor. La zorra gris, la más abundante, es también la de nicho más central y la UMA queda más cerca de su centro.
La amplitud del nicho no acompaña al IAR (ρ = −0.30): P. concolor es la más generalista y la menos abundante, aunque su IAR depende de 2 registros.
Alcance: con 5 especies, los resultados son descriptivos y no una prueba de las hipótesis de V (p = 0.083 incluso para ρ = −0.90).
Estructura resultante
03-analisis-uma-rstudio/results/
├── figures/          # 04_nicho_omi.png; 04_distancia_uma.png
└── tables/           # 04_parametros_nicho.csv; 04_clima_uma.csv; 04_posicion_uma.csv;
                      # 04_nicho_vs_iar.csv
Limitaciones
Área de estudio (M): el OMI mide la posición respecto al clima promedio de México, el mismo fondo para las cinco especies (Qiao et al., 2017). Una especie que vive también fuera de México (como C. latrans o P. concolor) puede parecer más marginal o más estrecha de lo que es en toda su distribución.
Presencias, no abundancias: en la práctica de V, la tabla de especies tiene abundancias por sitio; aquí solo hay presencia (1) o sin registro (0) por celda, a partir de GBIF. Los 0 no son ausencias (paso 2.3).
Escala de la hipótesis: las hipótesis de la posición y la amplitud del nicho relacionan el nicho con la abundancia en muchos sitios de una región; aquí la abundancia es el IAR de una sola localidad, que funciona solo como aproximación.
Sesgo de muestreo: los registros de GBIF se concentran en sitios muy muestreados, lo que puede desplazar el centro del nicho hacia el clima de esos sitios. Se conserva una presencia por celda, pero no se corrige el sesgo.
Amplitud en 2 ejes: Tol solo mide la dispersión en los 2 ejes que conserva niche() (valor predeterminado de la práctica); el resto queda en Rtol (paso 4). Los extremos (L. rufus estrecho, P. concolor amplio) no cambian con la dispersión total, pero sí el orden de especies con valores casi iguales.
Marginalidad sin prueba de significancia: no se probó si el OMI de cada especie es mayor que el esperado al azar; se comparan solo los valores entre especies.
El IAR es una referencia frágil: el artículo de Plata-Pérez et al. (2024) reporta valores ligeramente distintos según la sección (por ejemplo, 6.06%, 7.2% y 7.22% para el venado); aquí se usan los de su Tabla 1. El IAR del puma (0.14%) no aparece en esa tabla y se basa en solo 2 registros, y los registros de zorra gris se concentran en pocas cámaras.
Posición no es abundancia: el IAR es una abundancia relativa medida con 22 cámaras en 2018–2020, mientras que el clima es el promedio de 1970–2000. Las correlaciones del paso 6.2 son solo descriptivas (n = 5).
Las especies se eligieron por estar en la UMA: que la UMA caiga dentro del nicho de todas es esperable y no es un resultado independiente.
Solo clima: el nicho se describe con 5 variables bioclimáticas. Cobertura vegetal, presas, competidores y presión humana (como cacería) también influyen en la abundancia local.
Distancia de la UMA al centroide: la distancia euclidiana del paso 5 se basa en el concepto de distancia al centroide del nicho visto en clase, aplicado al mismo espacio de la PCA del análisis OMI. Los elipsoides de nicho (Práctica 4 de V) se usan en el objetivo 5.
Referencias
Brown, J. H. (1984). On the relationship between abundance and distribution of species. The American Naturalist, 124(2), 255–279. https://doi.org/10.1086/284267
Dolédec, S., Chessel, D., & Gimaret-Carpentier, C. (2000). Niche separation in community analysis: a new method. Ecology, 81(10), 2914–2927. https://doi.org/10.1890/0012-9658(2000)081[2914:NSICAA]2.0.CO;2
Dray, S., & Dufour, A.-B. (2007). The ade4 package: implementing the duality diagram for ecologists. Journal of Statistical Software, 22(4), 1–20. https://doi.org/10.18637/jss.v022.i04
Hutchinson, G. E. (1957). Concluding remarks. Cold Spring Harbor Symposia on Quantitative Biology, 22, 415–427. https://doi.org/10.1101/SQB.1957.022.01.039
Karasiewicz, S., Dolédec, S., & Lefebvre, S. (2017). Within outlying mean indexes: refining the OMI analysis for the realized niche decomposition. PeerJ, 5, e3364. https://doi.org/10.7717/peerj.3364
Lira-Noriega, A., & Manthey, J. D. (2014). Relationship of genetic diversity and niche centrality: a survey and analysis. Evolution, 68(4), 1082–1093. https://doi.org/10.1111/evo.12343
Plata-Pérez, F. X., Urbina-Flores, D. P., Duana Hernández, B., Villarreal-Espino-Barros, O. A., Gloria-Trujillo, A., & Mendoza-Martínez, G. D. (2024). Unveiling activity patterns of the deer Odocoileus virginianus (Artiodactyla: Cervidae) and its predators in Mexico's Arid Region. Revista de Biología Tropical, 72, e55515. https://doi.org/10.15517/rev.biol.trop..v72i1.55515
Qiao, H., Escobar, L. E., Saupe, E. E., Ji, L., & Soberón, J. (2017). Accessible areas in ecological niche comparisons of invasive species: Recognized but still overlooked. Scientific Reports, 7, 1213. https://doi.org/10.1038/s41598-017-01313-2
Venier, L. A., & Fahrig, L. (1996). Habitat availability causes the species abundance-distribution relationship. Oikos, 76(3), 564–570. https://doi.org/10.2307/3546349
