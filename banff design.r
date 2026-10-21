# Calgary-Banff stated preference design with spdesign
# Priors: Swissmetro MNL (Bierlaire, Axhausen & Abay 2001, Table 2)
#   Swiss train -> Banff bus (reference, ASC = 0)
#   Swissmetro  -> Banff rail (new mode)
#   Swiss car   -> Banff car
# Cost prior converted from CHF to CAD: -0.01038 / 1.711 = -0.0061 per CAD

library(spdesign)

utility <- list(
  car  = "b_asc_car[1.108]  * asc_car[1]  +
          b_time[-0.0126]   * time_car[c(80, 100, 120)](5:7)  +
          b_cost[-0.0061]   * cost_car[c(20, 35, 50)](5:7)",
  bus  = "b_time            * time_bus[c(100, 115, 130)](5:7) +
          b_cost            * cost_bus[c(15, 25, 35)](5:7)    +
          b_head[-0.0026]   * head_bus[c(60, 90, 120)](5:7)",
  rail = "b_asc_rail[1.302] * asc_rail[1] +
          b_time            * time_rail[c(75, 90, 105)](5:7)  +
          b_cost            * cost_rail[c(20, 35, 50)](5:7)   +
          b_head            * head_rail[c(30, 60, 90)](5:7)"
)

# Remove choice tasks where one option is better on every attribute
exclusions <- list(
  "rail_time_rail <= bus_time_bus & rail_cost_rail <= bus_cost_bus & rail_head_rail <= bus_head_bus",
  "bus_time_bus <= rail_time_rail & bus_cost_bus <= rail_cost_rail & bus_head_bus <= rail_head_rail",
  "car_time_car <= rail_time_rail & car_cost_car <= rail_cost_rail",
  "car_time_car <= bus_time_bus & car_cost_car <= bus_cost_bus"
)

set.seed(2026)
design <- generate_design(
  utility,
  rows = 18,
  model = "mnl",
  efficiency_criteria = "d-error",
  algorithm = "federov",
  draws = "scrambled-sobol",
  exclusions = exclusions,
  control = list(max_iter = 2000)
)

design <- block(design, 2)   # 2 versions x 9 choice tasks
summary(design)

# ---- Save the design ----
d <- as.data.frame(design$design)
write.csv(d, "~/Downloads/Fin_banff_design.csv", row.names = FALSE)

# ---- Diagnostics under the priors ----
b <- c(asc_car = 1.108, asc_rail = 1.302, time = -0.0126, cost = -0.0061, head = -0.0026)

# Each alternative's attributes in the order of b (one row per task)
X <- list(
  car  = cbind(1, 0, d$car_time_car,   d$car_cost_car,   0),
  bus  = cbind(0, 0, d$bus_time_bus,   d$bus_cost_bus,   d$bus_head_bus),
  rail = cbind(0, 1, d$rail_time_rail, d$rail_cost_rail, d$rail_head_rail)
)
P <- exp(sapply(X, function(x) x %*% b))
P <- P / rowSums(P)

# MNL Fisher information summed over all 18 tasks -> AVC matrix
info <- matrix(0, length(b), length(b), dimnames = list(names(b), names(b)))
for (i in seq_len(nrow(d))) {
  Xi <- rbind(X$car[i, ], X$bus[i, ], X$rail[i, ])
  p  <- P[i, ]
  info <- info + t(Xi) %*% (diag(p) - p %*% t(p)) %*% Xi
}
avc <- solve(info)
se  <- sqrt(diag(avc))

# S-estimate: replications of the full 18-task design needed for p < 0.05
params <- data.frame(prior = b, std_error = se, s_estimate = (1.96 * se / b)^2)
eff <- c(d_error = det(avc)^(1 / length(b)),
         a_error = sum(diag(avc)) / length(b),
         s_error = max(params$s_estimate))

attrs   <- grep("asc|block", names(d), invert = TRUE, value = TRUE)
balance <- t(sapply(d[attrs], table))
colnames(balance) <- c("low", "mid", "high")
n_blocks <- length(unique(d$block))

# ---- Save the report (also printed to the console) ----
sink("~/Downloads/Fin_banff_design_report.txt", split = TRUE)
cat("Calgary-Banff SP design: diagnostics under the priors\n")
cat(nrow(d), "choice tasks in", n_blocks, "blocks\n\n")
cat("Efficiency\n");                     print(round(eff, 6))
cat("\nParameters\n");                   print(round(params, 4))
cat("\nMinimum sample size: ", ceiling(eff["s_error"]), " design replications = ",
    ceiling(eff["s_error"]) * n_blocks, " respondents (", ceiling(eff["s_error"]),
    " per block)\n", sep = "")
cat("\nLevel balance (times each level appears)\n"); print(balance)
cat("\nCorrelation between attributes and block\n"); print(round(cor(d[attrs], d$block)[, 1], 3))
cat("\nExpected choice shares per task\n")
print(cbind(task = seq_len(nrow(d)), block = d$block, round(P, 2)))
sink()
