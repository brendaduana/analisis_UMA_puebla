# Objetivo 1: descargar y depurar registros de presencia de GBIF

### Instala paqueterias

```R
# install.packages(c("rgbif", "CoordinateCleaner", "dplyr", "readr", "terra"))
library(rgbif)
library(CoordinateCleaner)
library(dplyr)
library(readr)
library(terra)
```

### Crea directorios de entrada

```
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("docs", showWarnings = FALSE)
```

# ---- 1. Credenciales de GBIF ------------------------------------------------
# Crea una cuenta en https://www.gbif.org y guarda tus datos UNA vez con:
#   usethis::edit_r_environ()
# y agrega estas tres líneas al archivo que se abre (luego reinicia R):
#   GBIF_USER=tu_usuario
#   GBIF_PWD=tu_contraseña
#   GBIF_EMAIL=tu_correo
# Nunca escribas la contraseña dentro del script ni la subas a GitHub.

# ---- 2. Especies y claves taxonómicas ---------------------------------------
especies <- c("Urocyon cinereoargenteus",
              "Odocoileus virginianus",
              "Canis latrans",
              "Lynx rufus",
              "Puma concolor")

claves <- sapply(especies, function(sp) name_backbone(name = sp)$usageKey)
print(claves)  # revisa que ninguna sea NA

# ---- 3. Parámetros de temporalidad -----------------------------------------
# Periodo alineado con las variables climáticas y con el antecedente
# (Plata-Pérez et al. 2024, muestreo 2018–2020). Ver README / docs.
anio_inicio <- 1980
anio_fin    <- 2020

# ---- 4. Solicitud de descarga (una sola, con DOI citable) -------------------
# Se descarga el área de distribución completa (no solo México) para no
# truncar el nicho climático de especies con rangos amplios.
descarga <- occ_download(
  pred_in("taxonKey", claves),
  pred("hasCoordinate", TRUE),
  pred("hasGeospatialIssue", FALSE),
  pred("occurrenceStatus", "PRESENT"),
  pred_in("basisOfRecord", c("HUMAN_OBSERVATION", "PRESERVED_SPECIMEN",
                             "MACHINE_OBSERVATION", "OCCURRENCE")),
  pred_gte("year", anio_inicio),
  pred_lte("year", anio_fin),
  pred_lte("coordinateUncertaintyInMeters", 1000),  # ~ resolución 30 s
  format = "SIMPLE_CSV"
)

# La descarga tarda de minutos a horas; esta línea espera a que termine
occ_download_wait(descarga)

# Guarda la cita con DOI (obligatoria para reproducibilidad)
cita <- gbif_citation(occ_download_meta(descarga))$download
writeLines(cita, "docs/cita_GBIF.txt")
print(cita)

# ---- 5. Importar ------------------------------------------------------------
crudo <- occ_download_get(descarga, path = "data/raw", overwrite = TRUE) |>
  occ_download_import()

registros <- crudo |>
  select(gbifID, species, decimalLongitude, decimalLatitude, year,
         basisOfRecord, coordinateUncertaintyInMeters, countryCode) |>
  filter(species %in% especies)

cat("Registros crudos por especie:\n")
print(table(registros$species))

# ---- 6. Limpieza de coordenadas ---------------------------------------------
limpios <- registros |>
  distinct(species, decimalLongitude, decimalLatitude, .keep_all = TRUE) |>
  clean_coordinates(lon = "decimalLongitude", lat = "decimalLatitude",
                    species = "species", countries = "countryCode",
                    tests = c("capitals", "centroids", "equal", "gbif",
                              "institutions", "zeros", "seas"),
                    value = "clean")

# ---- 7. Adelgazamiento espacial (1 registro por celda de ~1 km) -------------
# Reduce el sesgo de muestreo (p. ej. muchos registros en ciudades)
# usando la misma rejilla que las variables climáticas (30 s).
rejilla <- rast(resolution = 30 / 3600)  # rejilla global de 30 s de arco

limpios$celda <- cellFromXY(rejilla,
                            as.matrix(limpios[, c("decimalLongitude",
                                                  "decimalLatitude")]))
adelgazados <- limpios |>
  distinct(species, celda, .keep_all = TRUE) |>
  select(-celda)

cat("Registros finales por especie:\n")
print(table(adelgazados$species))

# ---- 8. Guardar -------------------------------------------------------------
# Formato para Maxent: especie, longitud, latitud (como en la práctica de Q)
final <- adelgazados |>
  transmute(species,
            longitude = decimalLongitude,
            latitude  = decimalLatitude,
            year)

write_csv(final, "data/processed/registros_limpios.csv")
write_csv(select(final, -year), "data/processed/registros_maxent.csv")
