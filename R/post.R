# Medianas, pivôs de 3/5 e custo de governar: Congresso 2023-26 vs 2027.
# Entradas em data/ (posições na escala comum 2019-2026, dimensão 1).
# Saídas em results/ e figures/.
library(data.table); library(ggplot2)
set.seed(2027)
cam27 <- fread("data/camara_2027.csv"); sen27 <- fread("data/senado_2027.csv")
cam23 <- unique(fread("data/camara_2023_26.csv")); sen23 <- unique(fread("data/senado_2023_26.csv"))
gov <- fread("data/governos.csv")
res <- fread("data/residuos.csv")   # CV residuals of the prediction models, by chamber and bloc (empirical predictive distribution)
pools <- split(res$residuo, paste(res$casa, res$bloco))
pool_key <- function(casa, origem, bloco) paste(fifelse(casa == "Câmara" | grepl("coattail\\)$", origem), casa, "Senado (sem coattail)"), bloco)
prep <- function(d, casa) { d <- copy(d); d[, prev := startsWith(origem, "previsto")]; d[, key := pool_key(casa, origem, bloco)]; d[, mapped := origem == "medido 2015–18 (mapeado)"]; d }
draw <- function(d) { x <- d$dim1
  for (k in unique(d$key[d$prev])) { i <- which(d$prev & d$key == k); x[i] <- x[i] + sample(pools[[k]], length(i), replace = TRUE) }
  if (any(d$mapped)) x[d$mapped] <- x[d$mapped] + rnorm(sum(d$mapped), 0, d$erro[d$mapped])
  x }
g <- function(c, v) gov$dim1[gov$casa == c & gov$governo == v]
seats <- function(x, n) quantile(x, (seq_len(n) - 0.5) / n, names = FALSE)
piv <- function(x, n) { s <- sort(x); k <- ceiling(3 * n / 5); c(veto_dir = s[n - k + 1], mediana = s[ceiling(n / 2)], veto_esq = s[k]) }
custo <- function(x, g0, k) { d <- sort(pmax(0, (x - g0) * if (g0 < 0) 1 else -1)); c(alcance = d[k], custo = sum(d[1:k])) }
sim <- function(f, d, n = 2000) { s <- replicate(n, f(draw(d))); list(media = rowMeans(s), lo = apply(s, 1, quantile, .025), hi = apply(s, 1, quantile, .975)) }
casas <- list(
  list(casa = "Câmara", n = 513, k = c(maioria = 257, `3/5` = 308, `2/3` = 342), x23 = seats(cam23$dim1, 513), d27 = prep(cam27, "Câmara")),
  list(casa = "Senado", n = 81, k = c(maioria = 41, `3/5` = 49, `2/3` = 54), x23 = seats(sen23$dim1, 81), d27 = prep(sen27, "Senado")))
pivos <- list(); custos <- list()
for (h in casas) {
  p23 <- piv(h$x23, h$n); p27 <- sim(function(x) piv(x, h$n), h$d27)
  pivos[[h$casa]] <- data.table(casa = h$casa, ponto = names(p23), `2023-26` = p23, `2027` = p27$media, lo = p27$lo, hi = p27$hi)
  for (gv in c("Lula", "Direita")) for (lim in names(h$k)) {
    c23 <- custo(h$x23, g(h$casa, gv), h$k[[lim]])
    c27 <- sim(function(x) custo(x, g(h$casa, gv), h$k[[lim]]), h$d27, 1000)
    custos[[length(custos) + 1]] <- data.table(casa = h$casa, governo = gv, limiar = lim, k = h$k[[lim]],
      alcance_2023_26 = c23[["alcance"]], alcance_2027 = c27$media[["alcance"]], custo_2023_26 = c23[["custo"]],
      custo_2027 = c27$media[["custo"]], lo = c27$lo[["custo"]], hi = c27$hi[["custo"]])
  }
}
pivos <- rbindlist(pivos); custos <- rbindlist(custos)
custos[, variacao := custo_2027 / custo_2023_26 - 1]
razao <- dcast(custos, casa + limiar ~ governo, value.var = c("custo_2023_26", "custo_2027"))[, .(casa, limiar, razao_2023_26 = custo_2023_26_Lula / custo_2023_26_Direita, razao_2027 = custo_2027_Lula / custo_2027_Direita)]
fwrite(pivos, "results/pivos.csv"); fwrite(custos, "results/custos.csv"); fwrite(razao, "results/razoes.csv")
print(pivos, digits = 2); print(custos[, .(casa, governo, limiar, custo_2023_26, custo_2027, variacao = round(100 * variacao))], digits = 3); print(razao, digits = 2)

# figura: pivôs e posições dos governos
L <- melt(pivos[, .(casa, ponto, `2023-26`, `2027`)], id.vars = c("casa", "ponto"), variable.name = "ano", value.name = "x")
L[, linha := factor(paste(casa, ano), c("Senado 2027", "Senado 2023-26", "Câmara 2027", "Câmara 2023-26"))]
L[, ponto := factor(ponto, c("veto_dir", "mediana", "veto_esq"), c("pivô 3/5 (coalizão pela direita)", "mediana", "pivô 3/5 (coalizão pela esquerda)"))]
seg <- dcast(L, linha ~ ponto, value.var = "x"); setnames(seg, 2:4, c("a", "m", "b"))
G <- gov[, .(linha = factor(paste(casa, rep(c("2023-26", "2027"), each = 2)), levels(L$linha)), governo = rep(governo, 2), x = rep(dim1, 2)), by = casa]
p <- ggplot() + geom_vline(xintercept = 0, colour = "#e3e3e0") +
  geom_segment(data = seg, aes(x = a, xend = b, y = linha, yend = linha), colour = "#d9d9d6", linewidth = 4) +
  geom_point(data = G, aes(x = x, y = linha, fill = governo), shape = 25, size = 3.5, colour = "white", position = position_nudge(y = 0.3)) +
  geom_point(data = L, aes(x = x, y = linha, shape = ponto), size = 3.2) +
  scale_shape_manual(values = c(1, 16, 2), name = NULL) +
  scale_fill_manual(values = c(Lula = "#c2410c", Direita = "#1c5cab"), labels = c(Lula = "governo Lula", Direita = "governo de direita (Bolsonaro 2019-22)"), name = NULL) +
  scale_x_continuous(breaks = seq(-1, 1, 0.5), limits = c(-1, 1)) +
  guides(fill = guide_legend(order = 1), shape = guide_legend(order = 2, nrow = 1)) +
  labs(x = "escala comum 2019-2026 (dimensão 1): esquerda / governo Lula  ·  direita / governo Bolsonaro", y = NULL,
       title = "Onde ficam a mediana e os pontos de veto, antes e depois de 2026",
       subtitle = "Barra: faixa entre os dois pivôs de 3/5. Triângulos: posição dos governos. 2027: média de 2.000 sorteios, previstos com resíduos empíricos por bloco.") +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom", legend.box = "vertical", panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(), plot.title.position = "plot")
ggsave("figures/pivos.png", p, width = 9, height = 4.6, dpi = 200, bg = "white")
