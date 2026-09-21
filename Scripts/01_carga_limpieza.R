# ============================================================
# TP Integrador - Módulo R (Maestría en Econometría, UTDT, 2026)
# 01. Carga, limpieza y construcción de la muestra de estimación
#
# Salidas: data/datos_panel.rds, data/datos_est.rds
# ============================================================

rm(list = ls())
set.seed(2026)

library(dplyr)
library(readr)
library(stringr)

dir.create("data", showWarnings = FALSE)

# ------------------------------------------------------------
# 1. Descarga (una sola vez) y lectura de los datos
#    Fuente: MEN, "Estadísticas en Educación en Preescolar,
#    Básica y Media" (Datos Abiertos Colombia, id nudc-7mev)
# ------------------------------------------------------------

url <- "https://www.datos.gov.co/resource/nudc-7mev.csv?$limit=50000"
ruta_raw <- "data/men_estadisticas_educacion.csv"

if (!file.exists(ruta_raw)) {
  download.file(url, destfile = ruta_raw, mode = "wb")
}

# La población 5-16 trae separadores de miles mezclados (puntos y
# comas), por lo que se lee como texto y se convierte después.
datos_importados <- read_csv(
  ruta_raw,
  col_types = cols(poblaci_n_5_16 = col_character())
)

# ------------------------------------------------------------
# 2. Panel municipio-año
#    - Códigos DIVIPOLA a 5 dígitos (algunos venían con 4).
#    - Se excluye el agregado nacional (código "0").
#    - Población: se eliminan separadores y se pasa a numérico.
# ------------------------------------------------------------

datos_panel <- datos_importados %>%
  mutate(
    codigo_municipio = str_pad(
      c_digo_municipio,
      width = 5,
      side = "left",
      pad = "0"
    ),
    poblacion_5_16 = as.numeric(
      str_remove_all(poblaci_n_5_16, "[\\.,]")
    )
  ) %>%
  filter(codigo_municipio != "00000")

# Bandera: cobertura neta en media igual a cero (57 filas, 12 unidades
# de Amazonas, Guainía y Vaupés). Se conserva para trazabilidad.
datos_panel <- datos_panel %>%
  mutate(cobertura_cero = coalesce(cobertura_neta_media == 0, FALSE))

# ------------------------------------------------------------
# 3. Verificaciones
# ------------------------------------------------------------

stopifnot(
  nrow(datos_panel) == 15704,
  n_distinct(datos_panel$codigo_municipio) == 1123,
  sum(duplicated(paste(datos_panel$codigo_municipio, datos_panel$a_o))) == 0,
  sum(datos_panel$cobertura_cero) == 57
)

# ------------------------------------------------------------
# 4. Muestra de estimación (eliminación de casos incompletos)
#    No se imputa, no se winsorizan extremos y no se recorta
#    ningún año. Se excluyen deserción NA, cobertura NA y
#    cobertura igual a cero.
# ------------------------------------------------------------

datos_est <- datos_panel %>%
  filter(
    !is.na(deserci_n_media),
    !is.na(cobertura_neta_media),
    !cobertura_cero
  )

stopifnot(nrow(datos_est) == 14908)

# ------------------------------------------------------------
# 5. Guardar objetos para los scripts siguientes
# ------------------------------------------------------------

saveRDS(datos_panel, "data/datos_panel.rds")
saveRDS(datos_est, "data/datos_est.rds")
