# Objetivo 3: Modelos de nicho ecologico con Maxent ---####

# Nicho climatico y abundancia de mamiferos en la UMA Santa Cruz Nuevo

# Requiere el objetivo 2 (results/tables/02_variables_seleccionadas.csv).
# El paso 3 (Maxent) se hace fuera de R; ver la guia.

# 0.1 Paquetes ---####

if (!require("terra")) install.packages("terra")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("reshape2")) install.packages("reshape2")

# Cargar paqueterias

library(terra)
library(ggplot2)
library(reshape2)

# Se agrega una carpeta para archivos de entrada y salida de Maxent:

getwd() # [1] "C:/analisis_uma/03-analisis-uma-rstudio"

dir.create("../04-maxent/capas_asc", recursive = TRUE, showWarnings = FALSE)
dir.create("../04-maxent/presence", recursive = TRUE, showWarnings = FALSE)
dir.create("../04-maxent/results", recursive = TRUE, showWarnings = FALSE)

# 0.2 Maxent

# Se descarga e instala Maxent

# Paso 1 · Preparar las capas climaticas para Maxent ---####

# 1.1 Variables elegidas en el objetivo 2

variables_seleccionadas <- read.csv("results/tables/02_variables_seleccionadas.csv")$variable

variables_seleccionadas

# 1.2 Cargar y recortar las capas (igual que en el objetivo 2, pasos 3 y 4)

bios <- list.files(
  path = "../00-data-worldclim",
  pattern = "\\.tif$",
  full.names = TRUE
)

bios <- rast(bios)

names(bios) <- sub("wc2.1_2.5m_bio_", "BIO", names(bios))

mexico <- vect("../00-data-map-mex/destdv1gw.shp")

# Solo las 5 variables seleccionadas

bios_mx_sel <- mask(
  crop(bios[[variables_seleccionadas]], mexico),
  mexico
)

bios_mx_sel

png("results/figures/03_variables_seleccionadas.png", width = 2600, height = 1400, res = 200)
plot(bios_mx_sel, nc = 3)
dev.off()

# 1.3 Exportar cada variable como ASCII grid (.asc) para Maxent
# -9999 = celda sin dato

for (v in variables_seleccionadas) {
  writeRaster(
    bios_mx_sel[[v]],
    filename = paste0("../04-maxent/capas_asc/", v, ".asc"),
    filetype = "AAIGrid",
    NAflag = -9999,
    overwrite = TRUE
  )
}

list.files("../04-maxent/capas_asc", pattern = "\\.asc$")   # deben ser 5

# Paso 2 · Unir y verificar las presencias ---####

# 2.1 Unir los 5 CSV del objetivo 1 (species, longitude, latitude)

archivos_presencias <- list.files(
  path = "../02-data-clean-qgis",
  pattern = "\\.csv$",
  full.names = TRUE
)

archivos_presencias

presencias <- do.call(rbind, lapply(archivos_presencias, read.csv))

names(presencias)
table(presencias$species)

# 2.2 Quitar puntos que caen en celdas sin dato climatico (costa, islas)

valores_presencias <- extract(
  bios_mx_sel,
  as.matrix(presencias[, c("longitude", "latitude")])
)

fuera <- !complete.cases(valores_presencias)
sum(fuera) #11
table(presencias$species[fuera]) #2,1,3,2,3

presencias_maxent <- presencias[!fuera, ]

write.csv(presencias_maxent,
          "../04-maxent/presence/presencias_5spp.csv",
          row.names = FALSE)

# 2.3 Registros y celdas unicas por especie (Maxent usa una presencia por celda)

celdas <- cellFromXY(
  bios_mx_sel,
  as.matrix(presencias_maxent[, c("longitude", "latitude")])
)

registros_maxent <- data.frame(
  especie = names(table(presencias_maxent$species)),
  registros = as.vector(table(presencias_maxent$species)),
  celdas_unicas = as.vector(tapply(celdas, presencias_maxent$species,
                                   function(x) length(unique(x))))
)

registros_maxent

write.csv(registros_maxent, "results/tables/03_registros_maxent.csv", row.names = FALSE)


# Paso 3 · Correr Maxent (fuera de R) ---####

# Configuracion en la guia. Resumen:
#   Samples:               04-maxent/presence/presencias_5spp.csv
#   Environmental layers:  04-maxent/capas_asc (todas Continuous)
#   Output directory:      04-maxent/results
#   Output format:         Cloglog
#   Settings:              10% prueba | 10 replicas | Bootstrap

# Paso 4 · Desempeno de los modelos ---####

# 4.1 Leer la tabla resumen de Maxent

resultados_maxent <- read.csv("../04-maxent/results/maxentResults.csv",
                              check.names = FALSE)

names(resultados_maxent)   # revisar los nombres exactos de las columnas
resultados_maxent$Species

# 4.2 Quedarse solo con el promedio de las 10 replicas de cada especie

promedios <- resultados_maxent[grepl("\\(average\\)", resultados_maxent$Species), ]

promedios$Species   # deben ser 5 filas

# Tabla de desempeno

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

# 4.3 Contribucion e importancia por permutacion de cada variable (promedio de 10 replicas)

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

# Paso 5 · Mapas de idoneidad y mapas binarios ---####

# 5.1 Leer los mapas promedio de Maxent (_avg.asc)

especies <- resumen_maxent$especie   # p. ej. "Canis_latrans"

mapas <- rast(paste0("../04-maxent/results/", especies, "_avg.asc"))
names(mapas) <- especies
crs(mapas) <- "EPSG:4326"   # los .asc de Maxent no traen sistema de coordenadas

mapas

plot(mapas)

# 5.2 Binario: 1 = idoneo (>= umbral p10), 0 = no idoneo

binarios <- rast(lapply(seq_along(especies), function(i) {
  mapas[[i]] >= resumen_maxent$umbral_p10[i]
}))
names(binarios) <- especies

binarios

plot(binarios)

# 5.3 Porcentaje de Mexico clasificado como idoneo

area_idonea <- data.frame(
  especie = especies,
  umbral_p10 = resumen_maxent$umbral_p10,
  porcentaje_idoneo = round(unlist(global(binarios, "mean", na.rm = TRUE)) * 100, 1)
)

area_idonea

write.csv(area_idonea, "results/tables/03_area_idonea.csv", row.names = FALSE)

# Paso 6 · Proyectar la UMA en el espacio geografico ---####

# 6.1 Ubicacion de la UMA (Plata-Perez et al. 2024: 18°17'44" N, 97°48'35" W)

uma <- data.frame(
  sitio = "UMA Santa Cruz Nuevo",
  longitude = -97.8097,
  latitude = 18.2956
)

uma_vect <- vect(uma, geom = c("longitude", "latitude"), crs = "EPSG:4326")

uma_vect

# 6.2 Idoneidad en la celda de la UMA y en un radio de 5 km

idoneidad_uma <- unlist(extract(mapas, uma_vect)[, especies])
binario_uma <- unlist(extract(binarios, uma_vect)[, especies])

uma_buffer <- buffer(uma_vect, width = 5000)
idoneidad_buffer <- unlist(extract(mapas, uma_buffer, fun = mean, na.rm = TRUE)[, especies])

round(idoneidad_uma, 3)
binario_uma
round(idoneidad_buffer, 3)

# 6.3 Tabla final con la abundancia relativa publicada (solo referencia)

tabla_uma <- data.frame(
  especie = especies,
  idoneidad_uma = round(idoneidad_uma, 3),
  idoneidad_buffer_5km = round(idoneidad_buffer, 3),
  umbral_p10 = resumen_maxent$umbral_p10,
  uma_idonea = ifelse(as.logical(binario_uma), "Si", "No")
)

# 6.4 Tabla final con la abundancia relativa publicada (solo referencia)

iar <- data.frame(
  especie = c("Urocyon_cinereoargenteus", "Odocoileus_virginianus",
              "Canis_latrans", "Lynx_rufus", "Puma_concolor"),
  IAR = c(23.85, 7.22, 3.44, 2.34, 0.14)
)

tabla_uma <- merge(tabla_uma, iar, by = "especie")
tabla_uma <- tabla_uma[order(-tabla_uma$IAR), ]

tabla_uma

write.csv(tabla_uma, "results/tables/03_idoneidad_uma.csv", row.names = FALSE)

# Paso 7 · Figuras ---####

# Contorno de Mexico como lineas para ggplot

mexico_lineas <- as.data.frame(geom(mexico))
mexico_lineas$grupo <- paste(mexico_lineas$geom, mexico_lineas$part, 
                             mexico_lineas$hole)

# 7.1 Idoneidad continua

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

# 7.2 Mapas binarios (umbral p10)

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

# comando extra #
#rm(list = ls())   # borra todos los objetos del environment
#gc()              # libera la memoria que ocupaban
list.files("results/tables", pattern = "^03_", full.names = TRUE)
list.files("results/figures", pattern = "^03_", full.names = TRUE)
#file.remove(list.files("results/tables", pattern = "^03_", full.names = TRUE))
#file.remove(list.files("results/figures", pattern = "^03_", full.names = TRUE))
#if (file.exists(".RData")) file.remove(".RData")
