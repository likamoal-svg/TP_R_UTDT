# Cobertura neta en educación media y deserción escolar en los municipios de Colombia, 2011-2024

Trabajo Práctico Integrador, Módulo R. Maestría en Econometría, Universidad Torcuato Di Tella (2026).
Autora: Lina Katherine Mora Alzate.

## Pregunta de investigación

¿Cuál es la relación entre la cobertura neta en educación media y la tasa de deserción escolar en los municipios de Colombia entre 2011 y 2024?

La pregunta está formulada en términos de asociación y no de efecto causal.

## Datos

- **Fuente:** Ministerio de Educación Nacional (MEN), *Estadísticas en Educación en Preescolar, Básica y Media*, publicado en Datos Abiertos Colombia (identificador `nudc-7mev`).
- **Descarga:** `https://www.datos.gov.co/resource/nudc-7mev.csv?$limit=50000`
- **Cobertura:** municipios de Colombia, años 2011 a 2024. La versión descargada tiene 15.707 filas y 41 columnas.
- **Unidad de análisis:** municipio-año. Tras excluir el agregado nacional, el panel tiene 15.704 observaciones y 1.123 municipios (panel no balanceado).
- **Copia local:** el archivo descargado se incluye en `data/men_estadisticas_educacion.csv`, de modo que el análisis se reproduce aunque la fuente cambie.

## Técnica

Datos de panel con el paquete `plm`: mínimos cuadrados agrupados (*pooled*), efectos fijos, efectos aleatorios, test de Hausman y efectos fijos de municipio y de año como especificación base. La inferencia usa errores estándar robustos HC1 agrupados por municipio. Se incluyen tres pruebas de robustez (solo 2016-2024, incluyendo cobertura igual a cero y excluyendo 2020) y un diagnóstico de variación *within*.

## Resultado principal

El coeficiente de cobertura es negativo y significativo cuando se usa la variación entre municipios (pooled: -0,034) y se reduce cerca de un 89 % en la especificación base (efectos fijos de municipio y año: -0,0036, IC 95 % de -0,0101 a 0,0029), donde deja de distinguirse de cero. El resultado se mantiene en las tres pruebas de robustez. Los resultados son asociaciones y no efectos causales. El detalle está en el informe.

## Estructura del repositorio

```
.
├── README.md
├── data/
│   └── men_estadisticas_educacion.csv   # datos descargados de Datos Abiertos
├── scripts/
│   ├── 01_carga_limpieza.R              # carga, limpieza y muestra de estimación
│   ├── 02_eda.R                         # análisis exploratorio (figuras y tablas)
│   └── 03_modelos.R                     # modelos de panel, robustez y diagnósticos
├── outputs/
│   ├── figuras/                         # gráficos usados en el informe
│   ├── tablas/                          # tablas usadas en el informe
│   └── session_info.txt                 # versiones de R y paquetes
└── informe/
    ├── informe.Rmd                      # fuente del informe
    └── informe.pdf                      # informe entregado
```

## Cómo reproducir el análisis

**Requisitos:** R y RStudio. Paquetes necesarios:

```r
install.packages(c(
  "dplyr", "readr", "stringr", "ggplot2",
  "plm", "lmtest", "sandwich",
  "rmarkdown", "knitr"
))
```

**Pasos:**

1. Clonar o descargar el repositorio.
2. Abrir la carpeta como proyecto de RStudio (File > New Project > Existing Directory), o fijar el directorio de trabajo en la raíz del repositorio. Todas las rutas son relativas a esa raíz.
3. Ejecutar los scripts en orden, cada uno en una sesión limpia:

```r
source("scripts/01_carga_limpieza.R")
source("scripts/02_eda.R")
source("scripts/03_modelos.R")
```

Las semillas están fijadas (`set.seed(2026)`). El script 01 usa `data/men_estadisticas_educacion.csv` si existe, y lo descarga de la fuente si no. Además de las tablas y figuras, el script 01 genera archivos `.rds` intermedios en `data/`, que no se incluyen en el repositorio.

4. Para regenerar el informe, abrir `informe/informe.Rmd` en RStudio y pulsar **Knit**. El informe lee las figuras y tablas de `outputs/`, por lo que los scripts deben haberse ejecutado antes. Genera un archivo HTML, que se guarda como PDF desde el navegador (Imprimir > Guardar como PDF).
