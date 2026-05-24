# Pobreza comunal en la Región de Tarapacá

Análisis de pobreza por ingresos a nivel comunal utilizando microdatos CASEN 2024, diseño muestral complejo y visualización geoespacial en R.

## Objetivo

Estimar la proporción de población en situación de pobreza por ingresos en las comunas de la Región de Tarapacá, incorporando factores de expansión, estratificación e intervalos de confianza.

## Datos

Los datos utilizados provienen de la Encuesta CASEN 2024 y de la base territorial de comunas y provincias publicada por el Ministerio de Desarrollo Social y Familia.

Datos disponibles en:

https://observatorio.ministeriodesarrollosocial.gob.cl/encuesta-casen

## Metodología

- Diseño muestral complejo mediante `srvyr`
- Uso de factores de expansión
- Cálculo de intervalos de confianza al 95%
- Integración con cartografía comunal mediante `sf`
- Visualización de resultados con `ggplot2`

## Herramientas

- R 4.6.0
- srvyr
- dplyr
- sf
- chilemapas
- ggplot2
- kableExtra

## Estructura del proyecto

pobreza-tarapaca-casen2024/
├── analisis_pobreza_tarapaca_casen24.R
├── .gitignore
└── README.md

 
## Resultados principales
| Comuna | % Pobreza por ingresos |
|--------|------------------------|
| Pica | 36.1% |
| Colchane | 28.4% |
| Alto Hospicio | 27.9% |
| Camiña | 25.7% |
| Pozo Almonte | 18.9% |
| Huara | 14.1% |
| Iquique | 15.5% |

*Estimaciones con intervalos de confianza al 95%. Las comunas pequeñas como Camiña y Colchane presentan alta incertidumbre muestral.*

El proyecto genera:

- Mapa comunal de pobreza en Tarapacá
- Gráfico comparativo entre comunas
- Tabla con estimaciones e intervalos de confianza

## Nota

Los archivos de datos originales no se incluyen en este repositorio y deben descargarse por separado.
