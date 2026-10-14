# Objetivo 5 - Traslape de nichos climáticos del venado, el coyote y la zorra gris

Con las presencias (objetivo 1), las cinco variables (objetivo 2), los modelos de Maxent (objetivo 3) y la posición del nicho (objetivo 4), este objetivo compara los **nichos climáticos entre especies** para responder:

**¿Qué tanto se traslapa el nicho climático del venado cola blanca con el de su depredador, el coyote, y con el de la zorra gris, la especie más abundante en la UMA?**

Se sigue la Práctica 4 de V (paquete `ellipsenm`): se ajusta un **elipsoide de nicho** a los registros de cada especie en el espacio ambiental y se calcula el traslape entre elipsoides, con prueba de significancia. La práctica compara dos regiones de una misma especie; aquí se comparan dos especies en la misma área (México). El resto del flujo es el mismo.

| Práctica de V | Este análisis |
|---|---|
| Ocurrencias de la región 1 y de la región 2 | Presencias del venado y de cada especie comparada |
| `vars1`, `vars2` (variables de cada región) | Las mismas 5 capas climáticas de México (el fondo es común) |
| `overlap_object()` por región | `overlap_object()` por especie |
| `ellipsoid_overlap()` con `back_union` y prueba de significancia | Igual |
| `plot_overlap()` | Igual |

Los dos pares se eligen porque el venado es la presa y la especie central del antecedente (Plata-Pérez et al. 2024), el coyote es un depredador del venado, y la zorra gris es la especie más abundante en la UMA. Se mide **solo el traslape climático**; no se evalúan interacciones entre especies.

## Flujo de trabajo

| Paso | Qué se hace | Dónde | Origen en el curso |
|---|---|---|---|
| 0 | Preparar paquetes (`ellipsenm`) | R | Práctica 4 (V) |
| 1 | Cargar capas y presencias | R | Objetivos 2 a 4 |
| 2 | Elipsoide de nicho de cada especie | R | Práctica 4 (V) |
| 3 | Traslape de los elipsoides | R | Práctica 4 (V) |
| 4 | Prueba de significancia | R | Práctica 4 (V) |
| 5 | Tabla resumen | R | Práctica 4 (V) |
| 6 | Figuras | R | Práctica 4 (V) |

## Paso 0 - Preparar el ambiente

```r
library(terra)
library(ellipsenm)
library(ggplot2)

dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)
```

- `ellipsenm` es el paquete de la Práctica 4 de V. La versión usada aquí es la 0.3.5.

## Paso 1 - Capas y presencias

Es el mismo paso 1 del objetivo 4: las mismas capas `.asc` que usó Maxent y el mismo archivo de presencias, con **una presencia por celda**.

```r
variables_seleccionadas <- read.csv("results/tables/02_variables_seleccionadas.csv")$variable

capas <- rast(file.path("../04-maxent/capas_asc",
                        paste0(variables_seleccionadas, ".asc")))
names(capas) <- variables_seleccionadas
crs(capas) <- "EPSG:4326"

presencias <- read.csv("../04-maxent/presence/presencias_5spp.csv")
presencias$celda <- cellFromXY(capas, as.matrix(presencias[, c("longitude", "latitude")]))
presencias_u <- presencias[!duplicated(presencias[, c("species", "celda")]),
                           c("species", "longitude", "latitude")]

table(presencias_u$species)

venado <- presencias_u[presencias_u$species == "Odocoileus virginianus", ]
coyote <- presencias_u[presencias_u$species == "Canis latrans", ]
zorra  <- presencias_u[presencias_u$species == "Urocyon cinereoargenteus", ]
```

- Cada tabla queda con tres columnas (`species`, `longitude`, `latitude`), que es lo que pide `overlap_object()`.
- `crs()` asigna WGS 84, porque los `.asc` no guardan el sistema de coordenadas.

**Resultado**

Las celdas únicas son las mismas del objetivo 4: 1,060 (*C. latrans*), 541 (*L. rufus*), 1,183 (*O. virginianus*), 378 (*P. concolor*) y 1,203 (*U. cinereoargenteus*). Solo se usan tres de las cinco especies.

