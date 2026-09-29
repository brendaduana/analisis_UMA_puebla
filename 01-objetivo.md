# Objetivo 1: descargar y depurar registros de presencia de GBIF

### Instala paqueterias

# Objetivo 1 · Obtención y limpieza de registros de GBIF

Flujo basado en la práctica de GBIF vista en clase (portal web → Excel → QGIS → Excel → Maxent).
Se repite una vez por especie.

**Especies:** *Urocyon cinereoargenteus*, *Odocoileus virginianus*, *Canis latrans*, *Lynx rufus*, *Puma concolor*.

## 1. Descarga en GBIF

1. Entrar a gbif.org con la cuenta.
2. Escribir el nombre de la especie en el buscador y abrir **Ocurrencias**.
3. Aplicar los filtros del panel izquierdo:
   - **Año:** 1980 – 2020 (compatible con las capas climáticas y con el periodo del antecedente, 2018–2020).
   - **Ubicación:** incluir solo registros con coordenadas.
   - **País:** México.
4. Clic en **Descargar** → formato **Datos simples de ocurrencia** → taxonomía **Catalogue of Life**
   (predeterminada).
5. Llega un enlace al correo. Se descarga un `.zip` con el archivo de ocurrencias.
6. Copiar la **cita con DOI** que aparece en la página de la descarga y pegarla en `docs/citas_GBIF.txt`.

Guardar el `.zip` en `data/raw/`.

## 2. Primera limpieza en Excel

1. Abrir el archivo de ocurrencias en Excel, comenzando:
   Datos → obtener datos → desde texto/CSV, con delimitador **Tabulador**.
3. Conservar solo 4 columnas: `gbifID`, `decimalLatitude`, `decimalLongitude`, `species`.
4. Ordenar `decimalLatitude` de mayor a menor y eliminar las filas sin coordenadas.
5. Guardar como **CSV delimitado por comas**.
6. Quitar duplicados de las columnas de laitud y longitud

786 - *Urocyon cinereoargenteus* 1496 se encontraron y quitaron valores duplicados - 1883 quedan valores unicos

787 - *Odocoileus virginianus* 1732 se encontraron y quitaron valores duplicados - 2710 quedan valores unicos

789 - *Canis latrans* 804 se encontraron y quitaron valores duplicados - 1811 quedan valores unicos

791 - *Lynx rufus* 230 se encontraron y quitaron valores duplicados - 1014 quedan valores unicos

794 - *Lynx rufus* 453 se encontraron y quitaron valores duplicados - 591 quedan valores unicos

## 3. Revisión en (QGIS)[https://qgis.org/]

1. **Capa → Añadir capa → Añadir capa de texto delimitado**.
2. Archivo CSV delimitado por comas · Campo X: `decimalLongitude` · Campo Y: `decimalLatitude` · SRC: **EPSG:4326 – WGS 84**.
3. Guardar la capa como **shapefile (.shp)** para poder editarla.
4. Activar la edición, seleccionar los puntos erróneos (en el mar, fuera del área de distribución conocida) y eliminarlos.
5. Guardar los cambios.

## 4. Archivo final en Excel

1. Archivo → Abrir → Examinar, cambia el tipo de archivo a Todos los archivos
2. Abrir el `.dbf` del shapefile en Excel.
3. Eliminar la columna `gbifID`.
4. Ordenar las columnas como **Species · Longitude · Latitude**.
5. Guardar como **CSV delimitado por comas** en `data/processed/` con el nombre de la especie
   (p. ej. `Canis_latrans.csv`).

Este archivo está listo para Maxent.

## Nota sobre temporalidad

- Las capas de WorldClim representan el clima promedio de 1970–2000. El filtro de 1980–2020 mantiene
  los registros dentro de un periodo compatible y termina donde termina el muestreo del antecedente.
- El nicho climático se estima con clima promedio de largo plazo, por lo que no se empareja año por
  año con los registros.
- Limitación a declarar: la mayoría de los registros recientes (posteriores a 2010) queda fuera del
  periodo de las capas climáticas.
