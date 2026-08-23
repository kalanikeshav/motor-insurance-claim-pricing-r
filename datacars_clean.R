# ============================================================
# DATA CAR INSURANCE PRICING ANALYSIS
# Frequency-Severity Modelling with Train/Test Validation
# ============================================================

# ============================================================
# 1. PACKAGES AND DATA
# ============================================================

library(insuranceData)
library(dplyr)
library(ggplot2)
library(MASS)

data(dataCar)

dim(dataCar)
names(dataCar)
str(dataCar)
head(dataCar)
summary(dataCar)

x <- dataCar


# ============================================================
# 2. DATA AUDIT AND CONSISTENCY CHECKS
# ============================================================

# Basic claim consistency checks
sum(x$claimcst0 >= 1)
sum(x$numclaims > 0 & x$clm == 0)

# Missing values and duplicate rows
colSums(is.na(x))
sum(duplicated(x))

# 378 duplicate rows are retained because there is no strong
# evidence in the analysis to remove them.

# Convert categorical variables to factors
x$agecat <- factor(x$agecat)
x$veh_age <- factor(x$veh_age)

# Check variable classes and categorical levels
table(sapply(x, class))
unique(x$area)
unique(x$veh_body)
unique(x$veh_age)
unique(x$gender)
unique(x$agecat)

# Further claim consistency checks
table(x$clm, x$numclaims > 0)
table(x$claimcst0 > 0, x$numclaims == 0)
table(x$claimcst0 == 0, x$numclaims > 0)
table(x$numclaims)


# ============================================================
# 3. OVERALL PORTFOLIO METRICS
# ============================================================

total_exp <- sum(x$exposure)
total_clm <- sum(x$numclaims)

overall_freq <- total_clm / total_exp
overall_freq

total_clm_cost <- sum(x$claimcst0)

overall_sev <- total_clm_cost / total_clm
overall_sev

pure_prem <- overall_freq * overall_sev
pure_prem


# ============================================================
# 4. UNIVARIATE EDA
# ============================================================

# ------------------------------------------------------------
# 4.1 Distribution by driver age category
# ------------------------------------------------------------

x %>%
  group_by(agecat) %>%
  summarise(
    exposure = sum(exposure),
    claims = sum(numclaims),
    claimcost = sum(claimcst0),
    frequency = claims / exposure,
    severity = claimcost / claims,
    pureprem = frequency * severity
  )

# ------------------------------------------------------------
# 4.2 Distribution by area
# ------------------------------------------------------------

x %>%
  group_by(area) %>%
  summarise(
    exposure = sum(exposure),
    claims = sum(numclaims),
    claimcost = sum(claimcst0),
    frequency = claims / exposure,
    severity = claimcost / claims,
    purepremv = frequency * severity
  )

# ------------------------------------------------------------
# 4.3 Distribution by gender
# ------------------------------------------------------------

x %>%
  group_by(gender) %>%
  summarise(
    exposure = sum(exposure),
    claims = sum(numclaims),
    claimcost = sum(claimcst0),
    frequency = claims / exposure,
    severity = claimcost / claims,
    purepremv = frequency * severity
  )

# ------------------------------------------------------------
# 4.4 Distribution by vehicle body
# ------------------------------------------------------------

x %>%
  group_by(veh_body) %>%
  summarise(
    exposure = sum(exposure),
    claims = sum(numclaims),
    claimcost = sum(claimcst0),
    frequency = claims / exposure,
    severity = claimcost / claims,
    purepremv = frequency * severity
  )

# ------------------------------------------------------------
# 4.5 Distribution by vehicle age
# ------------------------------------------------------------

x %>%
  group_by(veh_age) %>%
  summarise(
    exposure = sum(exposure),
    claims = sum(numclaims),
    claimcost = sum(claimcst0),
    frequency = claims / exposure,
    severity = claimcost / claims,
    purepremv = frequency * severity
  )

table(x$veh_body)


# ============================================================
# 5. EDA VISUALISATIONS
# ============================================================

# ------------------------------------------------------------
# 5.1 Claim frequency by age category
# ------------------------------------------------------------