## Paso 2 - Un elipsoide de nicho por especie

```r
nicho_venado <- overlap_object(venado, species = "species",
                               longitude = "longitude", latitude = "latitude",
                               method = "mve1", level = 95, variables = capas)
nicho_coyote <- overlap_object(coyote, species = "species",
                               longitude = "longitude", latitude = "latitude",
                               method = "mve1", level = 95, variables = capas)
nicho_zorra  <- overlap_object(zorra, species = "species",
                               longitude = "longitude", latitude = "latitude",
                               method = "mve1", level = 95, variables = capas)

nicho_venado@level
nrow(nicho_venado@data)
```

- `method = "mve1"` ajusta el elipsoide de **volumen mínimo** (*minimum volume ellipsoid*), igual que en la práctica.
- `level = 95` hace que el elipsoide contenga el 95% de los registros; el otro 5% se trata como valores extremos.
- `variables = capas` debe ser un `SpatRaster` (`terra`). En la versión 0.3.5, una pila de `raster::stack()` como la que usa la práctica produce el error *Argument 'variables' is not valid*.
- `overlap_object()` extrae el clima de cada registro y guarda el conjunto de datos, el método, el nivel y las variables. **No devuelve todavía el elipsoide**: este se calcula en el paso 3.
- Conviene **no imprimir el objeto completo** (`nicho_venado`), porque la consola se llena con todos los registros; basta revisar `@level` y el número de filas de `@data`.

**Resultado**

Los tres objetos se crearon sin errores. Para el venado se conservaron todos sus registros (1,183, sin pérdida por falta de dato climático).

## Paso 3 - Traslape de los elipsoides

```r
traslape_vc <- ellipsoid_overlap(nicho_venado, nicho_coyote)
traslape_vz <- ellipsoid_overlap(nicho_venado, nicho_zorra)

traslape_vc@full_overlap
traslape_vc@union_overlap
traslape_vz@full_overlap
traslape_vz@union_overlap
```

- Con `overlap_type = "all"` (valor predeterminado) se calculan dos medidas:
  - **Traslape completo** (`full_overlap`): se simulan puntos dentro de los dos elipsoides en el espacio ambiental y se mide qué proporción cae en ambos.
  - **Traslape con fondo** (`union_overlap`, `back_union`): se usan solo las combinaciones de clima que **existen** en México. Compara los nichos en el clima realmente disponible, no en combinaciones que no existen.
- En ambos casos el traslape es `overlaped_points / total_points`, es decir, la proporción de puntos evaluados que cae dentro de los dos elipsoides (por ejemplo, 26,381 / 74,827 = 0.353 para venado–coyote).
- `prop_size_niche_1_vs_2` es el tamaño del elipsoide 1 respecto al 2.

**Resultado**

| Par | Traslape completo | Traslape con fondo | Tamaño venado / otra especie (completo) | Tamaño venado / otra especie (con fondo) |
|---|---|---|---|---|
| Venado–coyote | 0.353 | 0.801 | 1.89 | 1.12 |
| Venado–zorra gris | 0.682 | 0.955 | 0.77 | 0.96 |

El nicho del venado es mayor que el del coyote y algo menor que el de la zorra.

Centro de cada elipsoide (centroide):

| Especie | BIO5 (°C) | BIO6 (°C) | BIO12 (mm) | BIO15 | BIO17 (mm) |
|---|---|---|---|---|---|
| *O. virginianus* (venado) | 31.9 | 8.0 | 828 | 87.0 | 43.6 |
| *C. latrans* (coyote) | 32.0 | 4.9 | 521 | 87.1 | 23.7 |
| *U. cinereoargenteus* (zorra) | 32.1 | 8.4 | 787 | 87.6 | 41.2 |

**Decisión**

