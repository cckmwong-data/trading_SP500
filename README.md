---
title: "**Trading of S&P 500 on ARIMA–GARCH Model**"
author: "Carmen Wong"
date: "2025-09-18"
output:
  html_document: default
---

```{r setup, include=FALSE}
library(quantmod)
library(timeSeries)
library(rugarch)
library(tseries)
# Enable caching to avoid re-running expensive computations
knitr::opts_chunk$set(cache=TRUE)
```

## **Problem Statement**
We aim to design and backtest an active trading strategy for the S&P 500 that exploits short-term serial dependence in returns and time-varying volatility. Using daily data from Yahoo Finance starting 2018-01-01, we construct a rolling 500-day framework in which, for each window, we select the model by AIC over ARMA(p,q), where p, q are in the range of 0 and 4 (with d=0) and combine it with a GARCH(1,1) volatility model. 

We generate one-day-ahead forecasts of the conditional mean; the trading signal is BUY (1) if the forecast ≥ 0, SELL (−1) if < 0, and HOLD (0) on fitting failures. Signals are executed on the next trading day and performance is evaluated against a buy-and-hold benchmark via cumulative log returns and Sharpe ratios (assuming risk-free rate assumed 2% p.a.). 

The objective is to assess whether the ARIMA–GARCH strategy outperforms passive exposure in different market regimes (e.g. pandemic volatility vs. post-2022 uptrend) on a risk-adjusted basis.

### **1. Retrieve adjusted closing price of S&P500 from Yahoo Finance**
Extract the prices of S&P500 from 2018. Log daily return is preferred as it is additive and differencing log prices removes trends and produces stationary time series.

```{r}
getSymbols("^GSPC", from="2018-01-01")
returns = diff(log(Ad(GSPC)))
returns[as.character(head(index(Ad(GSPC)),1))] = 0
returns
```

### **2. Check stationarity using Augmented Dickey-Fuller (ADF) test**
Check whether the time series is stationary before fitting into ARIMA and GARCH model. Otherwise, we need to introduce the d (differencing) parameter of the model.

```{r, warning = FALSE}
returns_na <- na.omit(diff(log(Ad(GSPC)))) #truncate the NA value 
print(adf.test(returns_na)) #p-value < 0.05, so it is stationary
```

### **3. Set the rolling window and forecasting period**

```{r}
window = 500
#Length of forecasting period = Total Time Frame - Length of Window
foreLength = length(returns) - window
#create a vector for storing forecasted returns
forecasts <- vector(mode="character", length=foreLength)
```

### **4. Predict trading signal (BUY/ HOLD/ SELL)**
We searched through the optimal parameters p and q of the ARIMA model by idenifying the ones with the lowest AIC. Then, we combine the optimal ARIMA model with GARCH (1,1) which will be used to fit the return of each rolling window and predict the trading signal and expected returns of the following day. This procedure is carried out repetitively for each rolling window. 

```{r, cache = TRUE}
for (i in 0:foreLength){
  #Obtain the actual returns for each day from day 1 until the last date of the forecasting period on rolling basis
  rolling_returns = returns[(1+i):(window+i)]
  
  #Fit the ARIMA model with selection of p and q within the range of 0 and 4
  final.aic <- Inf
  final.order <- c(0,0,0)
  for (p in 0:4) for (q in 0:4){
    if ( p == 0 && q == 0){
      next
    }
    #Fit an ARIMA(p,0,q) model to the rolling_returns time series (d = 0)
    arimaFit = tryCatch(arima(rolling_returns, order=c(p, 0, q)),
                         error=function( err ) FALSE,
                         warning=function( err ) FALSE )
    
    #If the model is valid, check the AIC of the model 
    if(!is.logical(arimaFit)){
      current.aic <- AIC(arimaFit)
      #The optimal model with the one with p and q having the lowest AIC
      if (current.aic < final.aic){
        final.aic <- current.aic
        final.order <- c(p, 0, q)
        final.arima <- arima(rolling_returns, order=final.order)
      }
    } else{
      next
    }
  }
  
  #Define GARCH(1,1) model with ARMA mean (p = final.order[1]; q = final.order[3])
  spec = ugarchspec(
    variance.model = list(garchOrder=c(1,1)),
    mean.model = list(armaOrder=c(final.order[1], final.order[3]), include.mean=T),
    distribution.model="sged"
  )
  #Fit the final model (ARIMA + GARCH) using the rolling returns time series
  fit = tryCatch(
    ugarchfit(
      spec, rolling_returns, solver = 'hybrid'
    ), error=function(e) e, warning=function(w) w
  )
  
  #If the model does not converge, set the direction to HOLD (i.e. 0) else
  #choose the trading direction (Buy = 1, SELL = -1) based on the forecasted return
  #Output the results (date and trading signal) on the screen
  if(is(fit, "warning")) {
    forecasts[i+1] = paste(index(rolling_returns[window]), 0, sep=",")
    print(paste(index(rolling_returns[window]), 0, sep=","))
  } else {
    fore = ugarchforecast(fit, n.ahead=1)
    ind = fore@forecast$seriesFor
    forecasts[i+1] = paste(colnames(ind), ifelse(ind[1] < 0, -1, 1), sep=",")
    print(paste(colnames(ind), ifelse(ind[1] < 0, -1, 1), sep=",")) 
  }
}
```