age_frequency <- x %>%
  group_by(agecat) %>%
  summarise(
    exposure = sum(exposure),
    claims = sum(numclaims),
    frequency = claims / exposure * 100
  )

ggplot(age_frequency, aes(x = factor(agecat), y = frequency)) +
  geom_col() +
  labs(
    title = "Claim Frequency by Age Category",
    x = "Age Category",
    y = "Frequency (%)"
  ) +
  theme_minimal()


# ------------------------------------------------------------
# 5.2 Claim severity by age category
# ------------------------------------------------------------

age_severity <- x %>%
  group_by(agecat) %>%
  summarise(
    claimcost = sum(claimcst0),
    claims = sum(numclaims),
    severity = claimcost / claims
  )

ggplot(age_severity, aes(x = factor(agecat), y = severity)) +
  geom_col() +
  labs(
    title = "Claim Severity by Age",
    y = "Severity",
    x = "Age Category"
  ) +
  theme_minimal()


# ------------------------------------------------------------
# 5.3 Pure premium by age category
# ------------------------------------------------------------

age_pp <- x %>%
  group_by(agecat) %>%
  summarise(
    Exposure = sum(exposure),
    Claims = sum(numclaims),
    ClaimCost = sum(claimcst0),
    PurePremium = ClaimCost / Exposure
  )

ggplot(age_pp, aes(x = factor(agecat), y = PurePremium)) +
  geom_col() +
  labs(
    title = "Pure Premium by Driver Age Category",
    x = "Driver Age Category",
    y = "Pure Premium ($)"
  ) +
  theme_minimal()


# ------------------------------------------------------------
# 5.4 Claim severity distributions
# ------------------------------------------------------------

claims <- x %>%
  filter(numclaims > 0)

hist(
  claims$claimcst0,
  breaks = 30,
  main = "Distribution of Claim Severity",
  xlab = "Claim Amount"
)

hist(
  log(claims$claimcst0),
  breaks = 30,
  main = "Log Claim Severity",
  xlab = "Log Claim Amount"
)


# ------------------------------------------------------------
# 5.5 Vehicle value distribution
# ------------------------------------------------------------

hist(
  x$veh_value,
  breaks = 30,
  main = "Distribution of Vehicle Value",
  xlab = "Vehicle Value ($10,000s)"
)


# ============================================================
# 6. MULTIVARIATE EDA
# ============================================================

# ------------------------------------------------------------
# 6.1 Claim frequency by age category and gender
# ------------------------------------------------------------

age_gender <- x %>%
  group_by(agecat, gender) %>%
  summarise(
    Exposure = sum(exposure),
    Claims = sum(numclaims),
    Frequency = Claims / Exposure,
    .groups = "drop"
  )

age_gender

ggplot(
  age_gender,
  aes(
    x = agecat,
    y = Frequency * 100,
    fill = gender
  )
) +
  geom_col(position = "dodge") +
  labs(
    title = "Claim Frequency by Age Category and Gender",
    x = "Age Category",
    y = "Claim Frequency (%)",
    fill = "Gender"
  ) +
  theme_minimal()


# ------------------------------------------------------------
# 6.2 Claim frequency by age category and area
# ------------------------------------------------------------

age_area <- x %>%
  group_by(agecat, area) %>%
  summarise(
    Exposure = sum(exposure),
    Claims = sum(numclaims),
    Frequency = Claims / Exposure,
    .groups = "drop"
  )

ggplot(
  age_area,
  aes(
    x = agecat,
    y = Frequency * 100,
    fill = area
  )
) +
  geom_col(position = "dodge") +
  labs(
    title = "Claim Frequency by Age Category and Area",
    x = "Age Category",
    y = "Claim Frequency (%)",
    fill = "Area"
  ) +
  theme_minimal()


# ------------------------------------------------------------
# 6.3 Pure premium by age category and gender
# ------------------------------------------------------------

age_gender_pp <- x %>%
  group_by(agecat, gender) %>%
  summarise(
    Exposure = sum(exposure),
    ClaimCost = sum(claimcst0),
    PurePremium = ClaimCost / Exposure,
    .groups = "drop"
  )