- La **zorra gris se traslapa más con el venado** que el coyote, con las dos medidas (0.68 contra 0.35 en el traslape completo; 0.96 contra 0.80 con fondo).
- La diferencia está en el **invierno y la lluvia**: los tres centros son casi iguales en calor de verano (BIO5) y estacionalidad de la lluvia (BIO15), pero el coyote ocupa climas más secos (BIO12 521 mm contra 828 y 787 mm) y de invierno más frío (BIO6 4.9 °C contra 8.0 y 8.4 °C).
- Esto es coherente con el objetivo 4: en el espacio de la PCA, el centro del nicho del venado queda cerca del de la zorra (diferencia de 0.11 en el Eje 1) y lejos del del coyote (0.84 en el Eje 1), que queda del lado seco.
- La medida **con fondo** es la más interpretable. Los elipsoides al 95% se extienden más allá del clima que existe en México (en la salida del traslape completo aparecen valores imposibles, como BIO12 y BIO17 negativos), y el traslape completo cuenta esos puntos. Por eso, en el resumen se da más peso al traslape con fondo y se reporta el completo como referencia.
- Los traslapes con fondo son altos (0.80 y 0.96) porque los elipsoides cubren casi todo el clima de México (la medida con fondo evalúa 92,924 puntos de las 102,316 celdas de México, que parecen corresponder a las celdas dentro de al menos uno de los elipsoides). Esto se retoma en las limitaciones.

## Paso 4 - Prueba de significancia

```r
set.seed(123)

traslape_vc_st <- ellipsoid_overlap(nicho_venado, nicho_coyote,
                                    overlap_type = "back_union",
                                    significance_test = TRUE,
                                    iterations = 100)
traslape_vz_st <- ellipsoid_overlap(nicho_venado, nicho_zorra,
                                    overlap_type = "back_union",
                                    significance_test = TRUE,
                                    iterations = 100)

nulo_vc <- traslape_vc_st@significance_results$union_random$Niche_1_vs_2$overlap
nulo_vz <- traslape_vz_st@significance_results$union_random$Niche_1_vs_2$overlap

range(nulo_vc)
range(nulo_vz)
```

- La prueba genera 100 comparaciones aleatorias dentro del mismo fondo y calcula el traslape en cada una. Así se obtiene la distribución del traslape esperado **por azar** (hipótesis nula), contra la que se compara el traslape observado.
- En la versión 0.3.5, el número de repeticiones se llama **`iterations`**, no `replicates` como en la práctica. Con `replicates` la función da el error *All objects to be compared must be of class ellipsoid\**, porque interpreta el valor como otro objeto a comparar.
- `set.seed(123)` hace que el resultado sea reproducible.
- 100 repeticiones es el valor de la práctica; con ese número el valor mínimo de p que se puede obtener es 1/101 ≈ 0.01.

**Resultado**

| Par | Traslape observado | Traslape aleatorio (rango) | Media aleatoria | Repeticiones con traslape ≤ observado |
|---|---|---|---|---|
| Venado–coyote | 0.801 | 0.960 a 0.995 | 0.980 | 0 de 100 |
| Venado–zorra gris | 0.955 | 0.957 a 0.992 | 0.980 | 0 de 100 |

**Decisión**

En los dos pares el traslape observado es **menor que en las 100 repeticiones aleatorias**, es decir, los nichos son **más distintos de lo esperado por azar** (p ≈ 0.01). Pero la magnitud de la diferencia es muy distinta:

- **Venado–coyote:** diferencia clara. El traslape observado (0.80) queda muy por debajo de todo el rango aleatorio (≥ 0.96).
- **Venado–zorra gris:** diferencia **estadísticamente significativa pero pequeña**. El traslape observado (0.955) queda apenas por debajo del valor mínimo aleatorio (0.957). En términos prácticos, los nichos climáticos del venado y la zorra son muy parecidos.

## Paso 5 - Tabla resumen

