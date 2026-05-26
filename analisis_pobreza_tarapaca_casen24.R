#paquetes/librerias
library(readr)
library(dplyr)
library(tidyr)
library(scales)
library(sf)
library(srvyr)
library(ggplot2)
library(chilemapas)
library(stringr)
library(haven)
library(knitr)
library(kableExtra)
library(magick)
library(readxl)
# cargar datos ----
load("casen_2024.Rdata")
load("casen_region2024.Rdata")

#unir bases 
casen_2 <- left_join(casen_2024,
                     casen_2024_provincia_comuna,
                     by = join_by(folio, id_persona))

#diseño muestral -----
casen_svy <- casen_2 |> 
  as_survey(weights = expr, 
            strata = estrato, 
            ids = id_vivienda,
            nest = TRUE)

#pobreza regional con pesos e IC ─----------
casen_svy |> 
  filter(region == 1) |> 
  group_by(region, pobreza) |> 
  summarize(n = survey_total(),
            p = survey_mean(vartype = c("se", "ci"))) |> 
  mutate(porcentaje = percent(p, accuracy = 0.1),
         ic_low = percent(p_low, accuracy = 0.1),
         ic_upp = percent(p_upp, accuracy = 0.1))

#pobreza comunal dicotomizada con pesos e IC------
pobreza_dic_svy <- casen_svy |>  
  filter(region == 1) |> 
  mutate(pobreza_2 = ifelse(pobreza %in% c(1, 2), "pobre", "no pobre")) |> 
  group_by(region, comuna, pobreza_2) |> 
  summarize(n = survey_total(),
            p = survey_mean(vartype = c("se", "ci", "cv"))) |> 
  filter(pobreza_2 == "pobre") |> 
  mutate(comuna_nombre = as_factor(comuna),
         porcentaje = percent(p, accuracy = 0.1),
         ic_low = percent(p_low, accuracy = 0.1),
         ic_upp = percent(p_upp, accuracy = 0.1),
         codigo_comuna = str_pad(comuna, width = 5, pad = "0"))

#pobreza comunal dicotomizada con pesos e IC------
pobreza_dic_svy <- casen_svy |>  
  filter(region == 1) |> 
  mutate(pobreza_2 = ifelse(pobreza %in% c(1, 2), "pobre", "no pobre")) |> 
  group_by(region, comuna, pobreza_2) |> 
  summarize(n = survey_total(),
            p = survey_mean(vartype = c("se", "ci"))) |> 
  filter(pobreza_2 == "pobre") |> 
  mutate(comuna_nombre = as_factor(comuna),
         porcentaje = percent(p, accuracy = 0.1),
         ic_low = percent(p_low, accuracy = 0.1),
         ic_upp = percent(p_upp, accuracy = 0.1),
         codigo_comuna = str_pad(comuna, width = 5, pad = "0"))


#coeficiente de variacion

pobreza_dic_svy <- pobreza_dic_svy |>
  mutate(cv = p_se / p)

pobreza_dic_svy |>
  select(comuna_nombre, p, p_se, cv) |>
  print(n = 7)

# cargar mapa con chilemapas
mapa_comunal <- mapa_comunas |> 
  filter(codigo_region == "01")

test <- mapa_comunal |> 
  left_join(pobreza_dic_svy, by = "codigo_comuna") |> 
  st_as_sf()

#graficar mapa ----------
p_mapa <- test |> 
  ggplot() +
  geom_sf(aes(fill = p)) +
  scale_fill_continuous(
    labels = scales::percent,
    low = "#f7f7f7",
    high = "#5a3905"
  ) +
  labs(
    fill = "% pobreza",
    title = "Pobreza comunal en la Región de Tarapacá",
    caption = "Fuente: Elaboración propia, Encuesta CASEN 2024"
  ) +
  theme_void() +
  theme(
    plot.title = element_text(size = 11, hjust = 0.5),
    plot.caption = element_text(face = "italic", hjust = 0),
    legend.position = "right"
  )

print(p_mapa)

ggsave(
  filename = "output/graphs/mapa_pobreza_tarapaca.png",
  plot = p_mapa,
  width = 7,
  height = 8,
  dpi = 300,
  bg = "white"
)

# histograma -----
p_hist <- pobreza_dic_svy |> 
  ggplot(aes(x = reorder(comuna_nombre, p), y = p)) +
  geom_col(fill = "#5a3905") +
  geom_text(aes(label = percent(p, accuracy = 1)), hjust = -0.1, size = 3.5) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 0.50)) +
  coord_flip() +
  labs(
    title = "Pobreza comunal en la Región de Tarapacá",
    x = NULL,
    y = "% en situación de pobreza",
    caption = "Fuente: Elaboración propia, Encuesta CASEN 2024"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 11, hjust = 0),
    plot.caption = element_text(face = "italic", hjust = 0),
    panel.grid.major.y = element_blank()
  )

print(p_hist)

ggsave(
  filename = "output/graphs/histograma_pobreza_tarapaca.png",
  plot = p_hist,
  width = 8,
  height = 5,
  dpi = 300,
  bg = "white"
)

