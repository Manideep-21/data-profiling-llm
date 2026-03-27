# Data Profiling and Cleaning Report

- Score before cleaning: 44
- Score after cleaning: 96
- Score improvement: 44
- Remaining issues after validation: 5

## Profile Before Cleaning

- Rows: 8478
- Columns: 6
- Duplicate rows: 0
- Total missing values: 3434
- Max missing values in a row: 3
- Average missing values per row: 0.405
- Constant columns: None
- Near-zero variance columns: None
- Suggested correlated feature drops: None

### ID
- Type: integer
- Inferred kind: numeric
- Missing: 0 (0.00%)
- Unique values: 8067
- Uniqueness ratio: 0.952
- Missing drop threshold exceeded: No
- Mean: 4038.643
- Median: 4022.5
- Min / Max: 1 / 8478
- Q1 / Q3: 1789.25 / 6233.75
- P05 / P95: 237 / 8026.15
- SD / Variance: 2536.209 / 6432357.196
- Outliers: 0
- Zero / Negative values: 0 / 0
- Constant / Near-zero variance: FALSE / FALSE

### Age
- Type: character
- Inferred kind: numeric
- Missing: 516 (6.09%)
- Unique values: 151
- Uniqueness ratio: 0.019
- Missing drop threshold exceeded: No
- Mean: 48.212
- Median: 42
- Min / Max: 18 / 200
- Q1 / Q3: 30 / 55
- P05 / P95: 20 / 124
- SD / Variance: 31.453 / 989.307
- Outliers: 507
- Zero / Negative values: 0 / 0
- Constant / Near-zero variance: FALSE / FALSE

### Salary
- Type: character
- Inferred kind: categorical
- Missing: 484 (5.71%)
- Unique values: 6640
- Uniqueness ratio: 0.831
- Missing drop threshold exceeded: No
- Mode: $60000
- Mode frequency: 408
- Dominance ratio: 0.051
- Rare categories: 6500
- Entropy: 11.609
- Avg / Min / Max length: 5.355 / 3 / 7
- Whitespace-only values: 0
- Top values: $60000:408, 50000 :406, abc:405, 87074:3, 101513:2

### JoinDate
- Type: character
- Inferred kind: date_like
- Missing: 431 (5.08%)
- Unique values: 2984
- Uniqueness ratio: 0.371
- Missing drop threshold exceeded: No
- Valid dates: 6785
- Invalid dates: 1262
- Min date / Max date: 2015-01-01 / 2024-12-31
- Date span (days): 3652

### Department
- Type: character
- Inferred kind: categorical
- Missing: 1117 (13.18%)
- Unique values: 13
- Uniqueness ratio: 0.002
- Missing drop threshold exceeded: No
- Mode: Engg
- Mode frequency: 598
- Dominance ratio: 0.081
- Rare categories: 0
- Entropy: 3.7
- Avg / Min / Max length: 7.822 / 2 / 25
- Whitespace-only values: 0
- Top values: Engg:598, Support!!:588, HR:578, sales:572, human resources:571

### Score
- Type: numeric
- Inferred kind: numeric
- Missing: 886 (10.45%)
- Unique values: 200
- Uniqueness ratio: 0.026
- Missing drop threshold exceeded: No
- Mean: 79.844
- Median: 77
- Min / Max: -10 / 300
- Q1 / Q3: 62 / 89
- P05 / P95: -10 / 163
- SD / Variance: 44.289 / 1961.491
- Outliers: 825
- Zero / Negative values: 0 / 399
- Constant / Near-zero variance: FALSE / FALSE

## Issues Detected

- Column Age: Missing values 6.09%
- Column Age: Stored as text with non-numeric values present
- Column Age: Outliers detected (507 values)
- Column Age: Invalid range values found
- Column Salary: Missing values 5.71%
- Column Salary: High cardinality detected
- Column JoinDate: Missing values 5.08%
- Column JoinDate: Stored as string but looks like date
- Column Department: Missing values 13.18%
- Column Score: Missing values 10.45%
- Column Score: Outliers detected (825 values)
- Column Score: Invalid range values found

## Correlation Analysis

No highly correlated feature pairs detected above the configured threshold.

![Correlation Heatmap](correlation_heatmap.png)

## Visualizations

### Score Comparison

![Score Comparison](visualizations/score_comparison.png)

### Missing Values

![Missing Values](visualizations/missing_values.png)

### Issue Summary

![Issue Summary](visualizations/issue_summary.png)

### Data Types

![Data Types](visualizations/data_types.png)

### Numeric Distributions

![ID_distribution](visualizations/ID_distribution.png)
![Score_distribution](visualizations/Score_distribution.png)

### Box Plots

![ID_boxplot](visualizations/ID_boxplot.png)
![Score_boxplot](visualizations/Score_boxplot.png)

