# 🚗 DataCar Insurance Pricing Analysis

## Frequency–Severity Modelling with GLMs and Train/Test Validation

This project develops an end-to-end **motor insurance pricing framework** using the `dataCar` dataset from the `insuranceData` R package.

The analysis follows the actuarial **frequency–severity approach**:

> **Expected Loss Cost = Expected Claim Frequency × Expected Claim Severity**

The final workflow moves from data validation and exploratory analysis to Poisson/Negative Binomial frequency modelling, Gamma/Lognormal severity modelling, diagnostic checks, test-set validation, calibration, and final pure-premium estimation.

---

## 📌 Executive Summary

The analysis was performed on **67,856 motor insurance policy records** containing exposure, claim counts, claim costs, driver characteristics, vehicle characteristics and geographic area.

### Key results

| Metric | Result |
|---|---:|
| Policies | 67,856 |
| Total claim count | 4,937 |
| Overall claim frequency | 0.1552 claims / exposure |
| Overall claim severity | $1,886.69 |
| Overall pure premium | **$292.90** |
| Training observations | 54,284 |
| Test observations | 13,572 |
| Test actual frequency | 0.1478 |
| Test predicted frequency | 0.1573 |
| Frequency difference | +6.41% |
| Test actual pure premium | **$294.17** |
| Test predicted pure premium | **$293.93** |
| Pure-premium difference | **-$0.24 (-0.08%)** |

The final pricing model therefore produces an extremely close **portfolio-level pure-premium estimate on the unseen test set**, although frequency calibration is somewhat less precise than the final loss-cost calibration.

---

# 1. Business Objective

The objective is to estimate the expected loss cost of an insurance policy using observable risk characteristics.

Instead of directly modelling total claim cost, the project separates the problem into two components:

### Frequency

How often is a policy expected to generate claims?

$$
E[N_i] = \text{Expected claim frequency}
$$

### Severity

How expensive is an expected claim?

$$
E[S_i] = \text{Expected claim severity}
$$

### Pure Premium

The expected loss cost is then:

$$
\boxed{\text{Pure Premium}_i =
E[N_i] \times E[S_i]}
$$

The model uses exposure as the denominator for frequency and as the basis for the final expected loss-cost calculation.

---

# 2. Dataset

The project uses the `dataCar` dataset supplied by the `insuranceData` R package.

The original dataset contains **67,856 observations and 11 variables**.

| Variable | Description / role |
|---|---|
| `veh_value` | Vehicle value |
| `exposure` | Policy exposure |
| `clm` | Claim indicator |
| `numclaims` | Number of claims |
| `claimcst0` | Total claim cost |
| `veh_body` | Vehicle body type |
| `veh_age` | Vehicle age category |
| `gender` | Driver gender |
| `area` | Geographic area |
| `agecat` | Driver age category |
| `X_OBSTAT_` | Dataset metadata/status field |

Categorical variables `agecat` and `veh_age` were converted to factors before modelling.

---

# 3. Data Audit and Quality Checks

The initial audit focused on missing values, duplicates, claim consistency and variable types.

### Findings

- **No missing values** were found across the variables.
- **378 duplicate rows** were identified.
- The duplicates were retained because the analysis did not establish sufficient evidence that they represented erroneous records.
- There were **4,624 policies with positive claim costs / positive claim activity**.
- No policy had `numclaims > 0` while `clm = 0`.
- Claim cost and claim count were fully consistent:
  - zero claims corresponded to zero claim cost;
  - positive claim counts corresponded to positive claim costs.

The claim-count distribution was:

| Number of claims | Policies |
|---:|---:|
| 0 | 63,232 |
| 1 | 4,333 |
| 2 | 271 |
| 3 | 18 |
| 4 | 2 |

This strong concentration at zero is typical of insurance claim-frequency data and motivates count-data modelling rather than ordinary regression.

---

# 4. Portfolio-Level Baseline

Before fitting GLMs, the overall portfolio metrics were calculated.

### Overall frequency

$$
\frac{\sum \text{Claims}}{\sum \text{Exposure}}
= 0.15525
$$

