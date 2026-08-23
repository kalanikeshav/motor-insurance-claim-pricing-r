# Non-Life Insurance Claim Pricing: Frequency-Severity Modelling in R

## Project Overview

This project develops a **non-life motor insurance pricing model** using the `dataCar` dataset from the `insuranceData` R package.

The objective is to estimate expected claim cost at the policy level by modelling the two main components of insurance risk separately:

1. **Claim Frequency** — how often claims occur.
2. **Claim Severity** — the average cost of a claim when a claim occurs.

These components are then combined to estimate **expected loss / pure premium**.

The project follows a complete actuarial pricing workflow:

> Data Audit → Exploratory Data Analysis → Train/Test Split → Frequency Modelling → Frequency Validation → Severity Modelling → Severity Validation → Frequency × Severity → Pure Premium → Business Validation

---

## Project Name

### **Motor Insurance Claim Pricing: Frequency-Severity Modelling in R**

A shorter GitHub repository name could be:

`motor-insurance-claim-pricing-r`

---

## Business Objective

For a motor insurance portfolio, an insurer needs to understand how different policyholder and vehicle characteristics affect expected claims.

The central pricing question is:

> **How much expected claim cost should be associated with a policy, based on its characteristics and exposure?**

The project addresses this using a traditional **frequency-severity actuarial pricing framework**.

The expected loss is represented as:

\[
Expected\ Loss = Expected\ Frequency \times Expected\ Severity
\]

and pure premium is calculated as:

\[
Pure\ Premium =
\frac{Expected\ Claim\ Cost}{Exposure}
\]

The final analysis compares actual and model-predicted pure premium on previously unseen test data.

---

## Dataset

The project uses the `dataCar` dataset from the R package `insuranceData`.

The dataset contains motor insurance policy-level observations with variables describing:

- Driver age category
- Vehicle age
- Gender
- Geographic area
- Vehicle body type
- Vehicle value
- Exposure
- Number of claims
- Total claim cost

The script begins by loading and inspecting the dataset before performing the modelling workflow.

---

## 1. Data Audit

The first stage checks the structure and consistency of the data.

The script examines:

- Number of observations and variables
- Variable names
- Data types
- Initial observations
- Summary statistics
- Missing values
- Duplicate rows
- Unique values of categorical variables
- Claim-related consistency checks

Examples of claim consistency checks include comparing:

- `numclaims`
- `clm`
- `claimcst0`

The project identifies duplicate rows but does **not automatically remove them**, because the analysis does not establish sufficient evidence that they are erroneous observations.

Categorical variables such as `agecat` and `veh_age` are converted to factors for modelling.

---

## 2. Portfolio-Level Metrics

Before modelling, the script calculates overall portfolio metrics.

### Exposure

Total exposure is:

\[
Total\ Exposure = \sum Exposure
\]

### Total Claims

\[
Total\ Claims = \sum Number\ of\ Claims
\]

### Overall Claim Frequency

\[
Frequency =
\frac{Total\ Claims}{Total\ Exposure}
\]

### Overall Claim Severity

\[
Severity =
\frac{Total\ Claim\ Cost}{Total\ Claims}
\]

### Pure Premium

\[
Pure\ Premium =
Frequency \times Severity
\]

This establishes a baseline against which the modelling results can be understood.

---

# 3. Exploratory Data Analysis

The EDA investigates how claim experience varies across important rating factors.

The analysis considers:

- Driver age category
- Geographic area
- Gender
- Vehicle body type
- Vehicle age
- Vehicle value

For categorical variables, the project calculates:

- Exposure
- Number of claims
- Claim cost
- Claim frequency
- Claim severity
- Pure premium

This allows the portfolio to be viewed from both a frequency and severity perspective.

---

## 4. Visual EDA

The project generates visualisations for important relationships in the data.

Examples include:

### Claim Frequency by Age

Shows how the observed frequency of claims varies across driver age categories.

### Claim Severity by Age

Shows differences in average claim cost across age categories.

### Pure Premium by Age

Combines claim frequency and severity into an overall expected claim-cost measure.

### Claim Severity Distribution

The distribution of claim amounts is examined both:

- On the original scale
- On the logarithmic scale

The log transformation is particularly useful for understanding the skewness commonly observed in insurance claim costs.

### Vehicle Value Distribution

The project also examines the distribution of vehicle value.

Vehicle value is subsequently grouped into bands to examine how pure premium varies with vehicle value.

---

# 5. Multivariate Frequency Modelling