### Category Bars

![Age_bar](visualizations/Age_bar.png)
![Salary_bar](visualizations/Salary_bar.png)
![JoinDate_bar](visualizations/JoinDate_bar.png)
![Department_bar](visualizations/Department_bar.png)

## LLM Suggestions

### Issue 1: Column Age: Missing values 6.09%
- Explanation: Column Age has 6.09% missing values.
- Fix options: Fill with median; Fill with mean; Fill with constant; Add missing indicator; Remove affected rows
- Recommended: Fill with median
- Reason: Median imputation is robust to outliers and preserves the dataset size, which is important given the presence of outliers in the 'Age' column. This should be performed after type conversion and range validation.

### Issue 2: Column Age: Stored as text with non-numeric values present
- Explanation: Column Age is stored as text with non-numeric values.
- Fix options: Convert to numeric; Remove invalid rows
- Recommended: Convert to numeric
- Reason: This is a high-severity foundational issue. Converting 'Age' to a numeric type is essential for performing any numerical analysis, range validation, or imputation.

### Issue 3: Column Age: Outliers detected (507 values)
- Explanation: Column Age has 507 detected outliers.
- Fix options: Cap outliers to IQR bounds; Winsorize extreme values; Robust scale using median and IQR; Remove outlier rows
- Recommended: Cap outliers to IQR bounds
- Reason: Capping outliers helps to reduce the influence of extreme values on statistical models without removing data, which is generally preferred for numerical columns like 'Age'.

### Issue 4: Column Age: Invalid range values found
- Explanation: Column Age contains values outside a valid range.
- Fix options: Replace invalid values with NA; Replace invalid values with median; Clip values to valid range; Remove invalid rows
- Recommended: Clip values to valid range
- Reason: This high-severity issue needs direct correction. Clipping values to a valid range is an effective way to correct out-of-range entries while retaining the data points, assuming the values are close to the valid boundaries.

### Issue 5: Column Salary: Missing values 5.71%
- Explanation: Column Salary has 5.71% missing values.
- Fix options: Fill with mode; Fill with constant; Add missing indicator; Remove affected rows
- Recommended: Add missing indicator
- Reason: Adding a missing indicator column allows models to potentially learn from the pattern of missingness itself, without altering the distribution of the existing 'Salary' data.

### Issue 6: Column Salary: High cardinality detected
- Explanation: Column Salary has high cardinality.
- Fix options: Group rare categories; Merge categories manually; Lowercase categories; Label encode categories; One-hot encode categories; Keep as-is
- Recommended: Keep as-is
- Reason: Salary is typically a continuous numerical variable, and high cardinality (many unique values) is expected and not an issue in this context. No action is required.

### Issue 7: Column JoinDate: Missing values 5.08%
- Explanation: Column JoinDate has 5.08% missing values.
- Fix options: Fill with mode; Fill with constant; Add missing indicator; Remove affected rows
- Recommended: Fill with mode
- Reason: Filling missing date values with the mode (most frequent date) is a reasonable imputation strategy for date columns, especially when the missingness percentage is moderate.

### Issue 8: Column JoinDate: Stored as string but looks like date
- Explanation: Column JoinDate is stored as a string but looks like a date.
- Fix options: Convert to Date; Convert to factor; Remove invalid rows
- Recommended: Convert to Date
- Reason: Converting the string representation to a proper date type is crucial for enabling date-specific operations, calculations, and time-series analysis.

### Issue 9: Column Department: Missing values 13.18%
- Explanation: Column Department has 13.18% missing values.
- Fix options: Fill with mode; Fill with constant; Add missing indicator; Remove affected rows
- Recommended: Fill with mode
- Reason: For categorical columns, filling missing values with the mode (most frequent category) is a standard and effective imputation technique.

### Issue 10: Column Score: Missing values 10.45%
- Explanation: Column Score has 10.45% missing values.
- Fix options: Fill with median; Fill with mean; Fill with constant; Add missing indicator; Remove affected rows
- Recommended: Fill with median
- Reason: Median imputation is robust to outliers and preserves the dataset size, which is important given the presence of outliers in the 'Score' column. This should be performed after range validation.

### Issue 11: Column Score: Outliers detected (825 values)
- Explanation: Column Score has 825 detected outliers.
- Fix options: Cap outliers to IQR bounds; Winsorize extreme values; Robust scale using median and IQR; Remove outlier rows
- Recommended: Cap outliers to IQR bounds
- Reason: Capping outliers helps to reduce the influence of extreme values on statistical models without removing data, which is generally preferred for numerical columns like 'Score'.

### Issue 12: Column Score: Invalid range values found
- Explanation: Column Score contains values outside a valid range.
- Fix options: Replace invalid values with NA; Replace invalid values with median; Clip values to valid range; Remove invalid rows
- Recommended: Clip values to valid range
- Reason: This high-severity issue needs direct correction. Clipping values to a valid range is an effective way to correct out-of-range entries while retaining the data points, assuming the values are close to the valid boundaries.