ggplot(
  age_gender_pp,
  aes(
    x = agecat,
    y = PurePremium,
    fill = gender
  )
) +
  geom_col(position = "dodge") +
  labs(
    title = "Pure Premium by Age Category and Gender",
    x = "Age Category",
    y = "Pure Premium ($)",
    fill = "Gender"
  ) +
  theme_minimal()


# ------------------------------------------------------------
# 6.4 Vehicle value bands
# ------------------------------------------------------------

summary(x$veh_value)

x$veh_value_band <- cut(
  x$veh_value,
  breaks = c(0, 0.5, 1, 1.5, 2, 3, 5, Inf),
  right = FALSE
)

vehicle_value_freq <- x %>%
  group_by(veh_value_band) %>%
  summarise(
    Exposure = sum(exposure),
    Claims = sum(numclaims),
    ClaimCost = sum(claimcst0),
    Frequency = Claims / Exposure,
    Severity = ClaimCost / Claims,
    PurePremium = ClaimCost / Exposure,
    .groups = "drop"
  )

vehicle_value_freq

ggplot(
  vehicle_value_freq,
  aes(x = veh_value_band, y = PurePremium)
) +
  geom_col() +
  labs(
    title = "Pure Premium by Vehicle Value",
    x = "Vehicle Value Band",
    y = "Pure Premium ($)"
  ) +
  theme_minimal()


# ============================================================
# 7. SEVERITY EDA
# ============================================================

# Claim-level severity dataset
severity_data <- x %>%
  filter(claimcst0 > 0)

nrow(severity_data)
summary(severity_data$claimcst0)

hist(
  severity_data$claimcst0,
  breaks = 50,
  main = "Claim Severity Distribution",
  xlab = "Claim Amount"
)

hist(
  log(severity_data$claimcst0),
  breaks = 50,
  main = "Log Claim Severity Distribution",
  xlab = "Log Claim Amount"
)

# claimcst0 is the total claim cost against the total
# number of claims on a policy, so severity is calculated
# as claim cost divided by claim count.

severity_data <- x %>%
  filter(numclaims > 0) %>%
  mutate(
    severity = claimcst0 / numclaims
  )

summary(severity_data$severity)

hist(
  severity_data$severity,
  breaks = 50,
  main = "Claim Severity Distribution",
  xlab = "Severity"
)

hist(
  log(severity_data$severity),
  breaks = 50,
  main = "Log Claim Severity",
  xlab = "Log Severity"
)

overall_severity <- sum(severity_data$claimcst0) /
  sum(severity_data$numclaims)

overall_frequency <- sum(x$numclaims) / sum(x$exposure)

overall_pure_premium <- overall_frequency * overall_severity

overall_frequency
overall_severity
overall_pure_premium


# ============================================================
# 8. TRAIN / TEST SPLIT
# ============================================================

set.seed(123)

train_index <- sample(
  seq_len(nrow(x)),
  size = 0.80 * nrow(x)
)

train <- x[train_index, ]
test <- x[-train_index, ]

# Check split
dim(train)
dim(test)

# Check exposure and claims
sum(train$exposure)
sum(test$exposure)

sum(train$numclaims)
sum(test$numclaims)


# ============================================================
# 9. FREQUENCY MODELLING
# ============================================================

# ------------------------------------------------------------
# 9.1 Poisson frequency model
# ------------------------------------------------------------

poisson_model <- glm(
  numclaims ~ agecat + veh_age + gender + area + veh_body +
    offset(log(exposure)),
  family = poisson(link = "log"),
  data = train
)

summary(poisson_model)

exp(coef(poisson_model))
exp(confint(poisson_model))


# ------------------------------------------------------------
# 9.2 Poisson dispersion diagnostics
# ------------------------------------------------------------

poisson_deviance_dispersion <-
  deviance(poisson_model) / df.residual(poisson_model)

poisson_pearson_dispersion <-
  sum(residuals(poisson_model, type = "pearson")^2) /
  df.residual(poisson_model)

poisson_deviance_dispersion
poisson_pearson_dispersion


# ------------------------------------------------------------
# 9.3 Negative Binomial frequency model
# ------------------------------------------------------------

nb_model <- MASS::glm.nb(
  numclaims ~ agecat + veh_age + gender + area + veh_body +
    offset(log(exposure)),
  data = train
)

summary(nb_model)


# ------------------------------------------------------------
# 9.4 Compare frequency models
# ------------------------------------------------------------

AIC(poisson_model, nb_model)

nb_deviance_dispersion <-
  deviance(nb_model) / df.residual(nb_model)

nb_pearson_dispersion <-
  sum(residuals(nb_model, type = "pearson")^2) /
  df.residual(nb_model)

nb_deviance_dispersion
nb_pearson_dispersion


# ============================================================
# 10. FREQUENCY MODEL VALIDATION ON TEST DATA
# ============================================================

test$pred_frequency <- predict(
  nb_model,
  newdata = test,
  type = "response"
)

# Actual frequency
actual_frequency_test <-
  sum(test$numclaims) / sum(test$exposure)

# Predicted frequency
predicted_frequency_test <-
  sum(test$pred_frequency) / sum(test$exposure)

frequency_validation <- c(
  Actual_Frequency = actual_frequency_test,
  Predicted_Frequency = predicted_frequency_test,
  Difference = predicted_frequency_test - actual_frequency_test,
  Difference_pct =
    (predicted_frequency_test / actual_frequency_test - 1) * 100
)

frequency_validation


# ============================================================
# 11. FREQUENCY CALIBRATION BY AGE
# ============================================================

frequency_calibration_age <- test %>%
  group_by(agecat) %>%
  summarise(
    exposure = sum(exposure),
    observed_claims = sum(numclaims),
    predicted_claims = sum(pred_frequency),
    observed_frequency = observed_claims / exposure,
    predicted_frequency = predicted_claims / exposure,
    difference_pct =
      (predicted_frequency / observed_frequency - 1) * 100,
    .groups = "drop"
  )

frequency_calibration_age


# ============================================================
# 12. FREQUENCY RESIDUAL DIAGNOSTICS
# ============================================================

par(mfrow = c(1, 2))

plot(
  fitted(nb_model),
  residuals(nb_model, type = "pearson"),
  xlab = "Fitted Frequency",
  ylab = "Pearson Residual",
  main = "Pearson Residuals vs Fitted"
)

abline(h = 0)

plot(
  fitted(nb_model),
  residuals(nb_model, type = "deviance"),
  xlab = "Fitted Frequency",
  ylab = "Deviance Residual",
  main = "Deviance Residuals vs Fitted"
)

abline(h = 0)

par(mfrow = c(1, 1))


# ============================================================
# 13. SEVERITY DATA FOR TRAIN / TEST
# ============================================================

train_severity <- train %>%
  filter(numclaims > 0) %>%
  mutate(
    severity = claimcst0 / numclaims
  )

test_severity <- test %>%
  filter(numclaims > 0) %>%
  mutate(
    severity = claimcst0 / numclaims
  )


# ============================================================
# 14. GAMMA SEVERITY MODEL
# ============================================================

severity_model <- glm(
  severity ~ agecat + veh_age + gender + area + veh_body,
  family = Gamma(link = "log"),
  weights = numclaims,
  data = train_severity
)

summary(severity_model)

exp(coef(severity_model))
exp(confint(severity_model))

gamma_dispersion <-
  deviance(severity_model) /
  df.residual(severity_model)

gamma_dispersion

# Gamma model diagnostic plots
par(mfrow = c(2, 2))
plot(severity_model)
par(mfrow = c(1, 1))


# ============================================================
# 15. LOGNORMAL SEVERITY MODEL
# ============================================================

lognormal_model <- glm(
  log(severity) ~ agecat + veh_age + gender + area + veh_body,
  weights = numclaims,
  data = train_severity
)

summary(lognormal_model)

AIC(severity_model, lognormal_model)


# ============================================================
# 16. SEVERITY PREDICTIONS ON TEST DATA
# ============================================================

test_severity$pred_gamma <- predict(
  severity_model,
  newdata = test_severity,
  type = "response"
)

sigma2 <- summary(lognormal_model)$dispersion

test_severity$pred_lognormal <- exp(
  predict(
    lognormal_model,
    newdata = test_severity
  ) + sigma2 / 2
)


# ============================================================
# 17. SEVERITY VALIDATION
# ============================================================

actual_severity_test <-
  sum(test_severity$claimcst0) /
  sum(test_severity$numclaims)

predicted_gamma_severity <-
  sum(
    test_severity$pred_gamma *
      test_severity$numclaims
  ) /
  sum(test_severity$numclaims)

predicted_lognormal_severity <-
  sum(
    test_severity$pred_lognormal *
      test_severity$numclaims
  ) /
  sum(test_severity$numclaims)

severity_validation <- c(
  Actual_Severity = actual_severity_test,
  Gamma = predicted_gamma_severity,
  Lognormal = predicted_lognormal_severity
)

severity_validation


# ============================================================
# 18. SEVERITY CALIBRATION BY AGE
# ============================================================

severity_calibration <- test_severity %>%
  group_by(agecat) %>%
  summarise(
    claims = sum(numclaims),

    observed = sum(
      severity * numclaims
    ) / sum(numclaims),

    gamma_pred = sum(
      pred_gamma * numclaims
    ) / sum(numclaims),

    lognormal_pred = sum(
      pred_lognormal * numclaims
    ) / sum(numclaims),

    .groups = "drop"
  )

severity_calibration


# ============================================================
# 19. FINAL FREQUENCY-SEVERITY PREDICTIONS
# ============================================================

# Predict frequency for every policy in test set
test$pred_frequency <- predict(
  nb_model,
  newdata = test,
  type = "response"
)

# Predict severity for every policy
test$pred_severity <- predict(
  severity_model,
  newdata = test,
  type = "response"
)

# Expected claim cost per policy
test$pred_loss <-
  test$pred_frequency * test$pred_severity

# Expected pure premium
test$pred_pure_premium <-
  test$pred_loss / test$exposure


# ============================================================
# 20. ACTUAL VS PREDICTED PORTFOLIO PURE PREMIUM
# ============================================================

actual_loss_test <-
  sum(test$claimcst0)

predicted_loss_test <-
  sum(test$pred_loss)

actual_pure_premium_test <-
  actual_loss_test / sum(test$exposure)

predicted_pure_premium_test <-
  predicted_loss_test / sum(test$exposure)

business_result <- data.frame(
  Metric = c(
    "Actual Pure Premium",
    "Predicted Pure Premium",
    "Difference",
    "Difference (%)"
  ),

  Value = c(
    actual_pure_premium_test,
    predicted_pure_premium_test,
    predicted_pure_premium_test -
      actual_pure_premium_test,
    (predicted_pure_premium_test /
       actual_pure_premium_test - 1) * 100
  )
)

business_result


# ============================================================
# 21. PREDICTED PURE PREMIUM BY AGE CATEGORY
# ============================================================

premium_by_age <- test %>%
  group_by(agecat) %>%
  summarise(

    Exposure = sum(exposure),

    Actual_Loss = sum(claimcst0),

    Predicted_Loss = sum(pred_loss),

    Actual_Pure_Premium =
      Actual_Loss / Exposure,

    Predicted_Pure_Premium =
      Predicted_Loss / Exposure,

    Difference_pct =
      (Predicted_Pure_Premium /
         Actual_Pure_Premium - 1) * 100,

    .groups = "drop"
  )

premium_by_age


# ============================================================
# 22. ACTUAL VS PREDICTED PURE PREMIUM BY AGE
# ============================================================

premium_by_age_long <- premium_by_age %>%
  dplyr::select(
    agecat,
    Actual_Pure_Premium,
    Predicted_Pure_Premium
  ) %>%
  tidyr::pivot_longer(
    cols = c(
      Actual_Pure_Premium,
      Predicted_Pure_Premium
    ),
    names_to = "Metric",
    values_to = "Pure_Premium"
  )

ggplot(
  premium_by_age_long,
  aes(
    x = agecat,
    y = Pure_Premium,
    fill = Metric
  )
) +
  geom_col(position = "dodge") +
  labs(
    title = "Actual vs Predicted Pure Premium by Age",
    x = "Driver Age Category",
    y = "Pure Premium ($)",
    fill = ""
  ) +
  theme_minimal()


# ============================================================
# 23. END OF ANALYSIS
# ============================================================
