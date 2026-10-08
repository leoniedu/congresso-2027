# Histogram and relative distribution of dim 1: Câmara 57th vs projected 58th. Run after post.R.
library(data.table); library(ggplot2)
set.seed(2027)
cam23 <- unique(fread("data/camara_2023_26.csv")); cam27 <- fread("data/camara_2027.csv")
res <- fread("data/residuos.csv"); pools <- split(res$residuo, paste(res$casa, res$bloco))
cam27[, prev := startsWith(origem, "previsto")][, key := paste("Câmara", bloco)][, mapped := origem == "medido 2015–18 (mapeado)"]
draw <- function(d) { x <- d$dim1
  for (k in unique(d$key[d$prev])) { i <- which(d$prev & d$key == k); x[i] <- x[i] + sample(pools[[k]], length(i), replace = TRUE) }
  if (any(d$mapped)) x[d$mapped] <- x[d$mapped] + rnorm(sum(d$mapped), 0, d$erro[d$mapped]); x }
# histogram
br <- seq(-1, 1, 0.1)
d <- rbind(cam23[, .(casa = "57ª (2023-26): eleitos em 2022, posição medida", dim1, tipo = "medido")],
           cam27[, .(casa = "58ª (2027): medidos + previstos", dim1, tipo = fifelse(prev, "previsto", "medido"))])
d[, casa := factor(casa, unique(casa))][, tipo := factor(tipo, c("previsto", "medido"))]
sim <- replicate(500, hist(pmin(pmax(draw(cam27), -0.999), 0.999), breaks = br, plot = FALSE)$counts)
esp <- data.table(casa = factor(levels(d$casa)[2], levels(d$casa)), x = head(br, -1), n = rowMeans(sim))
med <- d[, .(m = median(dim1)), by = casa]
p1 <- ggplot(d, aes(x = dim1)) + geom_histogram(aes(fill = tipo), breaks = br, colour = "white", linewidth = 0.3) +
  geom_step(data = esp, aes(x = x, y = n), colour = "#0b0b0b", linewidth = 0.5) +
  geom_vline(data = med, aes(xintercept = m), linetype = "22", linewidth = 0.4) + facet_wrap(~ casa, ncol = 1) +
  scale_fill_manual(values = c(medido = "#1c5cab", previsto = "#c2410c"), name = NULL, breaks = c("medido", "previsto")) +
  labs(x = "escala comum 2019-2026 (dimensão 1)", y = "deputados", title = "Distribuição da Câmara: 57ª contra 58ª",
       subtitle = "Faixas de 0,1. Tracejado: mediana. Na 58ª, a linha preta é o histograma esperado quando os previstos\nrecebem os resíduos empíricos do modelo (média de 500 sorteios).") +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom", panel.grid.minor = element_blank(), plot.title.position = "plot", strip.text = element_text(hjust = 0, face = "bold"))
ggsave("figures/hist_57_58.png", p1, width = 8, height = 6, dpi = 200, bg = "white")
# relative distribution
F57 <- ecdf(cam23$dim1)
rel <- function(x) { r <- F57(x); r[r >= 1] <- 0.9999; tabulate(findInterval(r, seq(0, 1, 0.1)), 10) / length(r) / 0.1 }
sim <- replicate(2000, rel(draw(cam27))); q57 <- quantile(cam23$dim1, seq(0, 1, 0.1))
rd <- data.table(decil = 1:10, g = rowMeans(sim), lo = apply(sim, 1, quantile, .025), hi = apply(sim, 1, quantile, .975), faixa = sprintf("%.2f a %.2f", head(q57, -1), tail(q57, -1)))
fwrite(rd, "results/distribuicao_relativa.csv")
p2 <- ggplot(rd, aes(x = decil, y = g)) + geom_hline(yintercept = 1, colour = "#8a8a86", linetype = "22") +
  geom_col(fill = "#1c5cab", width = 0.8) + geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.2, linewidth = 0.4) +
  scale_x_continuous(breaks = 1:10, labels = sprintf("%dº\n%s", rd$decil, rd$faixa)) + scale_y_continuous(limits = c(0, max(rd$hi) * 1.05), expand = c(0, 0)) +
  labs(x = "decil da 57ª (faixa da dimensão 1)", y = "densidade relativa da 58ª", title = "Distribuição relativa: onde a 58ª cai nos decis da 57ª",
       subtitle = "1 = mesma proporção que a 57ª naquele decil. Barras: média de 2.000 sorteios com resíduos empíricos por bloco; traços: IC 95 %.") +
  theme_minimal(base_size = 10) + theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(), plot.title.position = "plot", axis.text.x = element_text(size = 7))