### Overall severity

$$
\frac{\sum \text{Claim Cost}}
{\sum \text{Claims}}
= \$1,886.69
$$

### Overall pure premium

$$
0.15525 \times 1,886.69
= \boxed{\$292.90}
$$

This provides an important benchmark against which the final model can be evaluated.

---

# 5. Exploratory Data Analysis

## 5.1 Driver Age

Driver age showed a clear relationship with insurance risk.

| Age category | Frequency | Severity | Pure premium |
|---:|---:|---:|---:|
| 1 | 0.201 | $2,490 | **$500** |
| 2 | 0.170 | $1,985 | $337 |
| 3 | 0.160 | $1,793 | $288 |
| 4 | 0.156 | $1,810 | $282 |
| 5 | 0.125 | $1,638 | $205 |
| 6 | 0.126 | $1,753 | $221 |

### Insight

The youngest driver category has the highest observed frequency, severity and pure premium.

Pure premium falls substantially across the age categories, with category 5 producing the lowest observed pure premium.

This relationship becomes one of the strongest signals in the frequency model.

![Claim frequency by age](plots/09_claim_frequency_by_age.png)

![Claim severity by age](plots/08_claim_severity_by_age.png)

![Pure premium by age](plots/07_pure_premium_by_age.png)

---

## 5.2 Geographic Area

| Area | Frequency | Severity | Pure premium |
|---|---:|---:|---:|
| A | 0.155 | $1,754 | $273 |
| B | 0.162 | $1,758 | $285 |
| C | 0.156 | $1,919 | $299 |
| D | 0.137 | $1,739 | $239 |
| E | 0.149 | $2,104 | $313 |
| F | 0.176 | $2,629 | **$462** |

### Insight

Area F stands out as the highest-risk geographic segment because it combines relatively high frequency with substantially higher severity.

Area D has the lowest observed frequency and pure premium.

![Claim frequency by age and area](plots/02_claim_frequency_by_age_area.png)

---

## 5.3 Gender

| Gender | Frequency | Severity | Pure premium |
|---|---:|---:|---:|
| F | 0.158 | $1,733 | $273 |
| M | 0.152 | $2,093 | **$318** |

### Insight

The two groups have similar observed frequencies, but the male group has materially higher severity, producing a higher observed pure premium.

![Pure premium by age and gender](plots/01_pure_premium_by_age_gender.png)

![Claim frequency by age and gender](plots/03_claim_frequency_by_age_gender.png)

---

## 5.4 Vehicle Body

Vehicle body type produces substantial variation in observed risk.

| Vehicle body | Frequency | Severity | Pure premium |
|---|---:|---:|---:|
| BUS | 0.387 | $1,336 | $517 |
| CONVT | 0.092 | $2,296 | $211 |
| COUPE | 0.235 | $2,503 | $588 |
| HBACK | 0.151 | $1,947 | $294 |
| HDTOP | 0.174 | $2,168 | $376 |
| MCARA | 0.253 | $712 | $180 |
| MIBUS | 0.142 | $2,580 | $366 |
| PANVN | 0.166 | $1,958 | $325 |
| RDSTR | 0.257 | $456 | $117 |
| SEDAN | 0.153 | $1,678 | $257 |
| STNWG | 0.163 | $1,894 | $309 |
| TRUCK | 0.154 | $2,458 | $379 |
| UTE | 0.131 | $2,164 | $284 |

Some vehicle-body categories have relatively low exposure, so their raw experience should be interpreted cautiously.

---

## 5.5 Vehicle Age

| Vehicle age | Frequency | Severity | Pure premium |
|---:|---:|---:|---:|
| 1 | 0.164 | $1,775 | $291 |
| 2 | 0.171 | $1,836 | $314 |
| 3 | 0.152 | $1,880 | $285 |
| 4 | 0.140 | $2,026 | $284 |

The relationship is less pronounced than driver age, but vehicle age still contributes information to the multivariate models.

---

## 5.6 Vehicle Value

Vehicle value was also examined using bands:

