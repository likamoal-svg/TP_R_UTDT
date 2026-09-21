# ============================================================
# TP Integrador - Módulo R (Maestría en Econometría, UTDT, 2026)
# 03. Modelos de datos de panel, robustez y diagnósticos
#
# Requiere haber corrido 01_carga_limpieza.R.
# Salidas: outputs/figuras/*.png, outputs/tablas/*.csv
# ============================================================

rm(list = ls())
set.seed(2026)

library(dplyr)
library(ggplot2)
library(readr)
library(plm)
library(lmtest)
library(sandwich)

dir.create("outputs/figuras", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tablas", recursive = TRUE, showWarnings = FALSE)

datos_panel <- readRDS("data/datos_panel.rds")
datos_est <- readRDS("data/datos_est.rds")

# panel municipio-año
declarar_panel <- function(df) {
  pdata.frame(as.data.frame(df), index = c("codigo_municipio", "a_o"))
}

# test t con errores robustos HC1 agrupados por municipio
robusto <- function(modelo) {
  coeftest(modelo, vcov = vcovHC(modelo, type = "HC1", cluster = "group"))
}

# ------------------------------------------------------------
# 1. panel (no balanceado)
# ------------------------------------------------------------

datos_plm <- declarar_panel(datos_est)
pdim(datos_plm)   # n = 1118, T = 1-14, N = 14908

# ------------------------------------------------------------
# 2. Pooled OLS, efectos fijos, efectos aleatorios
# ------------------------------------------------------------

formula_base <- deserci_n_media ~ cobertura_neta_media

pooled <- plm(formula_base, data = datos_plm, model = "pooling")
fe     <- plm(formula_base, data = datos_plm, model = "within")
re     <- plm(formula_base, data = datos_plm, model = "random")

robusto(pooled)
robusto(fe)
robusto(re)

# Hausman: FE vs. RE
phtest(fe, re)

# ------------------------------------------------------------
# 3. Efectos fijos de municipio y de año (especificación base)
# ------------------------------------------------------------

twoways <- plm(
  formula_base,
  data = datos_plm,
  model = "within",
  effect = "twoways"
)

robusto(twoways)

# Comparación entre las especificaciones con efectos fijos (municipio,
# y municipio + año)
pFtest(twoways, fe)

# Ajuste
summary(twoways)

# ------------------------------------------------------------
# 3b. Diagnóstico: ¿hay suficiente variación within en la cobertura?
# ------------------------------------------------------------

sd_por_municipio <- datos_est %>%
  group_by(codigo_municipio) %>%
  summarise(
    n_anios = n(),
    sd_cobertura = sd(cobertura_neta_media),
    .groups = "drop"
  ) %>%
  filter(n_anios > 1)

summary(sd_por_municipio$sd_cobertura)

diag_within <- tibble(
  n_municipios = nrow(sd_por_municipio),
  sd_within_p25 = unname(quantile(sd_por_municipio$sd_cobertura, 0.25)),
  sd_within_mediana = median(sd_por_municipio$sd_cobertura),
  sd_within_p75 = unname(quantile(sd_por_municipio$sd_cobertura, 0.75)),
  sd_total = sd(datos_est$cobertura_neta_media)
)

write_csv(diag_within, "outputs/tablas/diagnostico_variacion_within.csv")

# ------------------------------------------------------------
# 4. Robustez
# ------------------------------------------------------------

# (a) Solo 2016-2024 (años con pocos faltantes)
datos_plm_2016 <- declarar_panel(datos_est %>% filter(a_o >= 2016))
pdim(datos_plm_2016)
tw_2016 <- plm(formula_base, data = datos_plm_2016,
               model = "within", effect = "twoways")
robusto(tw_2016)

# (b) Incluyendo las filas con cobertura igual a cero
datos_plm_ceros <- declarar_panel(
  datos_panel %>%
    filter(!is.na(deserci_n_media), !is.na(cobertura_neta_media))
)
tw_ceros <- plm(formula_base, data = datos_plm_ceros,
                model = "within", effect = "twoways")
robusto(tw_ceros)

# (c) Excluyendo 2020
datos_plm_sin2020 <- declarar_panel(datos_est %>% filter(a_o != 2020))
tw_sin2020 <- plm(formula_base, data = datos_plm_sin2020,
                  model = "within", effect = "twoways")
robusto(tw_sin2020)

# ------------------------------------------------------------
# 5. Tabla comparativa y gráfico principal
# ------------------------------------------------------------

extraer_coef <- function(modelo, nombre) {
  ct <- robusto(modelo)
  fila <- ct["cobertura_neta_media", ]
  tibble(
    modelo = nombre,
    estimate = unname(fila[1]),
    se = unname(fila[2]),
    p_valor = unname(fila[4])
  )
}

nombres <- c(
  "Pooled OLS",
  "Efectos aleatorios",
  "FE municipio",
  "FE municipio y año (base)",
  "Base: solo 2016-2024",
  "Base: con cobertura cero",
  "Base: sin 2020"
)

coefs <- bind_rows(
  extraer_coef(pooled, nombres[1]),
  extraer_coef(re, nombres[2]),
  extraer_coef(fe, nombres[3]),
  extraer_coef(twoways, nombres[4]),
  extraer_coef(tw_2016, nombres[5]),
  extraer_coef(tw_ceros, nombres[6]),
  extraer_coef(tw_sin2020, nombres[7])
) %>%
  mutate(
    lo = estimate - 1.96 * se,
    hi = estimate + 1.96 * se
  )

write_csv(coefs, "outputs/tablas/coeficientes_modelos.csv")

g_coef <- coefs %>%
  mutate(modelo = factor(modelo, levels = rev(nombres))) %>%
  ggplot(aes(x = estimate, y = modelo)) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_pointrange(aes(xmin = lo, xmax = hi)) +
  labs(
    title = "Asociación entre cobertura neta en media y deserción",
    subtitle = "Coeficiente de cobertura con IC 95 % (errores robustos agrupados por municipio)",
    x = "Cambio en la deserción (p.p.) por cada punto de cobertura",
    y = NULL
  ) +
  theme_minimal()

ggsave("outputs/figuras/05_coeficientes_modelos.png", g_coef,
       width = 10, height = 5.5, dpi = 200)

# ------------------------------------------------------------
# 6. Diagnóstico: residuos del modelo base por año
# ------------------------------------------------------------

res_tw <- data.frame(
  anio = index(twoways)[[2]],
  residuo = as.numeric(residuals(twoways))
)

g_res <- ggplot(res_tw, aes(x = anio, y = residuo)) +
  geom_boxplot() +
  geom_hline(yintercept = 0, colour = "red") +
  labs(
    title = "Residuos del modelo con efectos fijos de municipio y año",
    x = "Año",
    y = "Residuo"
  ) +
  theme_minimal()

ggsave("outputs/figuras/06_residuos_por_anio.png", g_res,
       width = 9, height = 5, dpi = 200)

# ------------------------------------------------------------
# 7. Reproducibilidad
# ------------------------------------------------------------

writeLines(capture.output(sessionInfo()), "outputs/session_info.txt")
