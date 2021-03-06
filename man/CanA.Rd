\name{CanA}
\alias{CanA}
\alias{lnParms}
\title{Simulates canopy assimilation}

\description{
  It represents an integration of the photosynthesis function
  \code{\link{c4photo}}, canopy evapo/transpiration and the
  multilayer canopy model \code{\link{sunML}}.
}
\usage{
CanA(lai,doy,hr,solar,temp,rh,windspeed,
     lat=40,nlayers=8,kd=0.7,
     stress=1, chi.l=1, leafwidth=0.04,
     heightFactor = 3,
     photoControl = list(),
     lnControl = list(),
     units = c("kg/m2/hr","Mg/ha/hr"))

}

\arguments{

\item{lai}{leaf area index.}
\item{doy}{day of the year, (1--365).}
\item{hr}{hour of the day, (0--23).}
\item{solar}{solar radiation  (\eqn{\mu}{micro} mol \eqn{m^{-2}}{m-2} \eqn{s^{-1}}{s-1}).}
\item{temp}{temperature (Celsius).}
\item{rh}{relative humidity (0--1).}
\item{windspeed}{wind speed (m \eqn{s^{-1}}{s-1}).}
\item{lat}{latitude.}
\item{nlayers}{number of layers in the simulation of the canopy (max
  allowed is 50).}
\item{kd}{ Ligth extinction coefficient for diffuse light.}
\item{stress}{coefficient controlling the effect of water stress on
  stomatal conductance and assimilation.}
\item{chi.l}{ The ratio of horizontal to vertical projected area of
  leaves in the canopy segment. A smaller than 1 value represents a more
  upright canopy and a value higher than 1 is represented by more
  horizontal leaves.}
\item{leafwidth}{average leaf width.}
\item{heightFactor}{ Height Factor. Divide LAI by this number to get the
  height of a crop.}
\item{photoControl}{ list that sets the photosynthesis parameters. See
  \code{\link{BioGro}}.}
\item{lnControl}{ list that sets the leaf nitrogen parameters.

  LeafN: Initial value of leaf nitrogen (g m-2).
  
  kpLN: coefficient of decrease in leaf nitrogen during the
  growing season. The equation is LN = iLeafN * exp(-kLN * (CumLAI-(LAI/nlayers))).

  lnFun: controls whether there is a decline in leaf nitrogen with the
  depth of the canopy. 'none' means no decline, 'linear' means a linear
  decline controlled by the following two parameters.

  lnb0: Intercept of the linear decline of vmax in the depth of the
  canopy. In this function this parameter together with lnb1 will
  override the vmax value set in photoControl.

  lnb1: Slope of the linear decline of leaf nitrogen in the depth of
  the canopy. The equation is 'vmax = leafN_lay * lnb1 + lnb0'.  
}
\item{units}{Whether to return units in kg/m2/hr or Mg/ha/hr. This is
  typically run at hourly intervals, that is why the hr is kept, but it
  could be used with data at finer timesteps and then convert the results.}
}

\value{

  \code{\link{list}} 

  returns a list with several elements

  CanopyAssim: hourly
  canopy assimilation (\eqn{kg m^{-2}}{kg/m2} \eqn{hr^{-1}}{per hour})
  or
  canopy assimilation (\eqn{Mg ha^{-1}}{Mg/ha} \eqn{hr^{-1}}{per hour})

  CanopyTrans: hourly
  canopy transpiration (\eqn{kg m^{-2}}{kg/m2} \eqn{hr^{-1}}{per hour})
  or
  canopy transpiration (\eqn{Mg ha^{-1}}{Mg/ha} \eqn{hr^{-1}}{per hour})

  CanopyCond: hourly
  canopy conductance (mmol/m2/s)

  TranEpen: hourly
  canopy transpiration according to Penman (\eqn{kg m^{-2}}
  \eqn{hr^{-1}}{per hour})
  or
  canopy transpiration according to Penman (\eqn{Mg ha^{-1}}
  \eqn{hr^{-1}}{per hour})

  TranEpries: hourly
  canopy transpiration according to Priestly (\eqn{kg m^{-2}}{kg/m2}
  \eqn{hr^{-1}}{per hour})
  canopy transpiration according to Priestly (\eqn{Mg ha^{-1}}{Mg/ha}
  \eqn{hr^{-1}}{per hour})

  LayMat: hourly by Layer
  matrix containing details of the calculations by layer (each layer is
  a row).
  col1: Direct Irradiance (micro mol/m2/s)
  col2: Diffuse Irradiance (micro mol/m2/s)
  col3: Leaf area in the sun (m2/m2)
  col4: Leaf area in the shade (m2/m2)
  col5: Transpiration of leaf area in the sun (kg/m2/h)
  col6: Transpiration of leaf area in the shade (kg/m2/h)
  col7: Assimilation of leaf area in the sun (micro mol/m2/s)
  col8: Assimilation of leaf area in the shade (micro mol/m2/s)
  col9: Difference in temperature between the leaf and the air
  (i.e. TLeaf - TAir) for leaves in sun (units = C).
  col10: Difference in temperature between the leaf and the air
  (i.e. TLeaf - TAir) for leaves in shade (units = C).
  col11: Stomatal conductance for leaves in the sun
  col12: Stomatal conductance for leaves in the shade
  col13: Nitrogen concentration in the leaf (g m^-2)
  col14: Vmax value as depending on leaf nitrogen
  col15: Relative humidty (0-1)
  col16: Wind speed (m/s)
  col17: Canopy height (m)
}    

\examples{

 \dontrun{
  data(doy124)
  tmp <- numeric(24)

  for(i in 1:24){
    lai <- doy124[i,1]
    doy <- doy124[i,3]
    hr  <- doy124[i,4]
    solar <- doy124[i,5]
    temp <- doy124[i,6]
    rh <- doy124[i,7]
    ws <- doy124[i,8]

    tmp[i] <- CanA(lai,doy,hr,solar,temp,rh,ws)$CanopyAssim

  }

  plot(c(0:23),tmp,
            type="l",lwd=2,
            xlab="Hour",
            ylab=expression(paste("Canopy assimilation (kg  ",
            m^-2," ",h^-1,")")))
 }
}

\keyword{models}