After EDA, the project moves to multivariate modelling.

The response variable is:

`numclaims`

The explanatory variables are:

- `agecat`
- `veh_age`
- `gender`
- `area`
- `veh_body`

Exposure is incorporated through an offset:

```r
offset(log(exposure))
```

This allows the model to account for different amounts of exposure across policies.

---

## 6. Poisson Frequency Model

The first frequency model is a Poisson GLM with a log link.

Conceptually:

\[
E[N_i] =
Exposure_i \times
\exp(X_i\beta)
\]

where:

- \(N_i\) = number of claims
- \(Exposure_i\) = policy exposure
- \(X_i\) = policy characteristics
- \(\beta\) = model coefficients

The script examines:

- Model summary
- Exponentiated coefficients
- Confidence intervals
- Deviance dispersion
- Pearson dispersion

The dispersion diagnostics are important because the Poisson distribution assumes that the conditional variance is approximately equal to the conditional mean.

---

# 7. Negative Binomial Frequency Model

Insurance claim counts commonly exhibit **overdispersion**, where the observed variance is greater than what a Poisson model can accommodate.

The project therefore fits a Negative Binomial model:

```r
glm.nb(...)
```

The Negative Binomial model is compared with the Poisson model using:

- AIC
- Deviance dispersion
- Pearson dispersion

The model is then used as the final frequency model for test-set prediction.

---

# 8. Frequency Model Validation

The dataset is divided into:

- **80% training data**
- **20% test data**

A fixed random seed is used to make the split reproducible.

The frequency models are fitted only on the training data.

Predictions are then generated for the unseen test data.

The project calculates:

### Actual Test Frequency

\[
Actual\ Frequency =
\frac{\sum Claims}{\sum Exposure}
\]

### Predicted Test Frequency

\[
Predicted\ Frequency =
\frac{\sum Predicted\ Claims}{\sum Exposure}
\]

The difference and percentage difference between actual and predicted frequency are then calculated.

---

# 9. Frequency Calibration by Age

Frequency calibration is also performed across driver age categories.

For every age category, the analysis compares:

- Exposure
- Observed claims
- Predicted claims
- Observed frequency
- Predicted frequency
- Percentage difference

This helps determine whether the model is systematically over- or under-predicting claim frequency for particular segments.

---

# 10. Frequency Residual Diagnostics

The final Negative Binomial frequency model is evaluated using residual diagnostics.

Two diagnostic plots are generated:

1. **Pearson residuals vs fitted frequency**
2. **Deviance residuals vs fitted frequency**

These plots help assess whether there are systematic patterns that could indicate model misspecification.

---

# 11. Severity Dataset

Frequency modelling uses all policies because policies with zero claims contain important information about claim frequency.

Severity modelling is different.

Only policies with at least one claim are included:

```r
filter(numclaims > 0)
```

For these policies, individual claim severity is calculated as:

\[
Severity =
\frac{Total\ Claim\ Cost}{Number\ of\ Claims}
\]

This creates the severity modelling dataset.

Both training and test severity datasets are created separately to maintain the train/test modelling framework.

---

# 12. Gamma Severity Model

The first severity model is a Gamma GLM with a log link.

The response variable is:

`severity`

The explanatory variables are:

- `agecat`
- `veh_age`
- `gender`
- `area`
- `veh_body`

The model uses `numclaims` as weights.

The Gamma model is appropriate for modelling positive, right-skewed claim severity.

The script evaluates:

- Model summary
- Exponentiated coefficients
- Confidence intervals
- Deviance dispersion
- Standard GLM diagnostic plots

---

# 13. Lognormal Severity Model

A second severity model is fitted using the logarithm of claim severity:

```r
log(severity)
```

This provides an alternative way of modelling the strongly right-skewed severity distribution.

The Gamma and Lognormal models are compared using AIC.

For the Lognormal model, the prediction is transformed back to the original severity scale while accounting for the estimated variance:

\[
E[Y] =
\exp(\mu + \frac{\sigma^2}{2})
\]

---

# 14. Severity Validation

Severity predictions are generated on the test-set positive-claim policies.

The project calculates:

- Actual test severity
- Predicted Gamma severity
- Predicted Lognormal severity

The predictions are claim-weighted so that policies with more claims contribute proportionately to the portfolio-level severity estimate.

This allows the two severity models to be compared on unseen data rather than relying only on training-set fit.

---

# 15. Final Frequency-Severity Pricing Model

The final business calculation combines the selected frequency and severity models.

For each test-set policy:

### Predicted Frequency

\[
\widehat{Frequency}_i
\]

is obtained from the Negative Binomial model.

### Predicted Severity

\[
\widehat{Severity}_i
\]

is obtained from the Gamma severity model.

### Predicted Expected Loss

\[
\widehat{Loss}_i =
\widehat{Frequency}_i
\times
\widehat{Severity}_i
\]

### Predicted Pure Premium

\[
\widehat{Pure\ Premium}_i =
\frac{\widehat{Loss}_i}{Exposure_i}
\]

This produces the final model-based expected claim cost for each policy.

---

# 16. Business Validation

The model's portfolio-level performance is evaluated on the test set.

The analysis compares:

- Actual portfolio pure premium
- Predicted portfolio pure premium
- Absolute difference
- Percentage difference

The resulting `business_result` table provides a concise summary of model calibration.

The key question is:

> **Does the frequency-severity model reproduce the observed aggregate claim cost of the unseen test portfolio reasonably well?**

---

# 17. Pure Premium by Age Category

The final analysis breaks the test-set results down by driver age category.

For each age category, the project calculates:

- Exposure
- Actual loss
- Predicted loss
- Actual pure premium
- Predicted pure premium
- Percentage difference

A final comparison chart displays:

**Actual vs Predicted Pure Premium by Age**

This provides a business-oriented view of model calibration across a key rating factor.

---

# Model Architecture

The final modelling structure can be summarised as:

```text
                         MOTOR INSURANCE DATA
                                  |
                                  v
                           DATA AUDIT
                                  |
                                  v
                                EDA
                                  |
                                  v
                         TRAIN / TEST SPLIT
                           /              \
                          /                \
                         v                  v
                FREQUENCY MODELING     SEVERITY DATA
                         |                  |
                  Poisson Model            |
                         |                  |
                  Dispersion Check          |
                         |                  v
                         v             Gamma Model
               Negative Binomial            |
                         |              Lognormal Model
                         |                  |
                         v                  v
                  Frequency Test      Severity Test
                    Validation          Validation
                         \                  /
                          \                /
                           v              v
                         FREQUENCY × SEVERITY
                                  |
                                  v
                         EXPECTED CLAIM COST
                                  |
                                  v
                            PURE PREMIUM
                                  |
                                  v
                       BUSINESS VALIDATION
```

---

# Key Actuarial Concepts Demonstrated

This project demonstrates practical application of:

- Insurance data auditing
- Exposure-based claim frequency
- Claim severity modelling
- Pure premium calculation
- Frequency-severity decomposition
- Generalized Linear Models
- Poisson regression
- Negative Binomial regression
- Overdispersion diagnostics
- Gamma regression
- Lognormal regression
- Exposure offsets
- Model comparison using AIC
- Residual diagnostics
- Train/test validation
- Model calibration
- Segment-level validation
- Expected loss modelling
- Portfolio-level pricing validation

---

# R Packages Used

The project uses:

```r
library(insuranceData)
library(dplyr)
library(ggplot2)
library(MASS)
```

`tidyr` functionality is accessed through `tidyr::pivot_longer()`.

---

# Repository Structure

A simple GitHub repository structure can be:

```text
motor-insurance-claim-pricing-r/
│
├── datacars_clean.R
├── README.md
└── LICENSE
```

If you later add outputs:

```text
motor-insurance-claim-pricing-r/
│
├── data/
├── scripts/
│   └── datacars_clean.R
├── outputs/
│   ├── figures/
│   └── tables/
├── README.md
└── LICENSE
```

---

# How to Run

Install the required packages if they are not already installed:

```r
install.packages(c(
  "insuranceData",
  "dplyr",
  "ggplot2",
  "MASS",
  "tidyr"
))
```

Then run:

```r
source("datacars_clean.R")
```

The script performs the complete analysis from data loading through final business validation.

---

# Reproducibility

The train/test split uses:

```r
set.seed(123)
```

This ensures that the same random train/test split can be reproduced when the script is rerun.

---

# Final Takeaway

This project demonstrates a complete **non-life insurance pricing workflow in R**, moving from raw policy-level data to an interpretable frequency-severity pricing model.

Rather than evaluating models only on statistical fit, the project also validates whether the final model can reproduce actual claim costs and pure premium on unseen data.

The final output therefore connects:

**Statistical Modelling → Actuarial Pricing → Portfolio Validation → Business Interpretation**

This makes the project suitable as a portfolio demonstration of practical actuarial data science and non-life insurance pricing.
