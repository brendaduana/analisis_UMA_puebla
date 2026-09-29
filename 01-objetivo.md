# Objetivo 1 · Obtención y limpieza de registros de GBIF

El primer flujo de trabajo consiste en lo siguiente:

1. Descargar los registros de GBIF.
2. Hacer una primera limpieza en Excel.
3. Revisar los puntos en QGIS.
4. Hacer una limpieza final en Excel.
5. Descargar las capas de WorldClim.

## Estructura de carpetas

Todos los archivos se guardan dentro de `C:\analisis_uma\`:

## 1. Descarga en GBIF

Repetir este paso una vez por especie.

**Especies:** *Urocyon cinereoargenteus*, *Odocoileus virginianus*, *Canis latrans*, *Lynx rufus*, *Puma concolor*.

1. Entrar a [gbif.org](https://www.gbif.org) e iniciar sesión (o crear una cuenta si aún no se tiene).
2. Escribir el nombre de la especie en el buscador y abrir la pestaña **Ocurrencias**.
3. Aplicar los filtros del panel izquierdo:
   - **Año:** 1980–2020.
   - **País:** México.
4. Hacer clic en **Descargar** → formato **Datos simples de ocurrencia** → taxonomía **Catalogue of Life** (predeterminada).
5. Esperar el correo de GBIF con el enlace y descargar el archivo `.zip`.
6. Copiar la **cita con DOI** que aparece en la página de la descarga.
7. Guardar el `.zip` y la cita en `00-data-species/`.

## 2. Primera limpieza en Excel

Repetir este paso una vez por especie.

**Especies:** *Urocyon cinereoargenteus*, *Odocoileus virginianus*, *Canis latrans*, *Lynx rufus*, *Puma concolor*.

1. Abrir el archivo de ocurrencias desde **Datos → Obtener datos → Desde texto/CSV**, con delimitador **Tabulador**.
2. Conservar solo cuatro columnas: `gbifID`, `decimalLatitude`, `decimalLongitude` y `species`.
3. Ordenar `decimalLatitude` de mayor a menor y eliminar las filas sin coordenadas.
4. Quitar los duplicados considerando las columnas de latitud y longitud (**Datos → Quitar duplicados**).
5. Guardar como **CSV delimitado por comas** en `01-data-unclean-qgis/`.

**Resultados de la eliminación de duplicados:**

| Descarga | Especie | Duplicados eliminados | Registros únicos |
|---|---|---:|---:|
| 0009786 | *Urocyon cinereoargenteus* | 1 496 | 1 883 |
| 0009787 | *Odocoileus virginianus* | 1 732 | 2 710 |
| 0009789 | *Canis latrans* | 804 | 1 811 |
| 0009791 | *Lynx rufus* | 230 | 1 014 |
| 0009794 | *Puma concolor* | 453 | 591 |

## 3. Revisar en [QGIS](https://qgis.org/).

Repetir este paso una vez por especie.

**Especies:** *Urocyon cinereoargenteus*, *Odocoileus virginianus*, *Canis latrans*, *Lynx rufus*, *Puma concolor*.

1. Ir a **Capa → Añadir capa → Añadir capa de texto delimitado**.
2. Cargar el CSV de `01-data-unclean-qgis/` con esta configuración: archivo CSV delimitado por comas · Campo X: `decimalLongitude` · Campo Y: `decimalLatitude` · SRC: **EPSG:4326 – WGS 84**.
3. Exportar la capa como **shapefile (.shp)** en `02-data-clean-qgis/` para poder editarla.
4. Activar la edición, seleccionar los puntos erróneos (en el mar o fuera del área de distribución conocida) y eliminarlos.
5. Guardar los cambios.

## 4. Archivo final en Excel

1. Ir a **Archivo → Abrir → Examinar** y cambiar el tipo de archivo a **Todos los archivos**.
2. Abrir el archivo `.dbf` del shapefile desde `02-data-clean-qgis/`.
3. Eliminar la columna `gbifID`.
4. Ordenar las columnas como **species · longitude · latitude**.
5. Guardar como **CSV delimitado por comas** en `02-data-clean-qgis/`.

**Resultados de la depuración en QGIS:**

| Archivo | Especie | Registros antes de QGIS | Puntos eliminados | Registros finales |
|---|---|---:|---:|---:|
| `0009786-urocyon-cinereoargenteus.csv` | *Urocyon cinereoargenteus* | 1 883 | 9 | 1 874 |
| `0009787-odocoileus-virginianus.csv` | *Odocoileus virginianus* | 2 710 | 29 | 2 681 |
| `0009789-canis-latrans.csv` | *Canis latrans* | 1 811 | 12 | 1 799 |
| `0009791-lynx-rufus.csv` | *Lynx rufus* | 1 014 | 1 | 1 013 |
| `0009794-puma-concolor.csv` | *Puma concolor* | 591 | 0 | 591 |

Estos cinco archivos CSV son la entrada de registros para Maxent.

## 5. Descarga de WorldClim

1. Entrar a la página de [WorldClim 2.1](https://www.worldclim.org/data/worldclim21.html).
2. En la sección de [variables bioclimáticas](https://www.worldclim.org/data/bioclim.html), descargar el archivo de resolución **2.5 minutos** (~4.5 km).
3. Descomprimir el `.zip`. Contiene 19 archivos GeoTIFF (`.tif`), uno por cada variable bioclimática (BIO1–BIO19).
4. Guardar los archivos en `00-data-worldclim/`.

| Parámetro | Valor |
|---|---|
| Versión | WorldClim 2.1 |
| Resolución | 2.5 minutos |
| Variables | 19 variables bioclimáticas (BIO1–BIO19) |
| Periodo | Promedio 1970–2000 |
| Formato | GeoTIFF (`.tif`) |

## Nota sobre la temporalidad de los datos

- Las capas de WorldClim representan el clima promedio del periodo 1970–2000. El filtro de 1980–2020 mantiene los registros en un periodo compatible y coincide con el fin del muestreo del estudio de antecedente.
- El nicho climático se estima con clima promedio de largo plazo, por lo que los registros no se emparejan año por año con las capas.
- **Limitación:** los registros posteriores a 2000 quedan fuera del periodo que cubren las capas climáticas.
