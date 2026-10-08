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
