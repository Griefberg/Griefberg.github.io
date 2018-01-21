library(BTYD); library(data.table); library(lubridate); library(zoo); library(DEoptim); 
library(ggplot2); library(gridExtra); library(ggthemr)

# ggplot theme
ggthemr('dust')

# constants
.MARGIN.PERCENT <- 0.3
.D <- 0.01

# helpers
monnb <- function(d) { 
    lt <- as.POSIXlt(as.Date(d, origin="1900-01-01")) 
    lt$year*12 + lt$mon 
    } 
mondf <- function(d1, d2) { monnb(d2) - monnb(d1) }

retention.function <- function(data, par) {
    with(data, 
         sum((avg.retention - (par[1] * exp(-par[2] * period) + (1 - par[1]) * exp(-par[3] * period)))^2))
    }
retention.forecast <- function(data, par){
    with(data, par[1] * exp(-par[2] * period) + (1 - par[1]) * exp(-par[3] * period))
    }
agmpu.function <- function(data, par) {
    with(data, 
         sum((avg.agmpu - ((par[1] * period + par[2]) / (period + par[3])))^2))
    }
agmpu.forecast <- function(data, par){
    with(data, (par[1] * period + par[2]) / (period + par[3]))
    }

# get transactions data (we don't have enough data =>  reduplicate it for the valid example)
transactions <- fread(system.file("data/cdnowElog.csv", package = "BTYD"), 
                      select=c('sampleid', 'date', 'sales'), 
                      col.names=c('cust', 'date', 'price'))
transactions$date <- as.Date(as.character(transactions$date), format = "%Y%m%d")
transactions <- rbind(transactions, 
                      transactions[, .(cust=cust+max(transactions$cust), date=date %m+% months(3), price=price)], 
                      transactions[, .(cust=cust+2*max(transactions$cust), date=date %m+% months(6), price=price)], 
                      transactions[, .(cust=cust+3*max(transactions$cust), date=date %m+% months(9), price=price)])
transactions <- transactions[date %between% c('1997-01-01', '1997-12-31'),]
transactions[, birth:=floor_date(min(date), 'month'), by='cust']
transactions[, period:=mondf(transactions$birth, transactions$date)]

# step 1 historical cohorts
cohorts.size <- transactions[, .(cohort_size = length(unique(cust))), by='birth']
cohorts.grid <- transactions[, .(retained_users=length(unique(cust)),
                                 revenue=sum(price),
                                 orders=.N), by=c('birth', 'period')]
setorder(cohorts.grid, birth, period)
cohorts.grid <- cohorts.grid[cohorts.size, on='birth', nomatch=0L]
cohorts.grid[, retention:=retained_users / cohort_size]
cohorts.grid[, agmpu:=.MARGIN.PERCENT*revenue/retained_users]
cohorts.grid[, orders:=orders/retained_users]

# step 2 average cohort
avg.cohort <- cohorts.grid[, .(avg.retention=sum(retention*cohort_size) / sum(cohort_size),
                               avg.agmpu=sum(agmpu*cohort_size) / sum(cohort_size),
                               avg.orders=sum(orders*cohort_size) / sum(cohort_size)), by='period']

ret.plot <- ggplot(data=avg.cohort, aes(period, avg.retention)) + geom_line() + 
    scale_x_continuous(name="Cohorts Period") + scale_y_continuous(name="Retention") +
    ggtitle('Average Retention vs. Cohort Periods (months)')
agmpu.plot <- ggplot(data=avg.cohort, aes(period, avg.agmpu)) + geom_line() + 
    scale_x_continuous(name="Cohorts Period") + scale_y_continuous(name="AGMPU", limits=c(0, 17)) +
    ggtitle('Average AGMPU vs. Cohort Periods (months)')
grid.arrange(ret.plot, agmpu.plot)
g <- arrangeGrob(ret.plot, agmpu.plot)
ggsave(file="historical_values.png", g)

# step 3 fitting retention and AGMPU
retention.fit <-  DEoptim(retention.function, lower=c(0.01, 0.01, 0.01), upper=c(1, 100, 100),
                       data=avg.cohort)
agmpu.fit <-  DEoptim(agmpu.function, lower=c(1, 0, 0), upper=c(150, 5, 1),
                      data=avg.cohort)
avg.cohort[, pred.retention:=retention.forecast(avg.cohort, retention.fit$optim$bestmem)]
avg.cohort[, pred.agmpu:=agmpu.forecast(avg.cohort, agmpu.fit$optim$bestmem)]

ret.plot.pred <- ggplot(data=avg.cohort, aes(period, avg.retention)) + geom_line() +
    geom_line(aes(y=pred.retention), col='black', linetype = 'dashed') +
    scale_x_continuous(name="Cohorts Period (months)") + scale_y_continuous(name="Retention") +
    ggtitle('Average Retention vs. Cohort Periods')
agmpu.plot.pred <- ggplot(data=avg.cohort, aes(period, avg.agmpu)) + geom_line() + 
    geom_line(aes(y=pred.agmpu), col='black', linetype = 'dashed') +
    scale_x_continuous(name="Cohorts Period (months)") + scale_y_continuous(name="AGMPU", limits=c(0, 17)) +
    ggtitle('Average AGMPU vs. Cohort Periods')
grid.arrange(ret.plot.pred, agmpu.plot.pred)
g <- arrangeGrob(ret.plot.pred, agmpu.plot.pred)
ggsave(file="predicted_values.png", g)

# step 4 prediction for 5 years (rule of thumb: look when retention rate is close to zero)
pred.cohorts <- data.table(period=0:60)
pred.cohorts[, pred.retention:=retention.forecast(pred.cohorts, retention.fit$optim$bestmem)]
pred.cohorts[, pred.agmpu:=agmpu.forecast(pred.cohorts, agmpu.fit$optim$bestmem)]
pred.cohorts[, one_d_n:=(1 + .D)**period] # (1 + d)^n

ret.plot.five.years <- ggplot(data=pred.cohorts, aes(period, pred.retention)) + 
    geom_line(col='black', linetype = 'dashed') +
    scale_x_continuous(name="Cohorts Period (months)") + scale_y_continuous(name="Retention") +
    ggtitle('Average Retention vs. Cohort Periods (60 Months Prediction)')
g <- ret.plot.five.years
ggsave(file="five_years_values.png", g, width = 6.9, height = 3.31)

# step 5 calculate LTV
.LTV <- with(pred.cohorts, sum(pred.retention * pred.agmpu / one_d_n)) 