```r
tabla_traslape <- data.frame(
  par = c("Venado - Coyote", "Venado - Zorra gris"),
  traslape_completo = c(traslape_vc@full_overlap[, "overlap"],
                        traslape_vz@full_overlap[, "overlap"]),
  traslape_fondo = c(traslape_vc@union_overlap[, "overlap"],
                     traslape_vz@union_overlap[, "overlap"])
)

tabla_traslape$nulo_media <- c(mean(nulo_vc), mean(nulo_vz))

tabla_traslape$p <- c(
  (sum(nulo_vc <= tabla_traslape$traslape_fondo[1]) + 1) / (length(nulo_vc) + 1),
  (sum(nulo_vz <= tabla_traslape$traslape_fondo[2]) + 1) / (length(nulo_vz) + 1)
)

tabla_traslape[, -1] <- round(tabla_traslape[, -1], 3)
tabla_traslape

write.csv(tabla_traslape, "results/tables/05_traslape_nichos.csv", row.names = FALSE)
```

- `p` es la proporción de repeticiones aleatorias con un traslape igual o menor que el observado, sumando 1 a numerador y denominador para que nunca sea 0.

**Resultado**

| Par | Traslape completo | Traslape con fondo | Media aleatoria | p |
|---|---|---|---|---|
| Venado–coyote | 0.353 | 0.801 | 0.980 | 0.01 |
| Venado–zorra gris | 0.682 | 0.955 | 0.980 | 0.01 |

**Salida:** `results/tables/05_traslape_nichos.csv`.

## Paso 6 - Figuras

```r
plot_overlap(traslape_vc, background = TRUE, background_type = "back_union",
             proportion = 0.3)
rgl::snapshot3d("results/figures/05_traslape_venado_coyote.png")

plot_overlap(traslape_vz, background = TRUE, background_type = "back_union",
             proportion = 0.3)
rgl::snapshot3d("results/figures/05_traslape_venado_zorra.png")
```

- `plot_overlap()` dibuja los dos elipsoides (malla), los registros de cada especie (puntos) y el clima de fondo (puntos de colores). `background_type = "back_union"` usa el mismo fondo que el traslape con fondo, y `proportion = 0.3` dibuja el 30% de los puntos de fondo para no saturar la figura.
- El gráfico es **3D** (`rgl`) y muestra solo las **tres primeras variables**: BIO5, BIO6 y BIO12. BIO15 y BIO17 entran en el cálculo del traslape pero no se ven en la figura.
- Se abre una ventana interactiva: se gira hasta una vista clara y `snapshot3d()` guarda la imagen. En la leyenda, **Niche 1 (azul) es el venado** y **Niche 2 (gris) la otra especie**.
- `snapshot3d()` avisa que usará `rgl.snapshot()` porque no están los paquetes `webshot2` ni Chrome; la imagen se guarda igual.

**Resultado**

`05_traslape_venado_coyote.png`: el elipsoide del venado (azul) es mayor que el del coyote (gris), que se asoma fuera del azul en un extremo y queda desplazado hacia climas más secos (BIO12). Los registros del venado llegan a valores de BIO12 cercanos a 3,000 mm (sureste húmedo), donde casi no hay registros del coyote.

`05_traslape_venado_zorra.png`: los dos elipsoides casi coinciden; la malla gris (zorra) es algo mayor y sobresale ligeramente de la azul. Los registros de ambas especies también ocupan la parte húmeda (BIO12 de 2,000 a 3,000 mm), a diferencia de lo que pasa con el coyote.

**Salidas:** `results/figures/05_traslape_venado_coyote.png` y `results/figures/05_traslape_venado_zorra.png`.

## Decisión

- **El nicho climático del venado se traslapa mucho más con el de la zorra gris que con el del coyote** (traslape con fondo de 0.955 contra 0.801; traslape completo de 0.682 contra 0.353).
- **La diferencia con el coyote es clara y se debe al invierno y a la lluvia:** el coyote ocupa climas más secos y de invierno más frío (BIO12 ≈ 521 mm y BIO6 ≈ 4.9 °C, contra ≈ 828 mm y 8.0 °C del venado). Esto coincide con la posición de su nicho en el objetivo 4. Para referencia, el clima de la UMA (BIO12 ≈ 494 mm) está más cerca del centro del coyote que del venado en esta variable.
- **Con la zorra, los nichos son casi iguales:** la diferencia es significativa pero pequeña.
- **Alcance:** es solo traslape **climático**. Que dos nichos se traslapen en clima no implica que las especies interactúen o compitan; eso depende del uso de hábitat y del tiempo, que no se evalúan aquí.

