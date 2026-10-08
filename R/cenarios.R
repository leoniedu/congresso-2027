# The post's quantities under three treatments of the 180 predicted deputies:
#   neutro   = v2 model (no regional term), residual pool from the 2023 cohort;
#   esquerda = model with the state PT share, coefficients and residuals from the 2023 cohort (left government);
#   direita  = same specification, coefficients and residuals from the 2019 cohort (right government).
# Senate predictions are the same in all three (its model has no scenario split).
library(data.table)
set.seed(2027)
cam27 <- fread("data/camara_2027.csv"); sen27 <- fread("data/senado_2027.csv"); cam23 <- unique(fread("data/camara_2023_26.csv")); sen23 <- unique(fread("data/senado_2023_26.csv"))
gov <- fread("data/governos.csv"); res <- fread("data/residuos.csv")
g <- function(c, v) gov$dim1[gov$casa == c & gov$governo == v]
seats <- function(x, n) quantile(x, (seq_len(n) - 0.5) / n, names = FALSE)
piv <- function(x, n) { s <- sort(x); k <- ceiling(3 * n / 5); c(veto_dir = s[n - k + 1], mediana = s[ceiling(n / 2)], veto_esq = s[k]) }
custo <- function(x, g0, k) { d <- sort(pmax(0, (x - g0) * if (g0 < 0) 1 else -1)); c(alcance = d[k], custo = sum(d[1:k])) }
mk <- function(d, casa, cenario, col) { d <- copy(d); d[, x := get(col)]; d[, prev := startsWith(origem, "previsto")]
  rc <- if (casa == "Câmara") res[res$casa == "Câmara" & res$cenario == cenario, ] else res[res$casa != "Câmara" & res$cenario == "neutro", ]
  pools <- if (casa == "Câmara") split(rc$residuo, rc$bloco) else split(rc$residuo, paste(rc$casa, rc$bloco))
  d[, key := if (casa == "Câmara") bloco else paste(fifelse(grepl("coattail\\)$", origem), "Senado", "Senado (sem coattail)"), bloco)]
  d[, mapped := origem == "medido 2015–18 (mapeado)"]; list(d = d, pools = pools) }
draw <- function(o) { d <- o$d; x <- d$x
  for (k in unique(d$key[d$prev])) { i <- which(d$prev & d$key == k); x[i] <- x[i] + sample(o$pools[[k]], length(i), replace = TRUE) }
  if (any(d$mapped)) x[d$mapped] <- x[d$mapped] + rnorm(sum(d$mapped), 0, d$erro[d$mapped]); x }
sim <- function(f, o, n) { s <- replicate(n, f(draw(o))); list(media = rowMeans(s), lo = apply(s, 1, quantile, .025), hi = apply(s, 1, quantile, .975)) }
casas <- list(Câmara = list(n = 513, k = c(maioria = 257, `3/5` = 308, `2/3` = 342), x23 = seats(cam23$dim1, 513)), Senado = list(n = 81, k = c(maioria = 41, `3/5` = 49, `2/3` = 54), x23 = seats(sen23$dim1, 81)))
out <- list()
for (cen in c("neutro", "esquerda", "direita")) {
  oc <- mk(cam27, "Câmara", cen, switch(cen, neutro = "dim1", esquerda = "dim1_esq", direita = "dim1_dir")); os <- mk(sen27, "Senado", cen, "dim1")
  for (casa in names(casas)) { h <- casas[[casa]]; o <- if (casa == "Câmara") oc else os
    p27 <- sim(function(x) piv(x, h$n), o, 1000); p23 <- piv(h$x23, h$n)
    for (pt in names(p23)) out[[length(out) + 1]] <- data.table(cenario = cen, casa = casa, medida = pt, governo = NA_character_, limiar = NA_character_, `2023-26` = p23[[pt]], `2027` = p27$media[[pt]], lo = p27$lo[[pt]], hi = p27$hi[[pt]])
    for (gv in c("Lula", "Direita")) for (lim in names(h$k)) { c23 <- custo(h$x23, g(casa, gv), h$k[[lim]]); c27 <- sim(function(x) custo(x, g(casa, gv), h$k[[lim]]), o, 500)
      out[[length(out) + 1]] <- data.table(cenario = cen, casa = casa, medida = "custo", governo = gv, limiar = lim, `2023-26` = c23[["custo"]], `2027` = c27$media[["custo"]], lo = c27$lo[["custo"]], hi = c27$hi[["custo"]]) } }
}
out <- rbindlist(out); fwrite(out, "results/cenarios.csv")
cam <- out[casa == "Câmara"]
cat("Câmara, medians and 3/5 pivots by scenario:\n"); print(dcast(cam[medida != "custo"], medida ~ cenario, value.var = "2027")[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 3) else x)])
cat("\nCâmara, cost 2027 by scenario (2023-26 reference in the last column):\n"); w <- dcast(cam[medida == "custo"], governo + limiar ~ cenario, value.var = "2027"); w <- merge(w, unique(cam[medida == "custo", .(governo, limiar, ref = `2023-26`)]), by = c("governo", "limiar")); print(w[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 1) else x)])