| Vehicle value band | Frequency | Severity | Pure premium |
|---|---:|---:|---:|
| [0, 0.5) | 0.115 | $1,475 | $169 |
| [0.5, 1) | 0.140 | $2,148 | $301 |
| [1, 1.5) | 0.153 | $1,854 | $284 |
| [1.5, 2) | 0.158 | $1,874 | $294 |
| [2, 3) | 0.170 | $1,835 | $312 |
| [3, 5) | 0.180 | $1,834 | **$330** |
| [5, Inf) | 0.165 | $2,020 | $334 |

The analysis suggests that higher-value vehicles generally exhibit higher observed claim frequency and pure premium, although the relationship is not perfectly monotonic.

![Pure premium by vehicle value](plots/17_pure_premium_by_vehicle_value.png)

---

# 6. Severity Distribution

The positive-claim dataset contains **4,624 claim-active observations**.

The claim severity distribution is strongly right-skewed:

| Statistic | Claim severity |
|---|---:|
| Minimum | $200 |
| 1st quartile | $353.80 |
| Median | $712.60 |
| Mean | $1,916.20 |
| 3rd quartile | $1,952.00 |
| Maximum | $55,922.10 |

The large difference between median and mean demonstrates the influence of high-cost claims.

The logarithmic transformation produces a substantially more manageable distribution for modelling.

![Claim severity distribution](plots/14_claim_severity_distribution_policy_level.png)

![Log claim severity](plots/13_log_claim_severity_policy.png)

![Claim-level severity distribution](plots/06_claim_severity_distribution_claim_level.png)

![Log claim-level severity](plots/15_log_claim_severity_distribution_claim_level.png)

---

# 7. Train/Test Design

A reproducible **80/20 random train/test split** was used with:

```r
set.seed(123)
```

| Dataset | Policies |
|---|---:|
| Training | 54,284 |
| Test | 13,572 |

The training set contained 3,999 claims, while the test set contained 938 claims.

Exposure was explicitly retained in the frequency modelling process rather than treating every policy as having equal observation time.

---

# 8. Frequency Modelling

Two count-data GLMs were compared.

## 8.1 Poisson GLM

The Poisson model was specified as:

```r
numclaims ~ agecat + veh_age + gender + area + veh_body +
  offset(log(exposure))
```

The exposure offset allows the model to estimate claim frequency rather than simply modelling raw claim counts.

### Poisson diagnostics

| Diagnostic | Value |
|---|---:|
| Deviance dispersion | 0.378 |
| Pearson dispersion | 1.473 |
| AIC | 28,172.40 |

The Pearson dispersion is above 1, indicating residual overdispersion relative to the Poisson assumption.

---

## 8.2 Negative Binomial GLM

A Negative Binomial model was therefore fitted:

```r
MASS::glm.nb(
  numclaims ~ agecat + veh_age + gender + area + veh_body +
    offset(log(exposure)),
  data = train
)
```

### Negative Binomial results

| Metric | Value |
|---|---:|
| Theta | 2.097 |
| AIC | **28,137.01** |
| Deviance dispersion | 0.347 |
| Pearson dispersion | **1.434** |

The Negative Binomial model improves AIC relative to the Poisson model:

$$
28,137.01 < 28,172.40
$$

and slightly reduces the Pearson dispersion.

### Model selection

**Negative Binomial was selected as the frequency model.**

![Frequency residual diagnostics](plots/12_nb_frequency_residual_diagnostics.png)

---

# 9. Frequency Model Interpretation

Several effects remain particularly important after controlling for the other rating variables.

Using age category 1 as the reference:

| Age category | Frequency multiplicative effect |
|---|---:|
| 2 | 0.857 |
| 3 | 0.771 |
| 4 | 0.784 |
| 5 | 0.621 |
| 6 | 0.618 |

The model therefore estimates materially lower claim frequency for older driver categories relative to category 1.

Vehicle age category 4 also has a multiplicative frequency effect below 1.

Several vehicle-body categories have substantially lower fitted frequency than the reference vehicle-body category.

The age effects are particularly consistent with the univariate EDA.