## Estructura resultante

```
03-analisis-uma-rstudio/results/
├── figures/          # 05_traslape_venado_coyote.png; 05_traslape_venado_zorra.png
└── tables/           # 05_traslape_nichos.csv
```

## Limitaciones

- **Elipsoides muy grandes respecto al clima de México:** los elipsoides al 95% cubren casi todo el clima del país, por lo que el traslape con fondo es alto en cualquier comparación (la media aleatoria es 0.98). Por eso importa más comparar contra la distribución aleatoria que el valor absoluto del traslape.
- **Traslape completo con valores imposibles:** los puntos simulados dentro del elipsoide incluyen valores que no existen (precipitaciones negativas), lo que baja el traslape completo. Se prefiere la medida con fondo.
- **Pocas repeticiones:** con 100 repeticiones, el menor p posible es 0.01. Más repeticiones darían un p más fino, pero con el mismo resultado cualitativo (ninguna repetición alcanzó el traslape observado).
- **Elipsoide con variación entre corridas:** el elipsoide de volumen mínimo se estima con un procedimiento aleatorio, por lo que el elipsoide del venado cambia ligeramente entre las dos comparaciones (volumen de 3.72 × 10⁹ en la comparación con el coyote y de 3.76 × 10⁹ con la zorra; menos de 1% de diferencia). No se fijó la semilla antes del paso 2, así que una nueva ejecución puede dar cifras ligeramente distintas.
- **Área de estudio (M):** el fondo es todo México, como en los objetivos 3 y 4. Especies que viven también fuera de México (como *C. latrans*) tienen un nicho parcialmente muestreado (Soberón y Peterson 2005; Barve et al. 2011).
- **Presencias de GBIF:** los registros se concentran en sitios muy muestreados y no se corrigió el sesgo de muestreo.
- **Solo tres especies y solo clima:** se comparan solo dos pares, y el nicho se describe con 5 variables bioclimáticas; vegetación, presas y presión humana no se consideran.
- **Gráfico en 3 de 5 variables:** `plot_overlap()` solo muestra BIO5, BIO6 y BIO12. El traslape se calcula con las cinco variables.
- **Diferencia con la práctica:** en `ellipsenm` 0.3.5 el argumento de repeticiones es `iterations` (no `replicates`) y `variables` debe ser un `SpatRaster`.

## Referencias

- Barve, N., Barve, V., Jiménez-Valverde, A., Lira-Noriega, A., Maher, S. P., Peterson, A. T., Soberón, J., & Villalobos, F. (2011). The crucial role of the accessible area in ecological niche modeling and species distribution modeling. *Ecological Modelling*, 222(11), 1810–1819. https://doi.org/10.1016/j.ecolmodel.2011.02.011
- Cobos, M. E., Osorio-Olvera, L., Soberón, J., Peterson, A. T., Barve, V., & Barve, N. *ellipsenm: Ecological niche characterization using ellipsoids*. Paquete de R. https://github.com/marlonecobos/ellipsenm
- Plata-Pérez, F. X., Urbina-Flores, D. P., Duana Hernández, B., Villarreal-Espino-Barros, O. A., Gloria-Trujillo, A., & Mendoza-Martínez, G. D. (2024). Unveiling activity patterns of the deer *Odocoileus virginianus* (Artiodactyla: Cervidae) and its predators in Mexico's Arid Region. *Revista de Biología Tropical*, 72, e55515. https://doi.org/10.15517/rev.biol.trop..v72i1.55515
- Soberón, J., & Peterson, A. T. (2005). Interpretation of models of fundamental ecological niches and species' distributional areas. *Biodiversity Informatics*, 2, 1–10. https://doi.org/10.17161/bi.v2i0.4