## Fixes Applied

- Issue 1 on `Age`: `fill_missing_median`
- Issue 2 on `Age`: `convert_to_numeric`
- Issue 3 on `Age`: `cap_outliers`
- Issue 4 on `Age`: `clip_to_range`
- Issue 5 on `Salary`: `add_missing_indicator`
- Issue 6 on `Salary`: `no_change`
- Issue 7 on `JoinDate`: `fill_missing_mode`
- Issue 8 on `JoinDate`: `convert_to_date`
- Issue 9 on `Department`: `fill_missing_mode`
- Issue 10 on `Score`: `fill_missing_median`
- Issue 11 on `Score`: `cap_outliers`
- Issue 12 on `Score`: `clip_to_range`

## Profile After Cleaning

- Rows: 8478
- Columns: 7
- Duplicate rows: 0
- Total missing values: 2177
- Max missing values in a row: 2
- Average missing values per row: 0.257
- Constant columns: None
- Near-zero variance columns: Salary_missing_flag
- Suggested correlated feature drops: None

### ID
- Type: integer
- Inferred kind: numeric
- Missing: 0 (0.00%)
- Unique values: 8067
- Uniqueness ratio: 0.952
- Missing drop threshold exceeded: No
- Mean: 4038.643
- Median: 4022.5
- Min / Max: 1 / 8478
- Q1 / Q3: 1789.25 / 6233.75
- P05 / P95: 237 / 8026.15
- SD / Variance: 2536.209 / 6432357.196
- Outliers: 0
- Zero / Negative values: 0 / 0
- Constant / Near-zero variance: FALSE / FALSE

### Age
- Type: numeric
- Inferred kind: numeric
- Missing: 0 (0.00%)
- Unique values: 49
- Uniqueness ratio: 0.006
- Missing drop threshold exceeded: No
- Mean: 43.729
- Median: 42
- Min / Max: 18 / 87.5
- Q1 / Q3: 30 / 53
- P05 / P95: 21 / 87.5
- SD / Variance: 16.534 / 273.386
- Outliers: 0
- Zero / Negative values: 0 / 0
- Constant / Near-zero variance: FALSE / FALSE

### Salary
- Type: character
- Inferred kind: categorical
- Missing: 484 (5.71%)
- Unique values: 6640
- Uniqueness ratio: 0.831
- Missing drop threshold exceeded: No
- Mode: $60000
- Mode frequency: 408
- Dominance ratio: 0.051
- Rare categories: 6500
- Entropy: 11.609
- Avg / Min / Max length: 5.355 / 3 / 7
- Whitespace-only values: 0
- Top values: $60000:408, 50000 :406, abc:405, 87074:3, 101513:2

### JoinDate
- Type: Date
- Inferred kind: date
- Missing: 1693 (19.97%)
- Unique values: 2980
- Uniqueness ratio: 0.439
- Missing drop threshold exceeded: No
- Valid dates: 6785
- Invalid dates: 0
- Min date / Max date: 2015-01-01 / 2024-12-31
- Date span (days): 3652

### Department
- Type: character
- Inferred kind: categorical
- Missing: 0 (0.00%)
- Unique values: 13
- Uniqueness ratio: 0.002
- Missing drop threshold exceeded: No
- Mode: Engg
- Mode frequency: 1715
- Dominance ratio: 0.202
- Rare categories: 0
- Entropy: 3.586
- Avg / Min / Max length: 7.318 / 2 / 25
- Whitespace-only values: 0
- Top values: Engg:1715, Support!!:588, HR:578, sales:572, human resources:571

### Score
- Type: numeric
- Inferred kind: numeric
- Missing: 0 (0.00%)
- Unique values: 52
- Uniqueness ratio: 0.006
- Missing drop threshold exceeded: No
- Mean: 74.996
- Median: 77
- Min / Max: 29.5 / 100
- Q1 / Q3: 64 / 87
- P05 / P95: 50 / 100
- SD / Variance: 17.2 / 295.853
- Outliers: 0
- Zero / Negative values: 0 / 0
- Constant / Near-zero variance: FALSE / FALSE

### Salary_missing_flag
- Type: integer
- Inferred kind: numeric
- Missing: 0 (0.00%)
- Unique values: 2
- Uniqueness ratio: 0
- Missing drop threshold exceeded: No
- Mean: 0.057
- Median: 0
- Min / Max: 0 / 1
- Q1 / Q3: 0 / 0
- P05 / P95: 0 / 1
- SD / Variance: 0.232 / 0.054
- Outliers: 484
- Zero / Negative values: 7994 / 0
- Constant / Near-zero variance: FALSE / TRUE

