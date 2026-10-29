# Nicho climático y abundancia de mamíferos en la UMA Santa Cruz Nuevo, Puebla

Proyecto final del curso **Bases ecológicas y genómicas de la interacción organismo-ambiente**
(Posgrado en Ciencias Biológicas, UNAM,semestre 2027-1).

## Contexto

Mi tesis de maestría se desarrolla en esta misma UMA y compara la detección de mamíferos terrestres
por fototrampeo y por metabarcoding de ADN ambiental. Es una zona semiárida con orografía accidentada,
marcada estacionalidad hídrica y vegetación de matorral xerófilo y bosque caducifolio (INEGI, 2022).
En ambientes así, el acceso al agua limita la distribución de la fauna, sobre todo en la temporada
seca, cuando los mamíferos se concentran en menos sitios con agua (Harris et al., 2015). En el norte
de Sonora, 17 de 21 especies de mamíferos, entre ellas *O. virginianus* y *P. concolor*, se asociaron
con sitios con agua disponible (Ragan et al., 2023).

## Pregunta

¿El clima de la UMA Santa Cruz Nuevo (Totoltepec de Guerrero, Puebla) ocupa una posición central o
marginal dentro del nicho climático de los mamíferos registrados en ella, y esa posición es coherente
con la abundancia relativa publicada para esas especies?

Todo el proyecto usa **datos públicos**: registros de presencia (GBIF), capas climáticas (WorldClim)
y valores publicados en la literatura. No incluye datos de campo propios.

## Antecedente

Plata-Pérez et al. (2024) registraron con 22 cámaras trampa (2018–2020) la abundancia relativa (IAR)
del venado cola blanca y de otros mamíferos en la UMA. Este proyecto usa esas especies y valores como
referencia.

| Especie | Nombre común | IAR (%) |
|---|---|---|
| *Urocyon cinereoargenteus* | Zorra gris | 23.85 |
| *Odocoileus virginianus* | Venado cola blanca | 7.22 |
| *Canis latrans* | Coyote | 3.44 |
| *Lynx rufus* | Gato montés | 2.34 |
| *Puma concolor* | Puma | 0.14 |

## Objetivos

| Objetivo | Guía | Script | Herramientas |
|---|---|---|---|
| 1. Obtener y depurar registros de presencia de GBIF para las cinco especies | [`01-objetivo.md`](01-objetivo.md) | — | GBIF, Excel, QGIS |
| 2. Seleccionar variables bioclimáticas no correlacionadas (Spearman y PCA) | [`02-objetivo.md`](02-objetivo.md) | [`02-objetivo-script.R`](02-objetivo-script.R) | QGIS, R |
| 3. Construir modelos de nicho con Maxent y evaluar la idoneidad de la UMA en el espacio geográfico | [`03-objetivo.md`](03-objetivo.md) | [`03-objetivo-script.R`](03-objetivo-script.R) | Maxent, R |
| 4. Estimar la posición y amplitud del nicho climático de cada especie (análisis OMI) y la posición de la UMA en el espacio ambiental | [`04-objetivo.md`](04-objetivo.md) | [`04-objetivo-script.R`](04-objetivo-script.R) | R (`ade4`) |
| 5. Comparar el nicho climático del venado con el del coyote y el de la zorra gris (traslape de elipsoides) | [`05-objetivo.md`](05-objetivo.md) | [`05-objetivo-script.R`](05-objetivo-script.R) | R (`ellipsenm`) |

Cada guía explica el procedimiento paso a paso, con los resultados obtenidos, las decisiones tomadas y
sus limitaciones. Cada script contiene el código que se ejecutó para ese objetivo.

## Resultados principales

Los resultados son **exploratorios**: se trabaja con cinco especies, una sola localidad y datos de
presencia de GBIF, por lo que las relaciones con la abundancia no se interpretan como prueba de
hipótesis.

| Objetivo | Resultado |
|---|---|
| 1 | 7,958 registros tras quitar duplicados y puntos erróneos (591 a 2,681 por especie). |
| 2 | Cinco variables: BIO5, BIO6, BIO12, BIO15 y BIO17 (\|ρ\| ≤ 0.58 entre ellas), que representan los extremos de temperatura y la disponibilidad de agua. |
| 3 | La UMA es idónea para las cinco especies según el umbral del percentil 10, con idoneidad intermedia (0.53–0.66). Como entre el 56% y el 74% de México resulta idóneo para cada especie, este resultado por sí solo dice poco. |
| 4 | El clima de la UMA queda en la parte central del nicho de las cinco especies (más cerca del centro que el 79% a 93% de los registros de cada una). El orden de las especies por posición del nicho coincide con el del IAR salvo por el gato montés y el puma (ρ = −0.90; p = 0.083; n = 5). La amplitud del nicho no acompaña al IAR (ρ = −0.30): el puma es la especie más generalista y la más rara. |
| 5 | El nicho climático del venado se traslapa más con el de la zorra gris (0.955) que con el del coyote (0.801), que ocupa climas más secos y de invierno más frío. En ambos pares el traslape observado fue menor que en las 100 comparaciones aleatorias (p ≈ 0.01, el mínimo posible con 100 repeticiones); con el coyote la diferencia es clara (0.80 frente a un mínimo aleatorio de 0.96) y con la zorra es muy pequeña (0.955 frente a 0.957). |

## Fuentes de datos

| Dato | Fuente | Acceso |
|---|---|---|
| Registros de presencia | GBIF (gbif.org), México, 1980–2020 | Descargas con DOI (tabla siguiente) |
| Variables bioclimáticas | WorldClim 2.1 (promedio 1970–2000, 2.5 min; Fick y Hijmans, 2017) | worldclim.org |
| División política estatal (máscara de México) | CONABIO, escala 1:1,000,000 (`destdv1gw`) | Geoportal de CONABIO |
| Abundancia relativa (IAR) | Plata-Pérez et al. (2024) | Artículo de acceso abierto |


| Especie | Descarga GBIF | DOI |
|---|---|---|
| *Urocyon cinereoargenteus* | 0009786-260921141020460 | [10.15468/dl.568fu5](https://doi.org/10.15468/dl.568fu5) |
| *Odocoileus virginianus* | 0009787-260921141020460 | [10.15468/dl.caw6rb](https://doi.org/10.15468/dl.caw6rb) |
| *Canis latrans* | 0009789-260921141020460 | [10.15468/dl.6vw73h](https://doi.org/10.15468/dl.6vw73h) |
| *Lynx rufus* | 0009791-260921141020460 | [10.15468/dl.27d2vx](https://doi.org/10.15468/dl.27d2vx) |
| *Puma concolor* | 0009794-260921141020460 | [10.15468/dl.6r3hc5](https://doi.org/10.15468/dl.6r3hc5) |

## Estructura del proyecto

En este repositorio se incluyen las guías (`.md`) de los cinco objetivos y los scripts (`.R`) de los
objetivos 2 a 5 (el objetivo 1 se hace en GBIF, Excel y QGIS, sin código). Los datos,
capas climáticas, resultados de Maxent, tablas y figuras **no se suben**; se generan siguiendo las
guías. En las guías, las figuras y
tablas se mencionan por su nombre de archivo.

Estructura de carpetas que se usa localmente:

```
analisis_uma/
├── 00-data-species/              # descargas originales de GBIF (.zip)
├── 00-data-worldclim/            # 19 .tif de WorldClim 2.1, 2.5 min
├── 00-data-map-mex/              # destdv1gw.shp (CONABIO)
├── 01-data-unclean-qgis/         # registros antes de la revisión en QGIS
├── 02-data-clean-qgis/           # 5 CSV finales de presencias
├── 03-analisis-uma-rstudio/      # proyecto de RStudio
│   ├── 03-analisis-uma-rstudio.Rproj
│   ├── 02-objetivo-script.R … 05-objetivo-script.R
│   └── results/                  # figures/ y tables/
└── 04-maxent/                    # capas .asc, presencias y resultados de Maxent (objetivo 3)
```

Para correr los scripts, se copian a la carpeta `03-analisis-uma-rstudio/` y se ejecutan desde el
proyecto `03-analisis-uma-rstudio.Rproj`; todas las rutas son relativas a esa carpeta.

## Requisitos

- Excel y QGIS (limpieza de registros)
- Maxent 3.4.4 (requiere Java)
- R 4.4.0 con los paquetes `terra`, `ggplot2`, `reshape2`, `factoextra`, `psych`, `ade4`, `ggrepel`,
  `ellipsenm` (0.3.5, instalado desde GitHub) y `rgl`

## Limitaciones generales

- Los registros se limitan a México, por lo que el nicho estimado corresponde solo a la parte
  mexicana de la distribución de cada especie.
- Los registros de GBIF tienen sesgo de muestreo y no se filtraron por tipo de registro ni por
  incertidumbre de las coordenadas.
- El nicho se describe solo con cinco variables climáticas; vegetación, presas y presión humana no se
  consideran.
- El IAR es la abundancia relativa de una sola localidad y, en el caso del puma, se basa en muy pocos
  registros. Con cinco especies, las comparaciones con el IAR son solo descriptivas.

## Referencias

- Brown, J. H. (1984). On the relationship between abundance and distribution of species. *The American Naturalist*, 124(2), 255–279. https://doi.org/10.1086/284267
- Fick, S. E., & Hijmans, R. J. (2017). WorldClim 2: new 1-km spatial resolution climate surfaces for global land areas. *International Journal of Climatology*, 37(12), 4302–4315. https://doi.org/10.1002/joc.5086
- GBIF.org (2026). Occurrence Download. https://doi.org/10.15468/dl.568fu5, https://doi.org/10.15468/dl.caw6rb, https://doi.org/10.15468/dl.6vw73h, https://doi.org/10.15468/dl.27d2vx, https://doi.org/10.15468/dl.6r3hc5
- Harris, G., Sanderson, J. G., Erz, J., Lehnen, S. E., & Butler, M. J. (2015). Weather and prey predict mammals' visitation to water. *PLOS ONE*, 10(11), e0141355. https://doi.org/10.1371/journal.pone.0141355
- INEGI, Instituto Nacional de Estadística y Geografía. (2022). *Aspectos geográficos de Puebla. Compendio 2022*.
- Lira-Noriega, A., & Manthey, J. D. (2014). Relationship of genetic diversity and niche centrality: a survey and analysis. *Evolution*, 68(4), 1082–1093. https://doi.org/10.1111/evo.12343
- Plata-Pérez, F. X., Urbina-Flores, D. P., Duana Hernández, B., Villarreal-Espino-Barros, O. A.,
  Gloria-Trujillo, A., & Mendoza-Martínez, G. D. (2024). Unveiling activity patterns of the deer
  *Odocoileus virginianus* (Artiodactyla: Cervidae) and its predators in Mexico's Arid Region.
  *Revista de Biología Tropical*, 72, e55515. https://doi.org/10.15517/rev.biol.trop..v72i1.55515
- Qiao, H., Escobar, L. E., Saupe, E. E., Ji, L., & Soberón, J. (2017). Accessible areas in ecological niche comparisons of invasive species: Recognized but still overlooked. *Scientific Reports*, 7, 1213. https://doi.org/10.1038/s41598-017-01313-2
- Ragan, K., Schipper, J., Bateman, H. L., & Hall, S. J. (2023). Mammal use of riparian corridors in semi-arid Sonora, Mexico. *The Journal of Wildlife Management*, 87(1), e22322. https://doi.org/10.1002/jwmg.22322
- Soberón, J., & Peterson, A. T. (2005). Interpretation of models of fundamental ecological niches and species' distributional areas. *Biodiversity Informatics*, 2, 1–10. https://doi.org/10.17161/bi.v2i0.4
- Venier, L. A., & Fahrig, L. (1996). Habitat availability causes the species abundance-distribution relationship. *Oikos*, 76(3), 564–570. https://doi.org/10.2307/3546349

Las referencias de las herramientas (Maxent, R, QGIS, `ade4`, `ellipsenm`) y de los métodos se
encuentran en la guía de cada objetivo.

### Autora

Brenda Duana Hernandez, Posgrado en Ciencias Biológicas, UNAM.

### Docentes

