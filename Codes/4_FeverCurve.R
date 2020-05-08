#-------------------------------------------------------------------------------------
# A daily fever curve for the Swiss economy
#-------------------------------------------------------------------------------------
# Feel free to copy, adapt, and use this code for your own purposes at 
# your own risk.
#
# Please cite: 
# Burri, Marc and Daniel Kaufmann (2020): "A daily fever curve for the
# Swiss economy", IRENE Working Paper No., University of Neuchâtel,
# https://github.com/dankaufmann/f-curve
#
# Marc Burri and Daniel Kaufmann, 2020 (daniel.kaufmann@unine.ch)
#-------------------------------------------------------------------------------------
# V 1.0
#-------------------------------------------------------------------------------------

# Packages and settings
rm(list = ls())
source("AllPackages.R")
normStart <- as.Date("1999-01-01")
startDate <- as.Date("2000-01-01")

endDate       <- Sys.Date()
noMANews      <- 5      # Number of days uncentered moving average for news (otherwise very volatile) do that in second step...
noMA          <- 5      # Working days for moving average
leadTS        <- 0.5    # Lead of term-spread on the business cycle (in years)

# Choose Which indicators to use
whichInd   <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
indexDom   <- c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  1,  1)    # Don't do decomposition here (later)

#-------------------------------------------------------------------------------------
# Get the data
#-------------------------------------------------------------------------------------
load(file="../Data/IndicatorData.RData")

# Estimate the factor
Results <- computeFactors(Indicators, leadTS, noMANews, normStart, startDate, endDate, whichInd, indexDom)
fc <- ts_xts(Results[[1]]$fc)
lastObsDate <- Results[[2]]

# Make sure that counter-cyclical
signInd   <- sign(as.numeric(fc["2009-01-20"])-as.numeric(fc["2007-12-13",]))
fc        <- fc*signInd

# Smooth with moving average 
fc_s  <- rollapply(fc, noMA, mean, na.rm = TRUE)

# Main chart of curve
DataCor <- as.data.frame(ts_c(ts_pca(GDP), ts_frequency(fc, to = "quarter", aggregate = "mean", na.rm = TRUE)))
Correl  <- cor(DataCor, use = "na.or.complete")[1, 2]
p <- ts_ggplot(
  # `Baseline, five-day moving-av., inv. scale`  = -fc_s ,
  `Baseline, inv. scale`                         = -fc,
  `GDP growth (ann.)`                           = ts_span(ts_pca(GDP), startDate),
  title = paste("f-curve and GDP (last obs.:", lastObsDate, ")", sep = "")
)
p <- ggLayout(p)
p <- ggColor2(p)
p <- addLines(p, myLines, myLabels, -11)
p <- addCorr(p, -Correl, "2015-01-01", 6.5)
p
ggsave(filename = "../Results/MainGDP.pdf", width = figwidth, height = figheight)
ggsave(filename = "../Results/MainGDP.png", width = figwidth, height = figheight)

# Main chart of curve
ShortLines <- c("2020-03-16", "2020-03-25", "2020-04-03", "2020-04-16", "2020-04-30")
ShortLabels <- c("Covid-19 lockdown", "Economic aid package (announced)", "Increase aid package (announced)", "Easing lockdown (phase I, announced)", "Easing lockdown (phase II, announced)")
p <- ts_ggplot(
  `Baseline, five-day moving-average`  = ts_span(fc_s, "2020-02-01"),
  `Baseline, raw data`                         = ts_span(fc, "2020-02-01"),
  title = paste("f-curve during Covid-19 lockdown (last obs.:", lastObsDate, ")", sep = "")
)
p <- ggLayout(p)
p <- ggColor3(p)
p <- addLines(p, ShortLines, ShortLabels, -8)
p <- p + scale_x_date(labels =  date_format("%b %Y"))
ggsave(filename = "../Results/MainGDPShort.pdf", width = figwidth, height = figheight)
ggsave(filename = "../Results/MainGDPShort.png", width = figwidth, height = figheight)
p

# Save data for later analysis
save(list = c("fc", "fc_s", "lastObsDate"), file = "../Data/f-curve.RData")
toExport <- data.frame(fc, fc_s, lastObsDate)
colnames(toExport) <- c("f-curve", "smoothed", "update")
write.csv(toExport, file = "../Results/f-curve-data.csv")