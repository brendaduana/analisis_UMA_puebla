# Analisis UMA Puebla

Proyecto final del curso **Bases ecológicas y genómicas de la interacción organismo-ambiente**
(Posgrado en Ciencias Biológicas, UNAM · semestre 2027-1).

## UMA Santa Cruz Nuevo, Puebla

En la Unidad de Manejo para la Conservación de la Vida Silvestre (UMA) ubicada en Santa Cruz Nuevo Puebla, han registrado con 22 cámaras trampa la abundancia relativa (IAR) y el traslape de actividad del venado cola blanca (_Odocoileus virginianus_) y sus depredadores en la UMA [(Plata-Perez et al, 2024)](https://archivo.revistas.ucr.ac.cr/index.php/rbt/article/view/55515/59501).

| Especie | Nombre común | IAR (%) |
|---|---|---|
| *Urocyon cinereoargenteus* | Zorra gris | 23.85 |
| *Odocoileus virginianus* | Venado cola blanca | 7.22 |
| *Canis latrans* | Coyote | 3.44 |
| *Lynx rufus* | Gato montés | 2.34 |
| *Puma concolor* | Puma | 0.14 |

Todo el proyecto usa datos públicos: registros de presencia (GBIF), capas climáticas (WorldClim) y valores publicados en la literatura. No incluye datos de campo propios.

## Pregunta de investigación

¿La UMA Santa Cruz Nuevo ocupa una posición central o marginal dentro del nicho climático de los mamíferos registrados en ella, y eso es coherente con su abundancia relativa en fototrampeo?

## Objetivos

Como objetivos especificos se pretende:

1. Obtener y depurar registros de presencia de GBIF para las cinco especies.

2. Seleccionar variables bioclimáticas no correlacionadas (correlación de Spearman y PCA).

3. Construir modelos de nicho ecológico (Maxent) y proyectar la UMA. 

4. Estimar la posición y amplitud de nicho de cada especie en el espacio ambiental (OMI).

5. Comparar el traslape de nicho climático entre venado–coyote y venado–zorra con el traslape temporal (Dhat1) reportado.
   
7. Generar un repositorio que documente el flujo de trabajo y de desiciones para llegar a responder a la pregunta de ivestigación

*como idea guía es: que este proyecto pueda ayudar a comprender el punto ecológico al comparar la detección de mamiferos por ambos metodos de muestreo/monitoreo y ver si este script se puede reutilizar con datos que obtenga en un futuro.
Posible estrucutura del repo:

├── README.md
├── data/
│   ├── raw/          # descargas originales de GBIF (no se editan)
│   └── processed/    # registros depurados y tablas de variables
├── scripts/
│   ├── 01_gbif_limpieza.R
│   ├── 02_variables_correlacion_pca.R
│   ├── 03_modelos_maxent.R
│   ├── 04_posicion_amplitud_omi.R
│   ├── 05_comparacion_nicho.R
│   ├── 06_sintesis.R
│   └── 07_referencias_12S_COI.R
├── results/
│   ├── figures/
│   └── tables/
└── docs/             # notas y referencias
