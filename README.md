# Trading S&P 500 Using ARIMA–GARCH Model

This project applies **ARIMA–GARCH modelling** to daily S&P 500 returns to assess whether short-horizon forecasts can produce superior risk-adjusted performance relative to a passive Buy-and-Hold benchmark. The project demonstrates practical applications of time-series econometrics, financial forecasting, and strategy backtesting.

<img src="./images/returns.png" width="" height="500">

---

## 1. Problem Statement and Motivation

Financial time series frequently exhibit features such as autocorrelation, non-constant variance, and heavy tails. Traditional linear models fail to capture these dynamics, particularly during periods of market stress.

This project evaluates whether incorporating both conditional mean and conditional variance dynamics via ARIMA–GARCH can improve portfolio decision-making. Specifically, the analysis tests whether:

- Forecasted returns can inform directional positioning, and
- Volatility forecasts can enhance risk-adjusted performance metrics.

The motivation extends to real-world financial analytics use cases, including:

- Short-horizon signal generation
- Risk management and volatility monitoring
- Strategy evaluation and benchmarking
- Algorithmic trading research workflows

---

## 2. Data

- Instrument: **S&P 500 Index (GSPC)**
- Source: Yahoo Finance via `quantmod::getSymbols()`
- Frequency: Daily close prices
- Transformation: Prices → Log returns
- Handling: Removal of initial NA returns
- Period: Full availability from Yahoo Finance

Daily log returns were selected because they:

- Convert multiplicative price changes into additive form
- Are standard in financial econometrics
- Align with ARIMA–GARCH modelling assumptions

---

## 3. Methods and Modeling Approach

### 3.1 Time Series Modeling

The modeling pipeline consists of:

1. **ARIMA** for conditional mean forecasts  
2. **GARCH(1,1)** for conditional variance forecasts

ARIMA order selection is performed using **AIC minimization** via `auto.arima()`. A fixed GARCH(1,1) structure is then applied to capture volatility clustering in the ARIMA residuals.

### 3.2 Trading Strategy Logic

Forecasts generate next-day trading signals based on:

- **Buy (Long)** if forecasted return > 0
- **Sell (Short)** if forecasted return < 0
- **Hold** if the model fails to converge

Signals are executed on the next trading day. No leverage, transaction costs, or shorting constraints are included in the baseline implementation, to isolate model behavior and risk-adjusted return characteristics.

---

## 4. Evaluation Metric

Performance is compared against a passive **Buy-and-Hold** benchmark using **Annualized Sharpe Ratio**:

