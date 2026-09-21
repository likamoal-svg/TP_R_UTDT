# ============================================================
# TP Integrador - Módulo R (Maestría en Econometría, UTDT, 2026)
# 02. Análisis exploratorio de datos (EDA)
#
# Requiere haber corrido 01_carga_limpieza.R.
# Salidas: outputs/figuras/*.png, outputs/tablas/*.csv
# ============================================================

rm(list = ls())
set.seed(2026)

library(dplyr)
library(ggplot2)
library(readr)

dir.create("outputs/figuras", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tablas", recursive = TRUE, showWarnings = FALSE)

datos_panel <- readRDS("data/datos_panel.rds")
datos_est <- readRDS("data/datos_est.rds")

# ------------------------------------------------------------
# 1. Distribuciones univariadas por año
# ------------------------------------------------------------

g_desercion <- ggplot(
  datos_panel,
  aes(x = factor(a_o), y = deserci_n_media)
) +
  geom_boxplot(na.rm = TRUE) +
  labs(
    title = "Distribución de la tasa de deserción en los municipios",
    x = "Año",
    y = "Tasa de deserción en educación media"
  ) +
  theme_minimal()

g_cobertura <- ggplot(
  datos_panel,
  aes(x = factor(a_o), y = cobertura_neta_media)
) +
  geom_boxplot(na.rm = TRUE) +
  labs(
    title = "Distribución de la cobertura neta en educación media",
    x = "Año",
    y = "Cobertura neta en educación media"
  ) +
  theme_minimal()

ggsave("outputs/figuras/01_boxplot_desercion.png", g_desercion,
       width = 9, height = 5, dpi = 200)
ggsave("outputs/figuras/02_boxplot_cobertura.png", g_cobertura,
       width = 9, height = 5, dpi = 200)

# ------------------------------------------------------------
# 2. Faltantes, ceros y muestra de estimación por año
# ------------------------------------------------------------

tabla_faltantes <- datos_panel %>%
  group_by(a_o) %>%
  summarise(
    n_observaciones = n(),
    desercion_na = sum(is.na(deserci_n_media)),
    cobertura_na = sum(is.na(cobertura_neta_media)),
    n_cobertura_cero = sum(cobertura_cero),
    muestra_estimacion = sum(
      !is.na(deserci_n_media) &
        !is.na(cobertura_neta_media) &
        !cobertura_cero
    ),
    .groups = "drop"
  )

write_csv(tabla_faltantes, "outputs/tablas/faltantes_por_anio.csv")

# Unidades con cobertura igual a cero
tabla_ceros <- datos_panel %>%
  group_by(codigo_municipio, municipio, departamento) %>%
  filter(any(cobertura_neta_media == 0, na.rm = TRUE)) %>%
  summarise(
    n_anios = n(),
    anios_cobertura_cero = sum(cobertura_neta_media == 0, na.rm = TRUE),
    anios_cobertura_na = sum(is.na(cobertura_neta_media)),
    anios_desercion_na = sum(is.na(deserci_n_media)),
    .groups = "drop"
  ) %>%
  arrange(departamento, municipio)

write_csv(tabla_ceros, "outputs/tablas/unidades_cobertura_cero.csv")

# ------------------------------------------------------------
# 3. Relación bivariada: cobertura vs. deserción, por año
# ------------------------------------------------------------

g_dispersion <- ggplot(
  datos_est,
  aes(x = cobertura_neta_media, y = deserci_n_media)
) +
  geom_point(alpha = 0.15, size = 0.8) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "red") +
  facet_wrap(~ a_o) +
  labs(
    title = "Cobertura neta en media vs. deserción, por año",
    x = "Cobertura neta en educación media",
    y = "Tasa de deserción en media"
  ) +
  theme_minimal()

ggsave("outputs/figuras/03_dispersion_por_anio.png", g_dispersion,
       width = 12, height = 8, dpi = 200)

# ------------------------------------------------------------
# 4. Variación within: desviaciones respecto a la media municipal
# ------------------------------------------------------------

g_within <- datos_est %>%
  group_by(codigo_municipio) %>%
  mutate(
    cobertura_within = cobertura_neta_media - mean(cobertura_neta_media),
    desercion_within = deserci_n_media - mean(deserci_n_media)
  ) %>%
  ungroup() %>%
  ggplot(aes(x = cobertura_within, y = desercion_within)) +
  geom_point(alpha = 0.1, size = 0.8) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "red") +
  labs(
    title = "Variación within: desviaciones respecto a la media de cada municipio",
    x = "Cobertura neta en media (desviación de la media municipal)",
    y = "Deserción en media (desviación de la media municipal)"
  ) +
  theme_minimal()

ggsave("outputs/figuras/04_variacion_within.png", g_within,
       width = 9, height = 5, dpi = 200)
