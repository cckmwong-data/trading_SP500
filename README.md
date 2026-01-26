# Trading S&P 500 Using ARIMA–GARCH Model

This project applies **ARIMA–GARCH model** to daily S&P 500 returns to assess whether short-horizon forecasts can produce superior risk-adjusted performance relative to a passive Buy-and-Hold benchmark. The project demonstrates practical applications of time-series econometrics, financial forecasting, and strategy backtesting.

<img src="./images/returns.png" width="" height="500">

---

## Problem Statement

Financial time series frequently exhibit features such as autocorrelation, non-constant variance, and heavy tails. Traditional linear models fail to capture these dynamics, particularly during periods of market stress.

This project evaluates whether incorporating both conditional mean and conditional variance dynamics via ARIMA–GARCH can improve portfolio decision-making. Specifically, the analysis tests whether:

- Forecasted returns can inform directional positioning, and
- Volatility forecasts can enhance risk-adjusted performance metrics.
- The final decision (Buy/ Hold/ Sell) is a combination of ARIMA mean with GARCH variance.

The motivation extends to real-world financial analytics use cases, including:

- Short-horizon signal generation
- Risk management and volatility monitoring
- Strategy evaluation and benchmarking
- Algorithmic trading research workflows

---

## Data

- Instrument: **S&P 500 Index (GSPC)**
- Source: *Yahoo Finance* via `quantmod::getSymbols()`
- Frequency: Daily close prices
- Transformation: Prices → *Log returns* (e.g., diff(log(Ad(GSPC)))).
- Handling: Removal of initial NA returns
- Period: Full availability from Yahoo Finance

Daily log returns were selected because they:

- Convert multiplicative price changes into additive form
- are typically stationary (fundamental requirement for the statistical validity of ARIMA and GARCH models) whereas stock prices are not 

---

## Methods and Modeling Approach

### Time Series Modeling

The modeling pipeline consists of:

1. **ARIMA** for conditional mean forecasts  
2. **GARCH(1,1)** for conditional variance forecasts

ARIMA order selection is performed using **AIC minimization** via `auto.arima()`. A fixed GARCH(1,1) structure is then applied to capture volatility clustering in the ARIMA residuals.

### Trading Strategy Logic

Forecasts generate next-day trading signals based on:

- **Buy (Long)** if forecasted return > 0
- **Sell (Short)** if forecasted return < 0
- **Hold** if the model fails to converge

Signals are executed on the next trading day. No leverage, transaction costs, or shorting constraints are included in the baseline implementation, to isolate model behavior and risk-adjusted return characteristics.

---

## Evaluation Metric

Performance is compared against a passive **Buy-and-Hold** benchmark using **Annualized Sharpe Ratio**:

Sharpe = (mean(daily returns) × 252) / (sd(daily returns) × √252)


Sharpe ratio is chosen because it adjusts for volatility and is a standard performance metric in quantitative finance.

---

## Results Summary

The ARIMA–GARCH strategy posted a **Sharpe ratio above 1** during the COVID-19 pandemic period, indicating strong risk-adjusted performance. In contrast, the Buy-and-Hold benchmark exhibited a **negative Sharpe ratio**, implying that its return over the same window was below the risk-free rate on a volatility-adjusted basis.

### Reason for Sharpe Divergence

This divergence arises because:

1. **Buy-and-Hold absorbed crisis drawdowns**  
   The early 2020 pandemic sell-off produced substantial negative returns, depressing the benchmark’s mean.

2. **Volatility spiked significantly**  
   Sharpe penalizes volatility, and realized volatility surged during crisis conditions.

3. **Model-based strategy adapted to regime shifts**  
   The ARIMA–GARCH strategy could avoid exposure or flip direction in response to negative forecasts, reducing drawdown participation.

4. **Crisis periods reinforce short-horizon predictability**  
   During high-volatility events, both return autocorrelation and volatility persistence increase, enhancing the effectiveness of ARIMA–GARCH forecasting relative to calm market conditions.

---

## Tools and Technologies

This project demonstrates:

- **Languages**: R
- **Libraries**: `quantmod`, `rugarch`, `timeSeries`, `tseries`
- **Skills**:
  - Financial time-series modelling
  - GARCH volatility forecasting
  - Strategy simulation & benchmarking
  - API-based data acquisition (`getSymbols` for price extraction from Yahoo Finance)
  - Statistical analysis
  - Visualization and reporting

---

## Author
Carmen Wong