ggsave("figures/distribuicao_relativa_57_58.png", p2, width = 9, height = 5, dpi = 200, bg = "white")

# relative density as in Handcock & Morris: kernel density of the relative ranks r = F57(x58) on [0, 1],
# reflected at the boundaries; averaged over draws of the predicted positions; pointwise 95% band.
grid <- seq(0.005, 0.995, by = 0.01)
kd <- function(x) { r <- F57(x); r <- pmin(pmax(r, 1e-4), 1 - 1e-4); rr <- c(-r, r, 2 - r)
  d <- density(rr, bw = 0.05, from = 0, to = 1, n = length(grid)); 3 * d$y }          # reflection: density of r on [0,1] is 3x the mirrored density
sim <- replicate(2000, kd(draw(cam27)))
rk <- data.table(r = grid, g = rowMeans(sim), lo = apply(sim, 1, quantile, .025), hi = apply(sim, 1, quantile, .975))
rk[, x57 := quantile(cam23$dim1, r)]
fwrite(rk, "results/densidade_relativa.csv")
marcas <- data.table(r = c(0.05, 0.25, 0.5, 0.75, 0.95)); marcas[, x := quantile(cam23$dim1, r)]
# party medians in the 57th, placed on the relative-rank axis
cam23[, partido := gsub(" ", "", toupper(partido))]
part <- cam23[, .(n = .N, x = median(dim1)), by = partido][n >= 8][, r := F57(x)][order(r)]
part[, y := 0.07 * max(rk$hi) * 1.05]
p3 <- ggplot(rk, aes(x = r)) + geom_hline(yintercept = 1, colour = "#8a8a86", linetype = "22") +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#1c5cab", alpha = 0.18) + geom_line(aes(y = g), colour = "#1c5cab", linewidth = 0.9) +
  geom_segment(data = part, aes(x = r, xend = r, y = 0, yend = y), colour = "#8a8a86", linewidth = 0.4) +
  ggrepel::geom_text_repel(data = part, aes(x = r, y = y, label = partido), size = 2.6, colour = "#52514e", direction = "x", nudge_y = 0.12,
                           segment.colour = "#d9d9d6", segment.size = 0.3, min.segment.length = 0, seed = 1) +
  scale_x_continuous(breaks = marcas$r, labels = sprintf("%.2f\n(x = %.2f)", marcas$r, marcas$x)) +
  scale_y_continuous(limits = c(0, max(rk$hi) * 1.05), expand = c(0, 0)) +
  labs(x = "posição relativa r na distribuição da 57ª (quantil; entre parênteses, a posição na escala)", y = "densidade relativa g(r)",
       title = "Densidade relativa da 58ª em relação à 57ª (Câmara)",
       subtitle = "g(r) > 1: a 58ª tem mais deputados que a 57ª naquele trecho. Kernel (largura 0,05) sobre os ranks relativos, com reflexão nas bordas;\nmédia de 2.000 sorteios com resíduos empíricos por bloco; faixa: IC 95 % pontual. Marcas: mediana de cada partido na 57ª (n ≥ 8).") +
  theme_minimal(base_size = 10) + theme(panel.grid.minor = element_blank(), plot.title.position = "plot")
