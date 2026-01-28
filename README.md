# Trading S&P 500 Using ARIMA–GARCH Model

This [project](https://cckmwong-data.github.io/trading_SP500/S-P500_ARIMA_GARCH_final.html) applies **ARIMA–GARCH model** to daily S&P 500 returns to assess whether short-horizon forecasts can produce superior risk-adjusted performance relative to a passive Buy-and-Hold benchmark. The project demonstrates practical applications of time-series econometrics, financial forecasting, and strategy backtesting.

<img src="./images/SP500_returns.png" width="" height="500">

---

## Problem Statement

Financial time series frequently exhibit features such as autocorrelation, non-constant variance, and heavy tails. Traditional linear models fail to capture these dynamics, particularly during periods of market stress.

This project evaluates whether incorporating both conditional mean and conditional variance dynamics via ARIMA–GARCH can improve portfolio decision-making. Specifically, the analysis shows that:

- Forecasted returns (ARIMA mean) can inform directional positioning,
- Volatility forecasts can enhance risk-adjusted performance metrics, and
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
- Frequency: Daily closing prices
- Transformation: Prices → *First Difference of Log returns* `diff(log(Ad(GSPC)))`
- Handling: Removal of initial NA returns `returns_na <- na.omit(diff(log(Ad(GSPC))))`
- Period: 2018-01-01 - 2025-12-31

We selected daily log returns because they convert multiplicative price changes into an additive format. This also ensures **stationarity**, satisfying a core requirement for ARIMA and GARCH modeling that raw price levels fail to meet.

---

## Methods and Modeling Approach

### Time Series Modeling

The modeling pipeline consists of:

1. **ARMA(p,q), where p, q are in the range of 0 and 4 (with d=0)** for conditional mean forecasts  
2. **GARCH(1,1)** for conditional variance forecasts

ARIMA order selection is performed using **AIC minimization** via `auto.arima()`. A fixed GARCH(1,1) structure is then applied to capture volatility clustering in the ARIMA residuals.

### Trading Strategy Logic

We combine the optimal ARIMA model with GARCH (1,1) which will be used to fit the return of each rolling window and predict the trading signal and expected returns of the following day.

- **Buy (Long)** if forecasted return > 0
- **Sell (Short)** if forecasted return < 0
- **Hold** if the model fails to converge

Signals are executed on the next trading day.

### Choice of Risk-free Rate (Rf)

During the pandemic (2020-2022), the Federal Reserve slashed interest rates to the "zero-lower bound" to support the economy, the return on safe assets effectively vanished. One of the most common proxies for the risk-free rate (Rf​) is the *3-Month U.S. Treasury Bill* which is an annualized money-market yield. 

Here is how it averaged during that window:

- 2020 (March–December): ~0.10%
- 2021 (Full Year): ~0.05%
- 2022 (January–March): ~0.30% (Rates only began rising in mid-March 2022)

**So, the estimated average Rf (Mar 2020 – Mar 2022): ~0.15% per annum**

<img src="./images/3mth_Tbills.png" width="" height="400">
---

## Evaluation Metric

Performance is compared against a passive **Buy-and-Hold** benchmark using **Annualized Sharpe Ratio**:

*Daily Sharpe Ratio = (mean of daily returns - risk-free rate/ 252)/ standard deviation of daily returns*

*Annualized Sharpe Ratio = Daily Sharpe Ratio * sqrt(252)*

Sharpe ratio is chosen because it adjusts for volatility and is a standard performance metric in quantitative finance. 252 days is used to calculate the annualized Sharpe Ratio, as there are generally 252 trading days a year for the US stock market.

---

## Results Summary

We noticed that the ARIMA–GARCH strategy posted a consistently high Sharpe ratio during the COVID-19 pandemic period between March 2020 and March 2022, indicating strong risk-adjusted performance. 

**The annualized Sharpe Ratio of ARIM+GARCH strategy is 1.2403, significantly higher than 0.0111 for Buy-and-Hold strategy, during the COVID pandemic.**

### Reason for Sharpe Divergence

This divergence arises because:

1. **Dynamic Risk Mitigation (GARCH)**: The model identified *volatility clustering* (i.e. *conditional heteroskedasticity*) during the pandemic. By forecasting spikes in conditional variance, it reduced exposure during high-risk periods, lowering the denominator (realized volatility) compared to the benchmark.

2. **Precision Entry/Exit (ARIMA)**: By modeling the conditional mean, the strategy captured short-term trends and "V-shaped" reversals. This allowed for consistent gains (higher numerator) while the benchmark remained stagnant during recovery phases.

3. **Drawdown Protection**: The active investment strategy using ARIMA ande GARCH successfully navigated "tail risk" events and transformed into significant *alpha*. By reacting to statistical signals rather than holding through the crash, it avoided the deep capital erosion that led to the extremely low Sharpe ratio for the passive strategy.

---

## Future Improvements and Extensions

A series of enhancements can be implemented to address real-world market frictions, model assumptions, and scalability requirements.

### 1. Transaction Costs and Execution Modeling

The current backtest operates under a frictionless assumption. Real trading environments impose non-trivial execution costs, especially for strategies that rebalance frequently.

- **Commissions:** Fixed or proportional fees assessed per order.
- **Bid–Ask Spread:** Execution price modeled off the spread, which typically widens during high-volatility regimes (e.g., COVID pandemic).
- **Slippage:** Price deviation between signal generation (e.g., close) and actual execution (e.g., next-day open).

Integrating these frictions enables more realistic profit and loss estimation and prevents overstated alpha.

### 2. Enhanced Risk Management & Position Sizing

Although GARCH provides conditional variance estimates, the current strategy employs binary buy/ sell/hold logic. Production-grade systems generally modulate position size as a function of forecasted risk.

- **Volatility Targeting:** Dynamically adjusting position size so that the portfolio maintains a roughly constant volatility level through time (e.g. Scale exposure inversely to predicted volatility)
- **Stop-Loss / Take-Profit Levels:** Hard exits to curb losses or take profits during extreme tail events that exceed parametric volatility assumptions.
- **Drawdown Controls:** Constraints on portfolio-level drawdowns to prevent catastrophic capital impairment.

These mechanisms improve both capital efficiency and operational robustness.

### 3. Multi-Asset Expansion & Exogenous Drivers (ARIMAX)

Introducing additional predictive signals and cross-asset structure can increase model capacity and reduce idiosyncratic noise. Incorporate variables (*eXogenous variables*) in ARIMAX model such as VIX, inflation, or interest rates to enrich the conditional mean.

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


