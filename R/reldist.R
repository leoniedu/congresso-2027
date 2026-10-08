# Relative distribution with the reldist package (Handcock & Morris): density, location/shape
# decomposition and polarization indices, 58th vs 57th Câmara, over draws of the predicted positions.
library(data.table); library(reldist)
set.seed(2027)
cam23 <- unique(fread("data/camara_2023_26.csv")); cam27 <- fread("data/camara_2027.csv")
res <- fread("data/residuos.csv"); pools <- split(res$residuo, paste(res$casa, res$bloco))
cam27[, prev := startsWith(origem, "previsto")][, key := paste("Câmara", bloco)][, mapped := origem == "medido 2015–18 (mapeado)"]
draw <- function(d) { x <- d$dim1
  for (k in unique(d$key[d$prev])) { i <- which(d$prev & d$key == k); x[i] <- x[i] + sample(pools[[k]], length(i), replace = TRUE) }
  if (any(d$mapped)) x[d$mapped] <- x[d$mapped] + rnorm(sum(d$mapped), 0, d$erro[d$mapped]); x }
y0 <- cam23$dim1
w <- function(v) rep(1, length(v))
one <- function(y) {
  rd <- reldist(y = y, yo = y0, graph = FALSE, ci = FALSE, smooth = 0.35, method = "gam")
  # rpy / rpluy return (lower CI, estimate, upper CI); keep the estimate
  c(mrp = rpy(y = y, yo = y0, ywgt = w(y), yowgt = w(y0), pvalue = FALSE)[2],
    lrp = rpluy(y = y, yo = y0, ywgt = w(y), yowgt = w(y0), pvalue = FALSE, lower = TRUE, upper = FALSE)[2],
    urp = rpluy(y = y, yo = y0, ywgt = w(y), yowgt = w(y0), pvalue = FALSE, lower = FALSE, upper = TRUE)[2],
    entropia = rd$entropy, g = as.numeric(rd$y)[seq(1, 5000, 50)])
}
pt <- one(cam27$dim1)
sims <- replicate(500, one(draw(cam27)))
idx <- c("mrp", "lrp", "urp", "entropia")
out <- data.table(indice = idx, ponto = pt[idx], media = rowMeans(sims[idx, ]), lo = apply(sims[idx, ], 1, quantile, .025), hi = apply(sims[idx, ], 1, quantile, .975))
print(out, digits = 3)
fwrite(out, "results/reldist_indices.csv")
rd0 <- reldist(y = cam27$dim1, yo = y0, graph = FALSE, ci = FALSE, smooth = 0.35, method = "gam")
curva <- data.table(r = rd0$x[seq(1, 5000, 50)], g_ponto = as.numeric(rd0$y)[seq(1, 5000, 50)], g_media = rowMeans(sims[-(1:4), ]), lo = apply(sims[-(1:4), ], 1, quantile, .025), hi = apply(sims[-(1:4), ], 1, quantile, .975))
fwrite(curva, "results/reldist_curva.csv")
# location/shape decomposition at the point prediction (median shift is ~0, so shape ≈ overall)
dec <- reldist(y = cam27$dim1, yo = y0, show = "effect", graph = FALSE, ci = FALSE, smooth = 0.35, method = "gam")
cat("entropy overall:", round(rd0$entropy, 4), " shape-only (location-adjusted):", round(dec$entropy, 4), "\n")
