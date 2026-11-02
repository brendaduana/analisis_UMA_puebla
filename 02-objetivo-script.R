# Objetivo 2: Seleccion de variables bioclimaticas ---####

# Nicho climatico y abundancia de mamiferos en la UMA Santa Cruz Nuevo

# Los pasos 1 y 2 (capas de WorldClim, descargadas en el objetivo 1, y mascara de Mexico de CONABIO) se hacen
# fuera de R; ver la guia.

# Paquetes ---####

# Los siguiente comandos ayudan a verificar si una paqueteria esta instalada
# si esta no se encuentra, la instalará.

if (!require("terra")) install.packages("terra")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("reshape2")) install.packages("reshape2")
if (!require("factoextra")) install.packages("factoextra")  # visualizacion PCA
if (!require("psych")) install.packages("psych")            # analisis de cargas

# Cargar paqueterias

library(terra)
library(ggplot2)
library(reshape2)
library(factoextra)
library(psych)

# Directorio de trabajo: al abrir el proyecto de RStudio (.Rproj), R trabaja
# automaticamente desde 03-analisis-uma-rstudio; no se necesita setwd().

getwd()

dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)

# Paso 1 - Verificar las capas WorldClim ---####
# Paso 2 - Crear la máscara de México (CONABIO) ---####
# Paso 3 - Cargar las capas de WorldClim ---####

# 3.1 Lista los archivos

bios <- list.files(
  path = "../00-data-worldclim",
  pattern = "\\.tif$",
  full.names = TRUE
)

bios


# 3.2  Leer las capas y unirlo en un solo objeto de 19 capas


bios <- rast(bios)

bios

# 3.3 Acorta los nombres: wc2.1_2.5m_bio_1 --> BIO1

names(bios) <- sub("wc2.1_2.5m_bio_", "BIO", names(bios))
names(bios)

# Paso 4 · Recortar a Mexico ---####

# (Practica 1 - V: crop + mask con un shapefile)

mexico <- vect("../00-data-map-mex/destdv1gw.shp")

nrow(mexico)   # numero de poligonos (un estado por fila)
plot(mexico)   # revisar que se vea la Republica completa


bios_mx <- mask(
  crop(bios, mexico),
  mexico
)

png("results/figures/02_recorte_mexico_bio1.png", width = 1600, height = 1200, res = 200)
plot(bios_mx[["BIO1"]])
plot(mexico, add = TRUE)
dev.off()

# da como resultado el mapa de mexico con la variable BIO1

# Paso 5 · Extraer valores y muestrear 10,000 celdas ---####
# (Practica 1 - V)

# 5.1 Convertir las capas en tabla

bios_mx_extract <- as.data.frame(
  bios_mx,
  xy = TRUE,
  na.rm = TRUE
)

dim(bios_mx_extract)

# 5.2 Toma de muestra aleatoria

set.seed(123)

sample_df <- function(x, n = 10000) {
  if (nrow(x) <= n) {
    return(x)
  }
  x[sample(nrow(x), n), ]
}

clima <- sample_df(bios_mx_extract)
dim(clima)


# Paso 6 · Seleccionar y escalar las variables ---####
# (Q)

# Solo las 19 variables bioclimaticas (sin las coordenadas x, y)
clima_variables <- clima[, names(bios)]

# scale() transforma a valores Z: media 0 y DE = 1
clima_variables <- scale(clima_variables)


# Paso 7 · Correlacion de Spearman ---####
# (Q)

# 7.1 Matriz de correlacion

cor_clima <- cor(clima_variables, method = "spearman")

cor_clima_2dec <- round(cor_clima, 2)

write.csv(cor_clima_2dec, "results/tables/02_matriz_spearman.csv")

# 7.2 Preparar la matriz para el heatmap

get_upper_tri <- function(cor_clima_2dec) {
  cor_clima_2dec[lower.tri(cor_clima_2dec)] <- NA
  return(cor_clima_2dec)
}

# Reordenar por clustering jerarquico para ver bloques de variables relacionadas

reorder_cor_clima <- function(cor_clima_2dec) {
  dd <- as.dist((1 - cor_clima_2dec) / 2)
  hc <- hclust(dd)
  cor_clima_2dec <- cor_clima_2dec[hc$order, hc$order]
  return(cor_clima_2dec)
}

cor_clima_2dec <- reorder_cor_clima(cor_clima_2dec)

upper_tri <- get_upper_tri(cor_clima_2dec)

# 7.3 Grafica el heatmap

melted_tri_cor_clima <- melt(upper_tri, na.rm = TRUE)

ggheatmap <- ggplot(data = melted_tri_cor_clima, aes(Var2, Var1, fill = value)) +
  geom_tile(color = "#f7f7f7") +
  scale_fill_gradient2(low = "#6baed6", mid = "white", high = "#084594",
                       midpoint = 0, limits = c(-1, 1),
                       space = "Lab",
                       name = "Spearman\nCorrelation") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, vjust = 1, size = 10, hjust = 1)) +
  coord_fixed()

print(ggheatmap)

ggsave("results/figures/02_heatmap_spearman.png", plot = ggheatmap,
       width = 8, height = 6, dpi = 300)


# Paso 8 · PCA: Analisis de Componentes Principales ---####
# (Q)

# 8.1 Calcular el PCA

pca_result <- prcomp(clima_variables, center = TRUE, scale. = TRUE)

summary(pca_result)

eig <- get_eigenvalue(pca_result)

round(eig, 2)

# 8.2 Scree plot: % de varianza explicada por cada componente

screen_plot <- fviz_eig(pca_result, addlabels = TRUE, ylim = c(0, 50))

print(screen_plot)

ggsave("results/figures/02_screen_plot.png", plot = screen_plot,
       width = 8, height = 6, dpi = 300)

# 8.3 Biplot: 
# puntos = celdas de Mexico, 
# flechas = variables
# label = "var" muestra solo el nombre de las variables (con 10,000 celdas
# las etiquetas de los puntos no se leerian)

biplot <- fviz_pca_biplot(pca_result, repel = TRUE, label = "var",
                          col.var = "#084594",
                          col.ind = "#6baed6")

print(biplot)

ggsave("results/figures/02_biplot.png", plot = biplot,
       width = 8, height = 6, dpi = 300)

# 8.4 Cargas de cada variable en cada componente

pca_loadings <- data.frame(pca_result$rotation)

print(round(pca_loadings[, 1:4], 2))

write.csv(round(pca_loadings, 3), "results/tables/02_cargas_pca.csv")

# 8.5 Variables "importantes" segun el PCA (carga > 0.3)

pca_importance <- apply(abs(pca_result$rotation), 2, function(x) which(x > 0.3))

print(pca_importance[1:4])

# Paso 9. Seleccion final de variables ---####

# Una variable por bloque de correlacion (Paso 7), con mayor carga en su
# componente del PCA (Pasos 8.4-8.5)
variables_seleccionadas <- c("BIO5", "BIO6", "BIO12", "BIO15", "BIO17")

# Revisar que ningun par supere |rho| > 0.8
round(cor_clima[variables_seleccionadas, variables_seleccionadas], 2)

write.csv(data.frame(variable = variables_seleccionadas),
          "results/tables/02_variables_seleccionadas.csv", row.names = FALSE)
