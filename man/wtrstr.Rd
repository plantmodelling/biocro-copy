\name{wtrstr}
\alias{wtrstr}
\alias{wsRcoef}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{ Simple function to illustrate soil water content effect on
  plant water stress.}
\description{
  This is a very simple function which implements the 'bucket' model
  for soil water content and it calculates a coefficient of plant water
  stress.
}
\usage{
wtrstr(precipt, evapo, cws, soildepth, fieldc, wiltp, phi1 = 0.01, 
    phi2 = 10, smthresh = 0.3, wsFun = c("linear", "logistic", "exp", "none","thresh")) 

wsRcoef(aw, fieldc, wiltp, phi1, phi2, smthresh, wsFun = c("linear", 
    "logistic", "exp", "none", "thresh")) 
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{precipt}{ Precipitation (mm). }
  \item{evapo}{ Evaporation (Mg H2O ha-1 hr-1). }
  \item{cws}{ current water content (fraction).}
  \item{soildepth}{ Soil depth, typically 1m.}
  \item{fieldc}{ Field capacity of the soil (fraction).}
  \item{wiltp}{ Wilting point of the soil (fraction).}
  \item{phi1}{ coefficient which controls the spread of the logistic function.}
  \item{phi2}{ coefficient which controls the effect on leaf area
    expansion.}
  \item{smthresh}{Soil moisture threshold for the 'thresh' method}
  \item{wsFun}{option to control which method is used for the water
    stress function.}

  function \code{wsRcoef} is similar but it takes different arguments.
  \item{aw}{plant available water.}

}
\details{
  This is a very simple function and the details can be seen in the code.
}
\value{
  A list with components:

  \item{rcoefPhoto }{ coefficient of plant water stress for photosyntheis.}
\item{rcoefSpleaf}{coefficient of plant water stress for specific leaf area.}
  \item{naw }{ New available water in the soil.}
}

\seealso{  \code{\link{wsRcoef}} }
\examples{

## Looking at the three possible models for the effect of soil moisture on water
## stress

aws <- seq(0,0.4,0.001)
wats.L <- numeric(length(aws)) # linear
wats.Log <- numeric(length(aws)) # logistic
wats.exp <- numeric(length(aws)) # exp
wats.none <- numeric(length(aws)) # none
wats.thresh <- numeric(length(aws)) # thresh

for(i in 1:length(aws)){
    wats.L[i] <- wtrstr(1,1,aws[i],0.5,0.37,0.2,2e-2,4)$wsPhoto
    wats.Log[i] <- wtrstr(1,1,aws[i],0.5,0.37,0.2,2e-2,4,wsFun="logistic")$wsPhoto
    wats.exp[i] <- wtrstr(1,1,aws[i],0.5,0.37,0.2,2e-2,4, wsFun="exp")$wsPhoto
    wats.none[i] <- wtrstr(1,1,aws[i],0.5,0.37,0.2,2e-2,4, wsFun="none")$wsPhoto
    wats.thresh[i] <- wtrstr(1,1,aws[i],0.5,0.37,0.2,2e-2,4, wsFun="thresh")$wsPhoto
}
     
xyplot(wats.L + wats.Log + wats.exp + wats.none + wats.thresh ~ aws,
       col=c("blue","green","purple","red","black"),
       type = "l",      
       xlab="Soil Water",
       ylab="Stress Coefficient",
       key = list(text=list(c("linear","logistic","exp", "none", "thresh")),
       col=c("blue","green","purple","red","black"), lines = TRUE) )

## This function is sensitive to the soil depth parameter

SDepth <- seq(0.05,2,0.05)

wats <- numeric(length(SDepth))

for(i in 1:length(SDepth)){
wats[i] <- wtrstr(1,4,0.3,SDepth[i],0.37,0.2,2e-2,3)$wsPhoto
}

xyplot(wats ~ SDepth, ylab="Water Stress Coef",
       xlab="Soil depth")

## Difference between the effect on assimilation and leaf expansion rate

aws <- seq(0,0.4,0.001)
wats.P <- numeric(length(aws))
wats.L <- numeric(length(aws))
for(i in 1:length(aws)){
wats.P[i] <- wtrstr(1,1,aws[i],0.5,0.37,0.2,2e-2,4)$wsPhoto
wats.L[i] <- wtrstr(1,1,aws[i],0.5,0.37,0.2,2e-2,4)$wsSpleaf
}

xyplot(wats.P + wats.L ~ aws,
       xlab="Soil Water",
       ylab="Stress Coefficient")


## An example for wsRcoef
## The scale parameter makes a big difference

aws <- seq(0.2,0.4,0.001)
wats.1 <- wsRcoef(aw=aws,fieldc=0.37,wiltp=0.2,phi1=1e-2,phi2=1, wsFun="logistic")$wsPhoto
wats.2 <- wsRcoef(aw=aws,fieldc=0.37,wiltp=0.2,phi1=2e-2,phi2=1, wsFun="logistic")$wsPhoto
wats.3 <- wsRcoef(aw=aws,fieldc=0.37,wiltp=0.2,phi1=3e-2,phi2=1, wsFun="logistic")$wsPhoto

xyplot(wats.1 + wats.2 + wats.3 ~ aws,type="l",
       col=c("blue","red","green"),
       ylab="Water Stress Coef",
       xlab="SoilWater Content",
       key=list(text=list(c("phi1 = 1e-2","phi1 = 2e-2","phi1 = 3e-2")),
         lines=TRUE,col=c("blue","red","green")))


}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ models }