---

# 10. Frequency Validation

The Negative Binomial model was evaluated on the **unseen test dataset**.

| Metric | Test result |
|---|---:|
| Actual frequency | 0.1478 |
| Predicted frequency | 0.1573 |
| Difference | +0.0095 |
| Difference (%) | **+6.41%** |

The model therefore slightly **overpredicts claim frequency** at the aggregate test-portfolio level.

This is important: a frequency model can have imperfect calibration while the combined frequency × severity model still produce a highly accurate expected loss cost.

---

# 11. Frequency Calibration by Driver Age

The test set was also calibrated by age category.

| Age category | Exposure | Observed claims |
|---:|---:|---:|
| 1 | 539 | 106 |
| 2 | 1,167 | 171 |
| 3 | 1,515 | 256 |
| 4 | 1,484 | 203 |
| 5 | 1,023 | 121 |
| 6 | 618 | 81 |

The full calibration calculation compares observed and predicted frequency within each age category rather than relying only on the aggregate frequency.

---

# 12. Severity Modelling

Severity was defined at the policy level as:

$$
\text{Severity}
=
\frac{\text{Total Claim Cost}}
{\text{Number of Claims}}
$$

Only policies with positive claim counts were included in the severity dataset.

Two severity models were compared.

---

## 12.1 Gamma GLM

The Gamma model used a log link:

```r
severity ~ agecat + veh_age + gender + area + veh_body
```

with claim count used as the modelling weight:

```r
weights = numclaims
```

This makes the model appropriate for positive, right-skewed claim severity.

---

## 12.2 Lognormal GLM

A second model was fitted to:

```r
log(severity)
```

again using claim count as the weight.

### AIC comparison

| Model | AIC |
|---|---:|
| Gamma | 68,054.67 |
| Lognormal | **11,733.06** |

The Lognormal model has a dramatically lower AIC.

However, model selection was not based on AIC alone. Aggregate out-of-sample calibration was also examined.

---

# 13. Severity Validation

On the test severity dataset:

| Model | Predicted severity |
|---|---:|
| Actual | **$1,990.28** |
| Gamma | **$1,882.34** |
| Lognormal | $1,775.66 |

Absolute aggregate errors:

- Gamma: approximately **$107.94**
- Lognormal: approximately **$214.62**

Although the Lognormal model has a much lower AIC, the Gamma model is materially closer to the observed test-set severity.

### Final severity choice

The **Gamma model was retained for the final frequency–severity pricing calculation** because its aggregate out-of-sample severity calibration was better.

This illustrates an important modelling principle:

> **In pricing, in-sample fit criteria should be considered alongside out-of-sample predictive calibration and business relevance.**

![Gamma severity diagnostics](plots/11_gamma_severity_diagnostics.png)

---

# 14. Severity Calibration by Age

Observed versus predicted severity was examined by driver age category.

| Age category | Claims | Observed severity | Gamma prediction |
|---:|---:|---:|---:|
| 1 | 106 | $3,008 | $2,374 |
| 2 | 171 | $2,261 | $1,959 |
| 3 | 256 | $1,808 | $1,814 |
| 4 | 203 | $1,699 | $1,839 |
| 5 | 121 | $1,616 | $1,668 |
| 6 | 81 | $1,953 | $1,721 |

The largest calibration challenge is concentrated in age category 1, where observed severity is considerably above the Gamma prediction.

For middle and older age categories, the Gamma model tracks observed severity more closely.

---

# 15. Final Frequency–Severity Pricing Model

The final model combines:

### Frequency

**Negative Binomial GLM**

$$
\hat{f}_i =
\text{NB}\left(
agecat_i, veh\_age_i, gender_i,
area_i, veh\_body_i, exposure_i
\right)
$$

### Severity

**Gamma GLM with log link**

$$
\hat{s}_i =
\text{Gamma}\left(
agecat_i, veh\_age_i, gender_i,
area_i, veh\_body_i
\right)
$$

### Expected loss

$$
\widehat{Loss}_i =
\hat{f}_i \times \hat{s}_i
$$