### **5. Trading forecast using ARIMA + GARCH strategy**
We computes the strategy’s daily returns as the product of the lagged direction and the corresponding actual returns over the evaluation window.

```{r}
#Convert forecasts into a matrix
forecast_m <- do.call(rbind, strsplit(forecasts, ","))  #Split string into date & direction
forecast_dates <- as.Date(forecast_m[,1])               #Extract the date column
forecast_directions <- as.numeric(forecast_m[,2])       #Extract the predicted directions column

#Create a time series object (xts) for the forecasted directions
strategy_directions_ <- xts(forecast_directions, order.by = forecast_dates)

#Shift the forecasts by 1 day, as in practical trading decision is based on the results of the model on the previous day-end
strategy.direction <- lag.xts(strategy_directions_, k = 1)

#Actual strategy returns = Trading direction * Actual return
strategy.returns <- strategy.direction * returns[window:length(returns)]
strategy.returns[1] <- 0 #set the first value of return from NA to 0
```

### **6. Plot the curves of investment returns of the strategies**
During the pandemic’s high-volatility regime, active investing (ARIMA-GARCH) outperformed passive investing (Buy-and-Hold). From mid-2022 onwards, S&P500 returned to a broad uptrend. As a result, Buy-and-Hold strategy which is good at capturing long-term drift beat the ARIMA-GARCH model.

```{r}
#Daily returns are additive in log terms for cumulative returns
strategy.curve <- cumsum(strategy.returns)
buy_hold.curve <- cumsum(returns[(window):length(returns)])
buy_hold.curve[1] <- 0 #set the first value of return from NA to 0

#Combine the performance of the 2 strategies and plot the graph
both.curves <- cbind(strategy.curve, buy_hold.curve)
colnames(both.curves) <- c("Strategy Returns", "Buy & Hold Returns")
invisible(both.curves)

plot(both.curves[, "Strategy Returns"], main = "Returns: ARIMA+GARCH (green) vs Buy & Hold (red)",
     col = "green", ylab = "Cumulative Log Return", xlab = "Date")

lines(both.curves[, "Buy & Hold Returns"], col = "red")
legend("bottomleft", legend = c("ARIMA+GARCH", "Buy & Hold"), col = c("green", "red"), lty = 1)
```

### **7. Compare the Sharpe Ratios of the two strategies**
In line with the plot, the ARIMA–GARCH strategy posted a Sharpe ratio above 1 during the pandemic, indicating strong risk-adjusted performance. By contrast, the buy-and-hold benchmark showed a negative Sharpe ratio, implying it underperformed the risk-free rate over the same window.

```{r}
#Noted the ARIMA + GARCH worked better during high market volatility (COVID-19)
start_date <- as.Date("2020-03-01")
end_date <- as.Date("2022-03-01")

#Extract strategy returns from start date to end date
strategy_returns_filtered <- strategy.returns[index(strategy.returns) <= end_date & index(strategy.returns) >= start_date]
buy_hold_returns_filtered <- returns[index(strategy.returns) <= end_date & index(strategy.returns) >= start_date]

#Assume the risk free rate as 2% p.a. and approx. 252 trading days per year
risk_free_rate <- 0.02/252  # daily rate

#Mean and standard deviation of investment returns using ARIMA + GARCH strategy 
mean_return_strategy <- mean(strategy_returns_filtered, na.rm = TRUE)
std_dev_strategy <- sd(strategy_returns_filtered, na.rm = TRUE)

#Mean and standard deviation of investment returns using buy-and-hold strategy
mean_return_buy_hold <- mean(buy_hold_returns_filtered, na.rm = TRUE)
std_dev_buy_hold <- sd(buy_hold_returns_filtered, na.rm = TRUE)

#Daily Sharpe Ratio
sharpe_ratio_daily_strategy <- (mean_return_strategy - risk_free_rate) / std_dev_strategy  
sharpe_ratio_daily_buy_hold <- (mean_return_buy_hold - risk_free_rate) / std_dev_buy_hold  

#Annualize the Sharpe Ratio (assuming 252 trading days)
sharpe_ratio_annual_strategy <- sharpe_ratio_daily_strategy * sqrt(252)
sharpe_ratio_annual_buy_hold <- sharpe_ratio_daily_buy_hold * sqrt(252)
print(paste("Annualized Sharpe Ratio of ARIM+GARCH strategy:", round(sharpe_ratio_annual_strategy, 4)))
print(paste("Annualized Sharpe Ratio of Buy-and-Hold strategy:", round(sharpe_ratio_annual_buy_hold, 4)))
```

