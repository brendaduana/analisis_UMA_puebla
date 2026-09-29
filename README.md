# Análisis UMA Puebla

Proyecto final del curso **Bases ecológicas y genómicas de la interacción organismo-ambiente**
Posgrado en Ciencias Biológicas
Uiversidad Nacional Autónoma de México - semestre 2027-1

## UMA Santa Cruz Nuevo, Puebla

En la Unidad de Manejo para la Conservación de la Vida Silvestre (UMA) ubicada en Santa Cruz Nuevo, Puebla, han registrado con 22 cámaras trampa la abundancia relativa (IAR) y el traslape de actividad del venado cola blanca (_Odocoileus virginianus_) y sus depredadores [(Plata-Perez et al, 2024)](https://archivo.revistas.ucr.ac.cr/index.php/rbt/article/view/55515/59501).

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

1. Obtener y depurar registros de presencia de GBIF para las cinco especies --> Q MA

2. Seleccionar variables bioclimáticas no correlacionadas (correlación de Spearman y PCA) --> Q MA

3. Construir modelos de nicho ecológico (Maxent) y proyectar la UMA. --> Q MA

4. Estimar la posición de la UMA dentro del nicho climático de cada especie como su distancia al centroide del elipsoide de nicho en el espacio ambiental. --> V

5. Comparar el traslape de nicho climático entre el venado y sus depredadores con el traslape temporal (Dhat1) reportado. --> V (lectura de amplitud y posicion de nicho)
   
6. Generar un repositorio que documente el flujo de trabajo y de desiciones para llegar a responder a la pregunta de ivestigación --> MA

*como idea guía es: que este proyecto pueda ayudar a comprender el punto ecológico al comparar la detección de mamiferos por ambos metodos de muestreo/monitoreo y ver si este script se puede reutilizar con datos que obtenga en un futuro.