### Pure premium

The portfolio-level pure premium is:

$$
\widehat{PP}
=
\frac{\sum_i \widehat{Loss}_i}
{\sum_i Exposure_i}
$$

---

# 16. Final Business Validation

The most important result is the aggregate test-set comparison.

| Metric | Value |
|---|---:|
| Actual pure premium | **$294.17** |
| Predicted pure premium | **$293.93** |
| Difference | **-$0.24** |
| Difference (%) | **-0.08%** |

The model therefore underestimates the actual test-set pure premium by only approximately **0.08%**.

This is a very strong aggregate calibration result.

![Actual vs predicted pure premium](plots/10_actual_vs_predicted_pure_premium_by_age.png)

---

# 17. Pure Premium Calibration by Age

The final model was also evaluated within each driver age category.

| Age category | Actual pure premium | Predicted pure premium |
|---:|---:|---:|
| 1 | $592 | $479 |
| 2 | $331 | $340 |
| 3 | $305 | $285 |
| 4 | $232 | $294 |
| 5 | $191 | $208 |
| 6 | $256 | $210 |

### Interpretation

The model captures the broad shape of risk across age categories, but calibration is not uniform.

- **Age 1:** materially underpredicted.
- **Age 2:** very close.
- **Age 3:** moderately underpredicted.
- **Age 4:** moderately overpredicted.
- **Age 5:** moderately overpredicted.
- **Age 6:** underpredicted.

This is an important pricing insight: **excellent portfolio-level calibration does not automatically imply perfect segment-level calibration.**

---

# 18. Key Business Insights

## 1. Driver age is a major rating variable

The youngest driver category has the highest observed pure premium and the frequency model assigns substantially higher expected claim frequency to it.

## 2. Geographic area matters

Area F has a notably higher observed pure premium, driven by both frequency and especially severity.

## 3. Vehicle body type produces substantial heterogeneity

Several body types exhibit very different claim frequencies and severities, suggesting meaningful segmentation potential.

## 4. Vehicle value is associated with higher risk

Higher-value vehicle bands generally show increasing observed frequency and pure premium, although the relationship is not perfectly monotonic.

## 5. Frequency requires an overdispersion-aware model

The Poisson model showed Pearson dispersion above 1. The Negative Binomial model reduced this issue and achieved a lower AIC.

## 6. AIC alone should not determine the final severity model

The Lognormal model had a dramatically lower AIC, but the Gamma model was substantially closer to actual test-set severity.

## 7. Aggregate pricing calibration is excellent

The final model predicts test-set pure premium within **0.08%** of actual experience.

## 8. Segment calibration still needs improvement

The age-level results show meaningful under- and overprediction in individual segments despite excellent aggregate calibration.

---

# 19. Modelling Workflow

```text
Raw Data
   │
   ▼
Data Audit & Consistency Checks
   │
   ▼
Univariate EDA
   │
   ▼
Multivariate EDA
   │
   ▼
Portfolio Frequency / Severity / Pure Premium
   │
   ▼
80/20 Train-Test Split
   │
   ├───────────────────────┐
   ▼                       ▼
Frequency Model         Severity Model
   │                       │
   ▼                       ▼
Poisson GLM             Gamma GLM
   │                       │
   ▼                       ├── Lognormal GLM
Overdispersion              │
Diagnostics                 ▼
   │                    AIC + Test
   ▼                    Calibration
Negative Binomial             │
GLM                           ▼
   │                    Gamma selected
   └──────────────┬───────────┘
                  ▼
        Frequency × Severity
                  │
                  ▼
          Expected Claim Cost
                  │
                  ▼
             Pure Premium
                  │
                  ▼
        Test-Set Validation
                  │
                  ▼
       Segment-Level Calibration
```

---

# 20. Project Structure

A recommended GitHub repository structure is:

```text
data-car-insurance-pricing/
│
├── README.md
├── datacars_clean.R
│
├── plots/
│   ├── 01_pure_premium_by_age_gender.png
│   ├── 02_claim_frequency_by_age_area.png
│   ├── 03_claim_frequency_by_age_gender.png
│   ├── 04_vehicle_value_distribution.png
│   ├── 05_log_claim_severity_policy.png
│   ├── 06_claim_severity_distribution_claim_level.png
│   ├── 07_pure_premium_by_age.png
│   ├── 08_claim_severity_by_age.png
│   ├── 09_claim_frequency_by_age.png
│   ├── 10_actual_vs_predicted_pure_premium_by_age.png
│   ├── 11_gamma_severity_diagnostics.png
│   ├── 12_nb_frequency_residual_diagnostics.png
│   ├── 13_log_claim_severity_policy.png
│   ├── 14_claim_severity_distribution_policy_level.png
│   ├── 15_log_claim_severity_distribution_claim_level.png
│   ├── 16_claim_severity_distribution_duplicate_view.png
│   └── 17_pure_premium_by_vehicle_value.png
│
└── data/
    └── README.md
```

The raw `dataCar` dataset is provided through the `insuranceData` R package and therefore does not need to be uploaded as a separate proprietary data file.

---

# 21. Reproducibility

### R packages

```r
library(insuranceData)
library(dplyr)
library(ggplot2)
library(MASS)
```

### Reproducible train/test split

```r
set.seed(123)

train_index <- sample(
  seq_len(nrow(x)),
  size = 0.80 * nrow(x)
)

train <- x[train_index, ]
test  <- x[-train_index, ]
```

The complete modelling workflow is contained in:

```text
datacars_clean.R
```

---

# 22. Limitations and Next Steps

This project demonstrates a strong baseline actuarial pricing framework, but it should not be treated as a production-ready tariff without further validation.

### Recommended next steps

1. **Out-of-time validation**
   - Validate on a future policy period rather than only a random holdout.

2. **Credibility / exposure checks**
   - Investigate low-exposure vehicle-body segments before using raw relativities.

3. **Interaction effects**
   - Explore interactions such as:
     - age × gender
     - age × area
     - age × vehicle type
     - vehicle value × vehicle age

4. **Non-linear continuous effects**
   - Model `veh_value` using splines or controlled bands rather than relying only on categorical summaries.

5. **Alternative frequency models**
   - Compare Zero-Inflated, Hurdle or other count models if justified by the data-generating process.

6. **Severity distributions**
   - Investigate Tweedie, inverse Gaussian and other heavy-tailed alternatives.

7. **Outlier treatment**
   - Examine high-severity claims and assess whether winsorisation, capping or explicit large-loss modelling is appropriate.

8. **Pricing layer**
   - Convert pure premium into indicated premium by incorporating:
     - expenses
     - commission
     - profit/risk margin
     - reinsurance
     - catastrophe/large-loss loads

9. **Model governance**
   - Add stability testing, sensitivity analysis, monitoring thresholds and documentation for production use.

---

# 23. Final Takeaway

This project demonstrates the core logic behind **modern actuarial motor insurance pricing**:

$$
\boxed{
\text{Pricing Risk}
=
\text{Frequency Model}
\times
\text{Severity Model}
}
$$

The analysis progresses from raw policy data through statistical diagnostics and GLM selection to an interpretable, validated pure-premium estimate.

The strongest result is the final test-set calibration:

> **Actual pure premium: $294.17**  
> **Predicted pure premium: $293.93**  
> **Error: -0.08%**

At the same time, the segment-level results reveal where the model still needs refinement, particularly for the youngest driver category.

That combination—**portfolio calibration + segment diagnostics + actuarial interpretability**—is the main value of the project.

---

## 🛠️ Tools & Techniques

- **R**
- `insuranceData`
- `dplyr`
- `ggplot2`
- `MASS`
- Generalized Linear Models
- Poisson Regression
- Negative Binomial Regression
- Gamma Regression
- Lognormal Regression
- Exposure offsets
- Overdispersion diagnostics
- Residual diagnostics
- Train/Test validation
- Calibration analysis
- Frequency–Severity pricing
- Pure premium estimation

---

## 👤 Author

**Keshav Kalani**

Actuarial & Data Analytics Project

