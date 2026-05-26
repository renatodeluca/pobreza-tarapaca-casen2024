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
library(janitor)
library(forcats)
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

#pobreza comunal con pesos e IC------
pobreza_comunal_svy <- casen_svy |> 
  filter(region == 1) |> 
  group_by(region, comuna, pobreza) |> 
  summarize(n = survey_total(),
            p = survey_mean(vartype = c("se", "ci"))) |> 
  mutate(pobreza_label = as_factor(pobreza),
         comuna_nombre = as_factor(comuna),
         porcentaje = percent(p, accuracy = 0.1),
         ic_low = percent(p_low, accuracy = 0.1),
         ic_upp = percent(p_upp, accuracy = 0.1))

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
         codigo_comuna = str_pad(comuna, width = 5, pad = "0"),
         cv = (p_se / p) * 100)

# mapa comunal Tarapacá -------
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

flags_extrema    <- tabla_pobreza_svy$`no_confiable_Pobreza extrema`
flags_no_extrema <- tabla_pobreza_svy$`no_confiable_Pobreza no extrema`
flags_fuera      <- tabla_pobreza_svy$`no_confiable_Fuera de la pobreza`

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

# cargar SAE 2024 ----
sae <- read_excel("SAE_ingresos_2024.xlsx", skip = 2) |>
  janitor::clean_names() |>
  mutate(codigo = str_pad(codigo, width = 5, pad = "0"))

# unir con estimacion directa
comparacion <- pobreza_dic_svy |>
  left_join(sae, by = c("codigo_comuna" = "codigo"))

#tabla comparativa casen y sae
comparacion |>
  ungroup() |>
  arrange(desc(porcentaje_de_personas_en_situacion_de_pobreza_de_ingresos_2024)) |>
  mutate(
    se_sae     = (limite_superior - limite_inferior) / (2 * 1.96),
    z          = (p - porcentaje_de_personas_en_situacion_de_pobreza_de_ingresos_2024) /
                  sqrt(p_se^2 + se_sae^2),
    p_valor    = 2 * (1 - pnorm(abs(z))),
    p_label    = percent(p, accuracy = 0.1),
    sae_label  = percent(porcentaje_de_personas_en_situacion_de_pobreza_de_ingresos_2024, accuracy = 0.1),
    diferencia = percent(porcentaje_de_personas_en_situacion_de_pobreza_de_ingresos_2024 - p, accuracy = 0.1),
    cv_label   = percent(cv, accuracy = 0.1),
    calidad_cv = case_when(
      cv < 0.15 ~ "Bajo",
      cv < 0.30 ~ "Medio",
      TRUE      ~ "Alto"),
    z_label    = round(z, 2),
    p_label2   = ifelse(p_valor < 0.001, "< 0.001", as.character(round(p_valor, 3)))
  ) |>
  select(comuna_nombre, p_label, sae_label, diferencia, cv_label, calidad_cv, z_label, p_label2) |>
  rename(
    Comuna                  = comuna_nombre,
    `Estimación CASEN 2024` = p_label,
    `SAE 2024`              = sae_label,
    `Diferencia`            = diferencia,
    `CV`                    = cv_label,
    `Calidad CV`            = calidad_cv,
    `Z`                     = z_label,
    `p-valor`               = p_label2
  ) |>
  kable(format = "html", align = "c") |>
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    full_width = TRUE,
    font_size  = 16,
    html_font  = "Times New Roman"
  ) |>
  add_header_above(c(" " = 1, "Comparación CASEN 2024 y SAE 2024 para la Región de Tarapacá" = 7)) |>
  footnote(
    general = "Fuente: Elaboración propia en base a CASEN 2024 y SAE 2024, MIDESO.",
    symbol  = "El CV corresponde a la estimación directa CASEN 2024. CV < 15%: Bajo (confiable). CV 15%-30%: Medio (cautela). CV > 30%: Alto (poco confiable). p-valor < 0.05 indica diferencia estadísticamente significativa entre ambas estimaciones."
  ) |>
  save_kable(
    "output/graphs/comparacion_sae_directa.png",
    density = 300,
    zoom = 2
  )

#grafico de barras comparativo CASEN vs SAE

comparacion |>
  ungroup() |>
  arrange(desc(porcentaje_de_personas_en_situacion_de_pobreza_de_ingresos_2024)) |>
  mutate(comuna_nombre = fct_reorder(comuna_nombre, 
                                     porcentaje_de_personas_en_situacion_de_pobreza_de_ingresos_2024)) |>
  select(comuna_nombre, p, porcentaje_de_personas_en_situacion_de_pobreza_de_ingresos_2024) |>
  pivot_longer(cols = c(p, porcentaje_de_personas_en_situacion_de_pobreza_de_ingresos_2024),
               names_to = "metodo",
               values_to = "valor") |>
  mutate(metodo = recode(metodo,
                         "p" = "Estimación directa CASEN 2024",
                         "porcentaje_de_personas_en_situacion_de_pobreza_de_ingresos_2024" = "SAE 2024")) |>
  ggplot(aes(x = comuna_nombre, y = valor, fill = metodo)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = percent(valor, accuracy = 0.1)),
            position = position_dodge(width = 0.9),
            hjust = -0.1, size = 3.2) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 0.65)) +
  scale_fill_manual(values = c("Estimación directa CASEN 2024" = "#a67c52",
                                "SAE 2024" = "#5a3905")) +
  coord_flip() +
  labs(
    title = "Pobreza comunal en la Región de Tarapacá: CASEN 2024 vs SAE 2024",
    x = NULL,
    y = "% en situación de pobreza por ingresos",
    fill = NULL,
    caption = "Fuente: Elaboración propia en base a CASEN 2024 y SAE 2024, MIDESO."
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 11, hjust = 0),
    plot.caption = element_text(face = "italic", hjust = 0),
    panel.grid.major.y = element_blank(),
    legend.position = "bottom")
ggsave(
  filename = "output/graphs/comparacion_sae_casen.png",
  width = 9,
  height = 6,
  dpi = 300,
  bg = "white")
