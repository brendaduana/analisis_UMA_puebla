# Objetivo 5 - Traslape de nichos climaticos (elipsoides) ---####
# Venado cola blanca, coyote y zorra gris

# Se sigue la Practica 4 de V (paquete ellipsenm), con dos especies en lugar de
# dos regiones de una misma especie.

# Ejecutar desde el proyecto 03-analisis-uma-rstudio.Rproj

# Paso 0 - Paquetes ---####
library(terra)
library(ellipsenm) # version 0.3.5, instalada desde GitHub
library(ggplot2)

dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)

# Paso 1 - Capas y presencias (igual que el objetivo 4) ---####
variables_seleccionadas <- read.csv("results/tables/02_variables_seleccionadas.csv")$variable

capas <- rast(file.path("../04-maxent/capas_asc",
                        paste0(variables_seleccionadas, ".asc")))
names(capas) <- variables_seleccionadas
crs(capas) <- "EPSG:4326"   # los .asc no traen sistema de coordenadas

presencias <- read.csv("../04-maxent/presence/presencias_5spp.csv")

# una presencia por celda, como en Maxent (objetivo 3) y en el objetivo 4
presencias$celda <- cellFromXY(capas, as.matrix(presencias[, c("longitude", 
                                                               "latitude")]))
presencias_u <- presencias[!duplicated(presencias[, c("species", "celda")]),
                           c("species", "longitude", "latitude")]

table(presencias_u$species)   # 1060, 541, 1183, 378, 1203

venado <- presencias_u[presencias_u$species == "Odocoileus virginianus", ]
coyote <- presencias_u[presencias_u$species == "Canis latrans", ]
zorra  <- presencias_u[presencias_u$species == "Urocyon cinereoargenteus", ]

# Paso 2 - Un nicho elipsoidal por especie ---####

# mve1 = elipsoide de volumen minimo; level = 95 % de los registros
# variables debe ser un SpatRaster (ellipsenm 0.3.5)
nicho_venado <- overlap_object(venado, species = "species",
                               longitude = "longitude", latitude = "latitude",
                               method = "mve1", level = 95, variables = capas)
nicho_coyote <- overlap_object(coyote, species = "species",
                               longitude = "longitude", latitude = "latitude",
                               method = "mve1", level = 95, variables = capas)
nicho_zorra  <- overlap_object(zorra, species = "species",
                               longitude = "longitude", latitude = "latitude",
                               method = "mve1", level = 95, variables = capas)

# No imprimir el objeto completo (la consola se llena de registros)
nicho_venado@level
nrow(nicho_venado@data)   # registros que conserva (con clima)

# Paso 3 - Traslape de los elipsoides ---####

# overlap_type = "all" (predeterminado) calcula dos medidas:
#   full_overlap  = traslape de los elipsoides completos (puntos simulados)
#   union_overlap = traslape usando solo el clima que existe en el fondo
traslape_vc <- ellipsoid_overlap(nicho_venado, nicho_coyote)
traslape_vz <- ellipsoid_overlap(nicho_venado, nicho_zorra)

traslape_vc@full_overlap
traslape_vc@union_overlap
traslape_vz@full_overlap
traslape_vz@union_overlap

# Volumen de cada elipsoide (solo sirve como razon entre nichos)
traslape_vc@ellipsoids$Niche_1@niche_volume
traslape_vc@ellipsoids$Niche_2@niche_volume
traslape_vz@ellipsoids$Niche_2@niche_volume

# Centro (centroide) de cada elipsoide, en unidades de las variables
rbind(venado = traslape_vc@ellipsoids$Niche_1@centroid,
      coyote = traslape_vc@ellipsoids$Niche_2@centroid,
      zorra  = traslape_vz@ellipsoids$Niche_2@centroid)

# Paso 4 - Prueba de significancia ---####
# En ellipsenm 0.3.5 el numero de repeticiones se llama "iterations"
# (en la practica aparece como "replicates")
set.seed(123)

traslape_vc_st <- ellipsoid_overlap(nicho_venado, nicho_coyote,
                                    overlap_type = "back_union",
                                    significance_test = TRUE,
                                    iterations = 100)
traslape_vz_st <- ellipsoid_overlap(nicho_venado, nicho_zorra,
                                    overlap_type = "back_union",
                                    significance_test = TRUE,
                                    iterations = 100)

# Traslape de cada una de las 100 repeticiones aleatorias
nulo_vc <- traslape_vc_st@significance_results$union_random$Niche_1_vs_2$overlap
nulo_vz <- traslape_vz_st@significance_results$union_random$Niche_1_vs_2$overlap

range(nulo_vc)
range(nulo_vz)

# Paso 5 - Tabla resumen ---####
tabla_traslape <- data.frame(
  par = c("Venado - Coyote", "Venado - Zorra gris"),
  traslape_completo = c(traslape_vc@full_overlap[, "overlap"],
                        traslape_vz@full_overlap[, "overlap"]),
  traslape_fondo = c(traslape_vc@union_overlap[, "overlap"],
                     traslape_vz@union_overlap[, "overlap"])
)

tabla_traslape$nulo_media <- c(mean(nulo_vc), mean(nulo_vz))

# p = (repeticiones con traslape <= observado + 1) / (repeticiones + 1)
tabla_traslape$p <- c(
  (sum(nulo_vc <= tabla_traslape$traslape_fondo[1]) + 1) / (length(nulo_vc) + 1),
  (sum(nulo_vz <= tabla_traslape$traslape_fondo[2]) + 1) / (length(nulo_vz) + 1)
)

tabla_traslape[, -1] <- round(tabla_traslape[, -1], 3)
tabla_traslape

write.csv(tabla_traslape, "results/tables/05_traslape_nichos.csv", row.names = FALSE)

# Paso 6 - Figuras ---####

# plot_overlap() dibuja en 3D (rgl) con las tres primeras variables
# (BIO5, BIO6 y BIO12). Se gira la ventana hasta una vista clara y se guarda.
plot_overlap(traslape_vc, background = TRUE, background_type = "back_union",
             proportion = 0.3)
rgl::snapshot3d("results/figures/05_traslape_venado_coyote.png")

plot_overlap(traslape_vz, background = TRUE, background_type = "back_union",
             proportion = 0.3)
rgl::snapshot3d("results/figures/05_traslape_venado_zorra.png")

# Verificacion final ---####
list.files("results/tables", pattern = "^05_")    # 1 archivo
list.files("results/figures", pattern = "^05_")   # 2 archivos
