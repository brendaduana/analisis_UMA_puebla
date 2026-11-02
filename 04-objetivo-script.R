# Objetivo 4: Posicion y amplitud del nicho climatico, y posicion de la UMA ---####

# Nicho climatico y abundancia de mamiferos en la UMA Santa Cruz Nuevo

# Guia paso a paso: docs/04-objetivo.md
# Cada seccion "Paso N" corresponde al mismo paso de la guia.
#
# Origen del codigo:
#   Pasos 3-4: Practica 2.1, amplitud y posicion del nicho (analisis OMI) - V
#              (dudi.pca, niche, niche.param de ade4)
#   Paso 5:    unico paso que no esta en la practica: ubica a la UMA en el mismo
#              espacio de la PCA (suprow de ade4 y distancia euclidiana)
#   Paso 6:    Spearman, como en Q (objetivo 2)
#
# Requiere:
#   - objetivo 2: results/tables/02_variables_seleccionadas.csv
#   - objetivo 3: ../04-maxent/capas_asc/*.asc y
#                 ../04-maxent/presence/presencias_5spp.csv
# Maxent no se usa en este objetivo.

# Paso 0 · Paquetes ---####

if (!require("terra")) install.packages("terra")
if (!require("ade4")) install.packages("ade4")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("ggrepel")) install.packages("ggrepel")   # etiquetas que no se encimen

library(terra)
library(ade4)
library(ggplot2)
library(ggrepel)

# Limpieza (opcional, solo para empezar de cero) ---####
# rm(list = ls())
# gc()
# file.remove(list.files("results/tables", pattern = "^04_", full.names = TRUE))
# file.remove(list.files("results/figures", pattern = "^04_", full.names = TRUE))
# if (file.exists(".RData")) file.remove(".RData")

# Directorio de trabajo: 03-analisis-uma-rstudio (se abre con el .Rproj)

getwd()

dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)

# Paso 1 · Cargar los insumos de los objetivos 2 y 3 ---####

# 1.1 Variables elegidas en el objetivo 2

variables_seleccionadas <- read.csv("results/tables/02_variables_seleccionadas.csv")$variable

variables_seleccionadas

# 1.2 Capas climaticas de Mexico: los .asc que se exportaron para Maxent

archivos_asc <- file.path("../04-maxent/capas_asc",
                          paste0(variables_seleccionadas, ".asc"))

file.exists(archivos_asc)   # deben ser 5 TRUE

capas <- rast(archivos_asc)
names(capas) <- variables_seleccionadas
crs(capas) <- "EPSG:4326"   # los .asc no traen sistema de coordenadas

capas

# 1.3 Presencias que uso Maxent (7,947 registros)

presencias <- read.csv("../04-maxent/presence/presencias_5spp.csv")

presencias$species <- gsub(" ", "_", presencias$species)   # igual que los archivos de Maxent

especies <- sort(unique(presencias$species))

especies
nrow(presencias)   # 7947

# Paso 2 · Sitios y tabla de especies ---####
# (Practica 2.1 - V: base "drome", con $env y $fish)

# 2.1 Una presencia por celda, igual que Maxent (objetivo 3, paso 2.3)

presencias$celda <- cellFromXY(
  capas,
  as.matrix(presencias[, c("longitude", "latitude")])
)

presencias_u <- presencias[!duplicated(presencias[, c("species", "celda")]), ]

table(presencias_u$species)   # 1060, 541, 1183, 378, 1203

# 2.2 Sitios = todas las celdas de Mexico con dato (equivale a drome$env)

sitios <- as.data.frame(capas, cells = TRUE, na.rm = TRUE)

nrow(sitios)   # 102316 celdas, las mismas de Maxent

rownames(sitios) <- paste0("celda_", sitios$cell)

env_sitios <- sitios[, variables_seleccionadas]

head(env_sitios)

# 2.3 Tabla de especies por sitio: 1 = hay presencia en la celda, 0 = sin registro
# (equivale a drome$fish)

tabla_spp <- as.data.frame(sapply(especies, function(sp) {
  as.numeric(sitios$cell %in% presencias_u$celda[presencias_u$species == sp])
}))
rownames(tabla_spp) <- rownames(sitios)

colSums(tabla_spp)   # debe coincidir con las celdas unicas del paso 2.1
head(tabla_spp)

# Paso 3 · PCA del ambiente ---####
# (Practica 2.1 - V)

# 3.1 PCA de las 5 variables en las celdas de Mexico (variables estandarizadas)

pca_mx <- dudi.pca(env_sitios, scale = TRUE, scannf = FALSE, nf = 5)

