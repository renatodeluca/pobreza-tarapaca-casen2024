# Pobreza comunal en la Región de Tarapacá

Análisis de pobreza por ingresos a nivel comunal utilizando microdatos CASEN 2024, diseño muestral complejo, control de calidad estadístico y comparación con estimaciones SAE 2024 del MIDESO.

## Objetivo

Estimar la proporción de población en situación de pobreza por ingresos en las comunas de la Región de Tarapacá, incorporando factores de expansión, estratificación e intervalos de confianza. Adicionalmente, comparar las estimaciones directas con la metodología oficial de Estimación para Áreas Pequeñas (SAE) del MIDESO.

## Datos

Los datos utilizados provienen de:

- **Encuesta CASEN 2024**: https://observatorio.ministeriodesarrollosocial.gob.cl/encuesta-casen
- **SAE 2024**: https://observatorio.ministeriodesarrollosocial.gob.cl/pobreza-comunal
- Base territorial de comunas y provincias del Ministerio de Desarrollo Social y Familia

## Metodología

- Diseño muestral complejo mediante `srvyr`
- Uso de factores de expansión poblacional
- Cálculo de intervalos de confianza al 95%
- Coeficiente de variación (CV) como control de calidad de las estimaciones directas
- Comparación con estimaciones SAE 2024 mediante test Z
- Integración con cartografía comunal mediante `chilemapas` y `sf`
- Visualización de resultados con `ggplot2` y `kableExtra`

## Herramientas

- R 4.6.0
- srvyr
- dplyr
- tidyr
- forcats
- sf
- chilemapas
- ggplot2
- kableExtra
- readxl
- janitor

## Estructura del proyecto

```
pobreza-tarapaca-casen2024/
│
├── analisis_pobreza_tarapaca_casen24.R
├── README.md
└── output/
    └── graphs/
        ├── histograma_pobreza_tarapaca.png
        ├── mapa_pobreza_tarapaca.png
        ├── tabla_pobreza_tarapaca.png
        └── comparacion_sae_directa.png
```

## Resultados principales

### Estimación directa CASEN 2024

| Comuna | % Pobreza | CV | Calidad |
|---|---|---|---|
| Pica | 36.1% | 21.4% | Medio |
| Colchane | 28.4% | 53.6% | Alto |
| Alto Hospicio | 27.9% | 7.0% | Bajo |
| Camiña | 25.7% | 36.2% | Alto |
| Pozo Almonte | 18.9% | 26.4% | Medio |
| Iquique | 15.5% | 6.6% | Bajo |
| Huara | 14.1% | 42.5% | Alto |

### Comparación estimación directa vs SAE 2024

| Comuna | CASEN 2024 | SAE 2024 | CV | p-valor |
|---|---|---|---|---|
| Colchane | 28.4% | 51.0% | Alto | 0.165 |
| Camiña | 25.7% | 43.7% | Alto | 0.085 |
| Huara | 14.1% | 39.9% | Alto | < 0.001 |
| Pica | 36.1% | 31.4% | Medio | 0.570 |
| Alto Hospicio | 27.9% | 26.8% | Bajo | 0.641 |
| Pozo Almonte | 18.9% | 21.1% | Medio | 0.698 |
| Iquique | 15.5% | 16.2% | Bajo | 0.574 |

Para comunas con CV alto, se recomienda utilizar las estimaciones SAE como referencia principal, ya que incorporan fuentes adicionales que compensan el reducido tamaño muestral.

## Nota

Los archivos de datos originales no se incluyen en este repositorio y deben descargarse por separado desde los enlaces indicados en la sección Datos.

## Créditos

Este análisis se apoyó en tutoriales y recursos de [Bastián Olea](https://github.com/bastianolea), quien comparte material de visualización y procesamiento de datos en R.