#tabla con IC-----
tabla_pobreza_svy <- pobreza_comunal_svy |> 
  ungroup() |>
  select(comuna_nombre, pobreza_label, porcentaje, ic_low, ic_upp, p_low) |> 
  mutate(
    estimacion   = paste0(porcentaje, " [", ic_low, " - ", ic_upp, "]"),
    no_confiable = p_low < 0
  ) |> 
  select(comuna_nombre, pobreza_label, estimacion, no_confiable) |> 
  pivot_wider(
    names_from  = pobreza_label,
    values_from = c(estimacion, no_confiable),
    values_fill = list(estimacion = "0.0%", no_confiable = FALSE)
  ) |> 
  ungroup() |>
  select(-any_of(c("region", "comuna"))) |>
  rename(Comuna = comuna_nombre)

# flags para colorear
flags_extrema    <- tabla_pobreza_svy$`no_confiable_Pobreza extrema`
flags_no_extrema <- tabla_pobreza_svy$`no_confiable_Pobreza no extrema`
flags_fuera      <- tabla_pobreza_svy$`no_confiable_Fuera de la pobreza`

# tabla solo con columnas de texto
tabla_final <- tabla_pobreza_svy |> 
  select(
    Comuna,
    `estimacion_Pobreza extrema`,
    `estimacion_Pobreza no extrema`,
    `estimacion_Fuera de la pobreza`
  ) |> 
  rename(
    `Pobreza extrema`     = `estimacion_Pobreza extrema`,
    `Pobreza no extrema`  = `estimacion_Pobreza no extrema`,
    `Fuera de la pobreza` = `estimacion_Fuera de la pobreza`
  )

# exportar tabla
tabla_final |> 
  kable(format = "html", align = "c") |> 
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    full_width = TRUE,         
    font_size  = 16,           
    html_font  = "Times New Roman"
  ) |> 
  add_header_above(c(" " = 1, "Nivel de pobreza (% [IC 95%])" = 3)) |> 
  column_spec(1, bold = TRUE, width = "15%") |>   
  column_spec(2, color = ifelse(flags_extrema,    "red", "black"), width = "28%") |> 
  column_spec(3, color = ifelse(flags_no_extrema, "red", "black"), width = "28%") |> 
  column_spec(4, color = ifelse(flags_fuera,      "red", "black"), width = "28%") |> 
  footnote(
    general = "Fuente: Elaboración propia, Encuesta CASEN 2024.",
    symbol  = "Las estimaciones en rojo presentan intervalos de confianza que cruzan el cero, por lo que deben interpretarse con cautela debido al reducido tamaño muestral en esas comunas."
  ) |> 
  save_kable(
    "output/graphs/tabla_pobreza_tarapaca.png",
    density = 300,
    zoom = 2                    
  )

#add sae 2024 (se skipean 2 porque esta mal formateado el excel)
sae <- read_excel("SAE_ingresos_2024.xlsx", skip = 2) |>
  janitor::clean_names()

names(sae)
# unir con estimacion creada con leftjoin
sae <- sae |>
  mutate(codigo = str_pad(codigo, width = 5, pad = "0"))

comparacion <- pobreza_dic_svy |>
  left_join(sae, by = c("codigo_comuna" = "codigo"))
#comparacion  sae y casen
comparacion |>
  select(comuna_nombre, p, porcentaje_de_personas_en_situacion_de_pobreza_de_ingresos_2024, tipo_de_estimacion_sae, cv) |>
  print(n = 7)

#tabla comparativa

comparacion |>
  ungroup() |>
  select(comuna_nombre, p, 
         porcentaje_de_personas_en_situacion_de_pobreza_de_ingresos_2024,
         tipo_de_estimacion_sae, cv) |>
  mutate(
    p_label    = percent(p, accuracy = 0.1),
    sae_label  = percent(porcentaje_de_personas_en_situacion_de_pobreza_de_ingresos_2024, accuracy = 0.1),
    diferencia = percent(porcentaje_de_personas_en_situacion_de_pobreza_de_ingresos_2024 - p, accuracy = 0.1),
    cv_label   = percent(cv, accuracy = 0.1),
    calidad_cv = case_when(
      cv < 0.15 ~ "Bajo",
      cv < 0.30 ~ "Medio",
      TRUE      ~ "Alto")
  ) |>
  select(comuna_nombre, p_label, sae_label, diferencia, cv_label, calidad_cv) |>
  rename(
    Comuna                 = comuna_nombre,
    `Estimación CASEN 2024`= p_label,
    `SAE 2024`             = sae_label,
    `Diferencia`           = diferencia,
    `CV`                   = cv_label,
    `Calidad CV`           = calidad_cv
  ) |>
  kable(format = "html", align = "c") |>
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    full_width = TRUE,
    font_size  = 16,
    html_font  = "Times New Roman"
  ) |>
  add_header_above(c(" " = 1, "Comparación metodológica | Tarapacá" = 5)) |>
  footnote(
    general = "Fuente: Elaboración propia en base a CASEN 2024 y SAE 2024, MIDESO.",
    symbol  = "CV < 15%: Bajo. CV 15%-30%: Medio. CV > 30%: Alto."
  ) |>
  save_kable(
    "output/graphs/comparacion_sae_directa.png",
    density = 300,
    zoom = 2
  )