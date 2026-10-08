# Senate relative to Câmara on the joint scale (stacked Câmara + Senado fit), 2023-26 and 2027,
# plus each house's 2027 relative to its own 2023-26. Kernel relative density on relative ranks
# (reflection at the boundaries), reldist polarization indices, simulation over the predicted members.
library(data.table); library(ggplot2); library(reldist)
set.seed(2027)
cam23 <- unique(fread("data/camara_2023_26_escala_conjunta.csv")); sen23 <- unique(fread("data/senado_2023_26.csv"))
cam27 <- fread("data/camara_2027.csv"); sen27 <- fread("data/senado_2027.csv")
res <- fread("data/residuos.csv"); pools <- split(res$residuo, paste(res$casa, res$bloco))
prep <- function(d, casa, col = "dim1", err = "erro") { d <- copy(d); d[, x := get(col)]; d[, e := get(err)]
  d[, prev := startsWith(origem, "previsto")]; d[, key := paste(fifelse(casa == "Câmara" | grepl("coattail\\)$", origem), casa, "Senado (sem coattail)"), bloco)]
  d[, mapped := origem == "medido 2015–18 (mapeado)"]; d }
draw <- function(d) { x <- d$x
  for (k in unique(d$key[d$prev])) { i <- which(d$prev & d$key == k); x[i] <- x[i] + sample(pools[[k]], length(i), replace = TRUE) }
  if (any(d$mapped)) x[d$mapped] <- x[d$mapped] + rnorm(sum(d$mapped), 0, d$e[d$mapped]); x }
c27 <- prep(cam27, "Câmara", "dim1_conjunta", "erro_conjunta"); s27 <- prep(sen27, "Senado")
grid <- seq(0.005, 0.995, by = 0.01); bw <- 0.07
kd <- function(y, yo) { r <- ecdf(yo)(y); r <- pmin(pmax(r, 1e-4), 1 - 1e-4); d <- density(c(-r, r, 2 - r), bw = bw, from = 0, to = 1, n = length(grid)); 3 * d$y }
w <- function(v) rep(1, length(v))
idx <- function(y, yo) c(mrp = rpy(y = y, yo = yo, ywgt = w(y), yowgt = w(yo), pvalue = FALSE)[2],
                         lrp = rpluy(y = y, yo = yo, ywgt = w(y), yowgt = w(yo), pvalue = FALSE, lower = TRUE, upper = FALSE)[2],
                         urp = rpluy(y = y, yo = yo, ywgt = w(y), yowgt = w(yo), pvalue = FALSE, lower = FALSE, upper = TRUE)[2],
                         mediana_y = median(y), mediana_yo = median(yo))
comp <- list(
  "Senado 2023–26 vs Câmara 2023–26" = list(y = function() sen23$dim1, yo = function() cam23$dim1, nsim = 1),
  "Senado 2027 vs Câmara 2027"       = list(y = function() draw(s27),  yo = function() draw(c27),  nsim = 1000),
  "Câmara 2027 vs Câmara 2023–26"    = list(y = function() draw(c27),  yo = function() cam23$dim1, nsim = 1000),
  "Senado 2027 vs Senado 2023–26"    = list(y = function() draw(s27),  yo = function() sen23$dim1, nsim = 1000))
curvas <- list(); indices <- list()
for (nm in names(comp)) { cc <- comp[[nm]]
  S <- replicate(cc$nsim, { y <- cc$y(); yo <- cc$yo(); c(kd(y, yo), idx(y, yo)) }); if (is.null(dim(S))) S <- matrix(S, ncol = 1)
  g <- S[seq_along(grid), , drop = FALSE]; ii <- S[-seq_along(grid), , drop = FALSE]
  curvas[[nm]] <- data.table(comparacao = nm, r = grid, g = rowMeans(g), lo = apply(g, 1, quantile, .025), hi = apply(g, 1, quantile, .975))
  indices[[nm]] <- data.table(comparacao = nm, indice = rownames(ii), media = rowMeans(ii), lo = apply(ii, 1, quantile, .025), hi = apply(ii, 1, quantile, .975)) }
curvas <- rbindlist(curvas); indices <- rbindlist(indices)
fwrite(curvas, "results/reldist_casas_curvas.csv"); fwrite(indices, "results/reldist_casas_indices.csv")
print(dcast(indices, comparacao ~ indice, value.var = "media")[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 3) else x)])
print(indices[indice %in% c("mrp", "lrp", "urp"), .(comparacao, indice, media = round(media, 3), lo = round(lo, 3), hi = round(hi, 3))])
# figure: Senate relative to Câmara, 2023-26 and 2027; party markers = party medians of the reference Câmara of each panel
cam23[, partido := gsub(" ", "", toupper(partido))]
pm <- function(ref, lab) { r <- ref[, .(n = .N, xm = median(x)), by = partido][n >= 8]; r[, rr := ecdf(ref$x)(xm)]; r[, comparacao := lab]; r }
part <- rbind(pm(cam23[, .(partido, x = dim1)], names(comp)[1]), pm(cam27[, .(partido, x = dim1_conjunta)], names(comp)[2]))
d <- curvas[comparacao %in% names(comp)[1:2]]; d[, comparacao := factor(comparacao, names(comp)[1:2])]; part[, comparacao := factor(comparacao, names(comp)[1:2])]
p <- ggplot(d, aes(x = r, y = g)) + geom_hline(yintercept = 1, colour = "#8a8a86", linetype = "22") +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#1c5cab", alpha = 0.15) + geom_line(colour = "#1c5cab", linewidth = 0.9) +
  geom_segment(data = part, aes(x = rr, xend = rr, y = 0, yend = 0.12), inherit.aes = FALSE, colour = "#8a8a86", linewidth = 0.4) +
  ggrepel::geom_text_repel(data = part, aes(x = rr, y = 0.12, label = partido), inherit.aes = FALSE, size = 2.4, colour = "#52514e", direction = "x", nudge_y = 0.2, segment.colour = "#d9d9d6", segment.size = 0.3, min.segment.length = 0, seed = 1) +
  facet_wrap(~ comparacao, ncol = 1) +
  scale_x_continuous(breaks = c(0.05, 0.25, 0.5, 0.75, 0.95)) + scale_y_continuous(limits = c(0, max(d$hi) * 1.05), expand = c(0, 0)) +
  labs(x = "posição relativa na distribuição da Câmara do mesmo período (quantil)", y = "densidade relativa do Senado",
       title = "O Senado em relação à Câmara, antes e depois de 2026",
       subtitle = "Escala conjunta Câmara + Senado (W-NOMINATE agrupado 2019–2026, dim. 1). g > 1: o Senado tem proporcionalmente mais membros ali do que a Câmara.\nKernel (largura 0,07) sobre os ranks relativos; 2027: média de 1.000 sorteios dos previstos; faixa: IC 95 % pontual. Marcas: medianas dos partidos na Câmara de cada período.") +
  theme_minimal(base_size = 10) + theme(panel.grid.minor = element_blank(), plot.title.position = "plot", strip.text = element_text(hjust = 0, face = "bold"), plot.subtitle = element_text(size = 8))
ggsave("figures/senado_vs_camara.png", p, width = 9, height = 7, dpi = 200, bg = "white")
