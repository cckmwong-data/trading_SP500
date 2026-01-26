# Import the necessary libraries
library(quantmod)
library(timeSeries)
library(rugarch)
library(tseries)

#Get the adjusted closing price of S&P500 from Yahoo Finance since 2008
getSymbols("^GSPC", from="2018-01-01")
returns = diff(log(Ad(GSPC)))

# sets the first return value to 0
# the first return in a financial time series is usually undefined 
# (there’s no previous price to compare with)
returns[as.character(head(index(Ad(GSPC)),1))] = 0

#Check if the series of daily log returns is stationary 
#using Augmented Dickey-Fuller (ADF) test to check if the series is stationary
# null hypothesis: the presence of unit root (random walk) in a time series 
returns_na <- na.omit(diff(log(Ad(GSPC)))) #truncate the NA value 
print(adf.test(returns_na)) #p-value < 0.05, so it is stationary

#set the window of 500 days
window = 500
#Length of forecasting period = Total Time Frame - Length of Window
foreLength = length(returns) - window
#create a vector (a 1-D string vector) for storing forecasted returns
forecasts <- vector(mode="character", length=foreLength)

#Forecast trading signal (BUY/ HOLD/ SELL) by calculating the rolling log daily returns
#Searching for the optimal parameters p and q of the ARIMA model by AIC
#Fitting the optimal ARIMA model to GARCH (1,1)
#Predicting the trading signal and obtain the expected returns using this strategy
#This procedure is carried out repetitively for each particular day
for (i in 0:foreLength) {
  #Obtain the actual returns for each day from day 1 until the last date of the forecasting period on rolling basis
  rolling_returns = returns[(1+i):(window+i)]
  
  #Fit the ARIMA model with selection of p and q < 4
  final.aic <- Inf
  final.order <- c(0,0,0)
  for (p in 0:4) for (q in 0:4) {
    if ( p == 0 && q == 0) {
      next
    }
    #Fitting the model using rolling returns by searching for the optimal p and q (set d = 0)
    arimaFit = tryCatch( arima(rolling_returns, order=c(p, 0, q)),
                         error=function( err ) FALSE,
                         warning=function( err ) FALSE )
    
    #If the model is valid, check the AIC of the model 
    if( !is.logical( arimaFit ) ) {
      current.aic <- AIC(arimaFit)
      #The optimal model with particular values of p and q will be the one with the lowest AIC
      if (current.aic < final.aic) {
        final.aic <- current.aic
        final.order <- c(p, 0, q)
        final.arima <- arima(rolling_returns, order=final.order)
      }
    } else {
      next
    }
  }
  
  #Define GARCH(1,1) model with ARMA mean (p = final.order[1]; q = final.order[3])
  spec = ugarchspec(
    variance.model=list(garchOrder=c(1,1)),
    mean.model=list(armaOrder=c(final.order[1], final.order[3]), include.mean=T),
    distribution.model="sged"
  )
  #Fit ARIMA and GARCH model using the rolling returns
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

#Convert forecasts into a dataframe
forecast_df <- do.call(rbind, strsplit(forecasts, ","))  #Split string into date & direction
forecast_dates <- as.Date(forecast_df[,1])               #Extract dates
forecast_directions <- as.numeric(forecast_df[,2])       #Extract predicted directions

#Create a time series for the forecasted directions
strategy_directions_ts <- xts(forecast_directions, order.by = forecast_dates)

#Shift the forecasts by 1 day, as in practical trading decision is based on the results of the model on the previous day-end
strategy.direction <- lag.xts(strategy_directions_ts, k = 1)

#Actual strategy returns = Trading direction * Actual return
strategy.returns <- strategy.direction * returns[window:length(returns)]
strategy.returns[1] <- 0 #set the first value of return from NA to 0

#Daily returns are additive in log terms
strategy.curve <- cumsum(strategy.returns)
buy_hold.curve <- cumsum(returns[(window):length(returns)])
buy_hold.curve[1] <- 0 #set the first value of return from NA to 0

#Combine the performance of the 2 strategies and plot the graph
both.curves <- cbind(strategy.curve, buy_hold.curve)
colnames(both.curves) <- c("Strategy Returns", "Buy & Hold Returns")

plot(both.curves[, "Strategy Returns"], main = "Daily Returns: ARIMA+GARCH (green) vs Buy & Hold (red)",
     col = "green", ylab = "Log Daily Return", xlab = "Date")
lines(both.curves[, "Buy & Hold Returns"], col = "red")
legend("bottomleft", legend = c("ARIMA+GARCH Strategy", "Buy & Hold"), col = c("green", "red"), lty = 1)

# Define the dates
start_date <- as.Date("2020-03-01")
end_date <- as.Date("2022-03-01")

# Extract strategy returns between the start date and end date
strategy_returns_filtered <- strategy.returns[index(strategy.returns) <= end_date & index(strategy.returns) >= start_date]
buy_hold_returns_filtered <- returns[index(strategy.returns) <= end_date & index(strategy.returns) >= start_date]

#Assume the risk free rate as 2% p.a.
risk_free_rate <- 0.02/252  

# Mean and standard deviation of strategy returns
mean_return_strategy <- mean(strategy_returns_filtered, na.rm = TRUE)
std_dev_strategy <- sd(strategy_returns_filtered, na.rm = TRUE)

mean_return_buy_hold <- mean(buy_hold_returns_filtered, na.rm = TRUE)
std_dev_buy_hold <- sd(buy_hold_returns_filtered, na.rm = TRUE)

# Daily Sharpe Ratio
sharpe_ratio_daily_strategy <- (mean_return_strategy - risk_free_rate) / std_dev_strategy  
sharpe_ratio_daily_buy_hold <- (mean_return_buy_hold - risk_free_rate) / std_dev_buy_hold  

# Annualize the Sharpe Ratio (assuming 252 trading days)
sharpe_ratio_annual_strategy <- sharpe_ratio_daily_strategy * sqrt(252)
sharpe_ratio_annual_buy_hold <- sharpe_ratio_daily_buy_hold * sqrt(252)

# Print the result
print(paste("Annualized Sharpe Ratio of ARIM+GARCH strategy:", round(sharpe_ratio_annual_strategy, 4)))
print(paste("Annualized Sharpe Ratio of Buy-and-Hold strategy:", round(sharpe_ratio_annual_buy_hold, 4)))