# 3.2 % de varianza de cada componente

round(100 * pca_mx$eig / sum(pca_mx$eig), 1)

# 3.3 Cargas de las variables

round(pca_mx$c1, 2)

# Paso 4 · Posicion y amplitud del nicho de cada especie (OMI) ---####
# (Practica 2.1 - V)

# 4.1 Analisis OMI

niche_description <- niche(pca_mx, tabla_spp, scannf = FALSE)

niche_description$nf   # ejes que conserva niche(): 2 por defecto. Tol se mide solo en esos 2 ejes

# 4.2 Parametros del nicho: OMI = posicion (marginalidad), Tol = amplitud

params <- niche.param(niche_description)

colnames(params)   # revisar los nombres exactos de las columnas

round(params, 2)

write.csv(round(params, 3), "results/tables/04_parametros_nicho.csv")

# Paso 5 · Posicion de la UMA en el espacio de la PCA ---####
# (paso propio: usa el mismo espacio ambiental de la practica)

# 5.1 Clima de la UMA (Plata-Perez et al. 2024: 18°17'44" N, 97°48'35" W)

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

# 5.2 Proyectar la UMA en la PCA (suprow usa el mismo centrado y escala del PCA)

uma_pca <- as.numeric(suprow(pca_mx, clima_uma)$lisup)
uma_buffer_pca <- as.numeric(suprow(pca_mx, clima_uma_buffer)$lisup)

round(uma_pca, 2)

# 5.3 Centro del nicho de cada especie en la PCA: promedio de las celdas con presencia

pesos <- sweep(as.matrix(tabla_spp), 2, colSums(tabla_spp), "/")   # cada columna suma 1

centroides_pca <- t(pesos) %*% as.matrix(pca_mx$li)

round(centroides_pca, 2)

# Comprobacion: la distancia al cuadrado de cada centro al origen es la marginalidad (OMI)

round(rowSums(centroides_pca^2), 2)
round(params[, "OMI"], 2)

# 5.4 Distancia de la UMA al centro de cada especie, frente a la de sus registros

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

# Paso 6 · Posicion, amplitud y abundancia relativa ---####

# 6.1 Tabla final con la abundancia relativa publicada (solo referencia)

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

# 6.2 Correlaciones de Spearman con el IAR (solo descriptivas: n = 5 especies)

cor(tabla_nicho$OMI, tabla_nicho$IAR, method = "spearman")             # posicion
cor(tabla_nicho$Tol, tabla_nicho$IAR, method = "spearman")             # amplitud
cor(tabla_nicho$d_uma, tabla_nicho$IAR, method = "spearman")           # UMA (distancia)
cor(tabla_nicho$percentil_uma, tabla_nicho$IAR, method = "spearman")   # UMA (percentil)

# Paso 7 · Figuras ---####

# 7.1 Espacio del nicho: celdas de Mexico, centro de cada especie y UMA
# (Practica 2.1 - V: flechas = variables, puntos = nichos; tamano = tolerancia)

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
  coord_fixed(xlim = c(-2.6, 2), ylim = c(-1.5, 3)) +   # encuadre donde estan las especies
  labs(x = paste0("Eje 1 (", varianza_pc[1], "%)"),
       y = paste0("Eje 2 (", varianza_pc[2], "%)")) +
  theme_minimal()

print(fig_nicho)

ggsave("results/figures/04_nicho_omi.png", plot = fig_nicho,
       width = 9, height = 7, dpi = 300)

# 7.2 Distancia de la UMA al centro del nicho (barra) frente al limite de sus registros (rombo)

distancias <- merge(posicion, iar, by = "especie")
distancias <- distancias[order(-distancias$IAR), ]
distancias$especie <- factor(gsub("_", " ", distancias$especie),
                             levels = gsub("_", " ", distancias$especie))   # orden por IAR

fig_distancias <- ggplot(distancias, aes(x = especie)) +
  geom_col(aes(y = d_uma), fill = "#e6550d", width = 0.6) +
  geom_point(aes(y = d_p95_registros), shape = 18, size = 4) +
  labs(x = NULL, y = "Distancia al centro del nicho (espacio de la PCA)") +
  theme_minimal() +
  theme(axis.text.x = element_text(face = "italic", angle = 20, hjust = 1))

print(fig_distancias)

ggsave("results/figures/04_distancia_uma.png", plot = fig_distancias,
       width = 8, height = 5, dpi = 300)

# Verificacion final
list.files("results/tables", pattern = "^04_")    # 4 archivos
list.files("results/figures", pattern = "^04_")   # 2 archivos