ggsave("figures/densidade_relativa_57_58.png", p3, width = 9, height = 5, dpi = 200, bg = "white")

# comparison: model (bloc residual draws) vs party-only predictions for the newcomers:
#  (a) party median, point; (b) draws from the 57th's members of the same party (empirical party distribution)
pos_sets <- list()
pos_sets[["modelo + resíduos empíricos por bloco"]] <- function() draw(cam27)
cam27[, partido := gsub(" ", "", toupper(partido))]
pm <- cam23[, .(x = median(dim1)), by = partido]
party_members <- split(cam23$dim1, cam23$partido)
x_pm <- cam27$dim1; x_pm[cam27$prev] <- pm$x[match(cam27$partido[cam27$prev], pm$partido)]; x_pm[is.na(x_pm)] <- cam27$dim1[is.na(x_pm)]
pos_sets[["mediana do partido (ponto)"]] <- function() x_pm
pos_sets[["sorteio entre os deputados do partido na 57ª"]] <- function() { x <- cam27$dim1
  for (p in unique(cam27$partido[cam27$prev])) { i <- which(cam27$prev & cam27$partido == p); if (!is.null(party_members[[p]])) x[i] <- sample(party_members[[p]], length(i), replace = TRUE) }
  x }
cmp <- rbindlist(lapply(names(pos_sets), function(nm) { s <- replicate(if (nm == "mediana do partido (ponto)") 1 else 1000, kd(pos_sets[[nm]]()))
  if (is.null(dim(s))) s <- matrix(s, ncol = 1); data.table(previsao = nm, r = grid, g = rowMeans(s), lo = apply(s, 1, quantile, .025), hi = apply(s, 1, quantile, .975)) }))
cmp[, previsao := factor(previsao, names(pos_sets))]
p4 <- ggplot(cmp, aes(x = r, y = g, colour = previsao, fill = previsao)) + geom_hline(yintercept = 1, colour = "#8a8a86", linetype = "22") +
  geom_ribbon(data = cmp[previsao != "mediana do partido (ponto)"], aes(ymin = lo, ymax = hi), alpha = 0.12, colour = NA) + geom_line(linewidth = 0.9) +
  geom_segment(data = part, aes(x = r, xend = r, y = 0, yend = 0.07 * max(cmp$hi) * 1.05), inherit.aes = FALSE, colour = "#8a8a86", linewidth = 0.4) +
  ggrepel::geom_text_repel(data = part, aes(x = r, y = 0.07 * max(cmp$hi) * 1.05, label = partido), inherit.aes = FALSE, size = 2.6, colour = "#52514e", direction = "x", nudge_y = 0.12, segment.colour = "#d9d9d6", segment.size = 0.3, min.segment.length = 0, seed = 1) +
  scale_colour_manual(values = c("#1c5cab", "#c2410c", "#eda100"), name = "os 180 previstos entram como:") + scale_fill_manual(values = c("#1c5cab", "#c2410c", "#eda100"), guide = "none") +
  scale_x_continuous(breaks = marcas$r, labels = sprintf("%.2f\n(x = %.2f)", marcas$r, marcas$x)) + scale_y_continuous(limits = c(0, max(cmp$hi) * 1.05), expand = c(0, 0)) +
  labs(x = "posição relativa r na distribuição da 57ª", y = "densidade relativa g(r)", title = "Densidade relativa da 58ª: modelo contra rótulo partidário",
       subtitle = "Os 333 medidos são os mesmos nas três curvas; só os 180 previstos mudam. Faixas: IC 95 % pontual (1.000 sorteios).\nMarcas: mediana de cada partido na 57ª.") +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom", panel.grid.minor = element_blank(), plot.title.position = "plot") + guides(colour = guide_legend(nrow = 1))
ggsave("figures/densidade_relativa_comparacao.png", p4, width = 9, height = 5.4, dpi = 200, bg = "white")
fwrite(cmp, "results/densidade_relativa_comparacao.csv")
