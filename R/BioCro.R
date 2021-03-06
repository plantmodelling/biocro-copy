##
##  BioCro/R/BioCro.R by Fernando Ezequiel Miguez  Copyright (C) 2007-2015
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 or 3 of the License
##  (at your option).
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  A copy of the GNU General Public License is available at
##  http://www.r-project.org/Licenses/
##
##
## Some of the code used internally in BioGro is derived from WIMOVAC
##
## WIMOVAC was created by Stephen Long and Steve Humphries
## http://www.life.illinois.edu/plantbio/wimovac/model.htm


BioGro <- function(WetDat, day1=NULL, dayn=NULL,
                   timestep=1,
                   lat=40,iRhizome=7,irtl=1e-4,
                   canopyControl=list(),
                   seneControl=list(),
                   photoControl=list(),
                   phenoControl=list(),
                   soilControl=list(),
                   nitroControl=list(),
                   centuryControl=list())
  {

    
## Trying to guess the first and last day of the growing season from weather data
    
    if(missing(day1)){
        half <- as.integer(dim(WetDat)[1]/2)
        WetDat1 <- WetDat[1:half,c(2,5)]
        if(min(WetDat1[,2]) > 0){
          day1 <- 90
        }else{
        WetDat1s <- WetDat1[which(WetDat1[,2]<0),]
        day1 <- max(WetDat1s[,1])
        if(day1 < 90) day1 <- 90
      }
     }
    if(missing(dayn)){
        half <- as.integer(dim(WetDat)[1]/2)
        WetDat1 <- WetDat[half:dim(WetDat)[1],c(2,5)]
        if(min(WetDat1[,2]) > 0){
          dayn <- 330
        }else{
          WetDat1s <- WetDat1[which(WetDat1[,2]<0),]
          dayn <- min(WetDat1s[,1])
          if(dayn > 330) dayn <- 330
        }
      }
    
    if((day1<0) || (day1>365) || (dayn<0) || (dayn>365))
      stop("day1 and dayn should be between 0 and 365")

    if(day1 > dayn)
      stop("day1 should be smaller than dayn")

    if( (timestep<1) || (24%%timestep != 0))
      stop("timestep should be a divisor of 24 (e.g. 1,2,3,4,6,etc.)")

    ## Getting the Parameters
    canopyP <- canopyParms()
    canopyP[names(canopyControl)] <- canopyControl
    
    soilP <- soilParms()
    soilP[names(soilControl)] <- soilControl

    nitroP <- nitroParms()
    nitroP[names(nitroControl)] <- nitroControl

    phenoP <- phenoParms()
    phenoP[names(phenoControl)] <- phenoControl

    photoP <- photoParms()
    photoP[names(photoControl)] <- photoControl

    seneP <- seneParms()
    seneP[names(seneControl)] <- seneControl

    centuryP <- centuryParms()
    centuryP[names(centuryControl)] <- centuryControl

    tint <- 24 / timestep
    vecsize <- (dayn - (day1-1)) * tint
    indes1 <- (day1-1) * tint
    indesn <- (dayn) * tint
    
    doy <- WetDat[indes1:indesn,2]
    hr <- WetDat[indes1:indesn,3]
    solar <- WetDat[indes1:indesn,4]
    temp <- WetDat[indes1:indesn,5]
    rh <- WetDat[indes1:indesn,6]
    windspeed <- WetDat[indes1:indesn,7]
    precip <- WetDat[indes1:indesn,8]

    if(max(rh) > 1)
      stop("Rel Hum. should be 0 < rh < 1")
    if((min(hr) < 0) | (max(hr) > 23))
      stop("hr should be between 0 and 23")
    
    DBPcoefs <- valid_dbp(as.vector(unlist(phenoP)[7:31]))

    TPcoefs <- as.vector(unlist(phenoP)[1:6])

    SENcoefs <- as.vector(unlist(seneP))

    soilCoefs <- c(unlist(soilP[1:5]),mean(soilP$iWatCont),soilP$scsf, soilP$transpRes, soilP$leafPotTh, soilP$smthresh, soilP$lrt, soilP$lrf)
    wsFun <- soilP$wsFun
    soilType <- soilP$soilType

    centCoefs <- as.vector(unlist(centuryP)[1:24])

    if(centuryP$timestep == "year"){
      stop("Not developed yet")
      centTimestep <- dayn - day1 ## This is really the growing season
    }
    if(centuryP$timestep == "week") centTimestep <- 7
    if(centuryP$timestep == "day") centTimestep <- 1
    if(centuryP$timestep == "hour") centTimestep <- 1/24
    
    vmax <- photoP$vmax
    alpha <- photoP$alpha
    kparm <- photoP$kparm
    theta <- photoP$theta
    beta <- photoP$beta
    Rd <- photoP$Rd
    Catm <- photoP$Catm
    b0 <- photoP$b0
    b1 <- photoP$b1
    ws <- photoP$ws

    mResp <- canopyP$mResp
    kd <- canopyP$kd
    chi.l <- canopyP$chi.l
    Sp <- canopyP$Sp
    SpD <- canopyP$SpD
    heightF <- canopyP$heightFactor
    leafW <- canopyP$leafwidth
    eteq <- canopyP$eteq
    nlayers <- canopyP$nlayers
    
    res <- .Call(MisGro,
                 as.double(lat),
                 as.integer(doy),
                 as.integer(hr),
                 as.double(solar),
                 as.double(temp),
                 as.double(rh),
                 as.double(windspeed),
                 as.double(precip),
                 as.double(kd),
                 as.double(c(chi.l,heightF,leafW,eteq)),
                 as.integer(nlayers),
                 as.double(iRhizome),
                 as.double(irtl),
                 as.double(SENcoefs),
                 as.integer(timestep),
                 as.integer(vecsize),
                 as.double(Sp),
                 as.double(SpD),
                 as.double(DBPcoefs),
                 as.double(TPcoefs),
                 as.double(vmax),
                 as.double(alpha),
                 as.double(kparm),
                 as.double(theta),
                 as.double(beta),
                 as.double(Rd),
                 as.double(Catm),
                 as.double(b0),
                 as.double(b1),
                 as.integer(ws),
                 as.double(soilCoefs),
                 as.double(nitroP$iLeafN),
                 as.double(nitroP$kLN), 
                 as.double(nitroP$Vmax.b1),
                 as.double(nitroP$alpha.b1),
                 as.double(mResp),
                 as.integer(soilType),
                 as.integer(wsFun),
                 as.double(centCoefs),
                 as.double(centTimestep),
                 as.double(centuryP$Ks),
                 as.integer(soilP$soilLayers),
                 as.double(soilP$soilDepths),
                 as.double(soilP$iWatCont),
                 as.integer(soilP$hydrDist),
                 as.double(c(soilP$rfl,soilP$rsec,soilP$rsdf)),
                 as.double(nitroP$kpLN),
                 as.double(nitroP$lnb0),
                 as.double(nitroP$lnb1),
                 as.integer(nitroP$lnFun))
    
    res$cwsMat <- t(res$cwsMat)
    colnames(res$cwsMat) <- soilP$soilDepths[-1]
    res$rdMat <- t(res$rdMat)
    colnames(res$rdMat) <- soilP$soilDepths[-1]
    res$psimMat <- t(res$psimMat)
    colnames(res$psimMat) <- soilP$soilDepths[-1]
    structure(res,class="BioGro")
  }



canopyParms <- function(Sp = 1.7, SpD = 0, nlayers = 10,
                        kd = 0.7, chi.l = 1,
                        mResp=c(0.02,0.03), heightFactor=3,
                        leafwidth=0.04,
                        eteq=c("Penman-Monteith","Penman","Priestly")){

  if((nlayers < 1) || (nlayers > 50))
    stop("nlayers should be between 1 and 50")

  if(Sp <= 0)
    stop("Sp should be positive")

  if(heightFactor <= 0)
    stop("heightFactor should be positive")

  eteq <- match.arg(eteq)
  if(eteq == "Penman-Monteith") eteq <- 0
  if(eteq == "Penman") eteq <- 1
  if(eteq == "Priestly") eteq <- 2
  
  list(Sp=Sp,SpD=SpD,nlayers=nlayers,kd=kd,chi.l=chi.l,
       mResp=mResp, heightFactor=heightFactor,
       leafwidth=leafwidth, eteq=eteq)

}

photoParms <- function(vmax=39, alpha=0.04, kparm=0.7, theta=0.83, beta=0.93, Rd=0.8, Catm=380, b0=0.08, b1=3, ws=c("gs","vmax")){

  ws <- match.arg(ws)
  if(ws == "gs") ws <- 1
  else ws <- 0
      
  list(vmax=vmax,alpha=alpha,kparm=kparm,theta=theta,beta=beta,Rd=Rd,Catm=Catm,b0=b0,b1=b1,ws=ws)

}


soilParms <- function(FieldC=NULL,WiltP=NULL,phi1=0.01,phi2=10,soilDepth=2,iWatCont=NULL,
                      soilType=6, soilLayers=1, soilDepths=NULL, hydrDist=1,
                      wsFun=c("linear","logistic","exp","none","lwp","thresh"),
                      scsf = 1, transpRes = 5e6, leafPotTh = -800,
                      rfl=0.2, rsec=0.3, rsdf=0.44, smthresh=0.3, lrt=0.3, lrf=0,
                      respcoef=c(0.512, 0.75, 0.0005, 0.0042), acoef=8){

  if(soilLayers < 1 || soilLayers > 50)
    stop("soilLayers must be an integer larger than 0 and smaller than 50")

  if(missing(iWatCont)){
    if(missing(FieldC))
      iWatCont <- rep(SoilType(soilType)$fieldc,soilLayers)
    else
      iWatCont <- rep(FieldC,soilLayers)
  }else{
    if(length(iWatCont) == 1)
      iWatCont <- rep(iWatCont,soilLayers)
  }

  if(length(iWatCont) != soilLayers){
    stop("iWatCont should be NULL, of length 1 or length == soilLayers")
  }

  if(missing(soilDepths)){
    soilDepths <- seq(0,soilDepth,length.out=I(soilLayers+1))
  }else{
    if(length(soilDepths) != I(soilLayers+1)) stop("soilDepths should be of length == soilLayers + 1")
  }

  if(wsFun == "lwp" && soilLayers > 1) stop("At the moment it is not possible to have more than one layer when the lwp option is selected")
  
  if(missing(FieldC)) FieldC <- -1

  if(missing(WiltP))  WiltP <- -1
  
  wsFun <- match.arg(wsFun)
  if(wsFun == "linear")  wsFun <- 0
  else if(wsFun == "logistic") wsFun <- 1
  else if(wsFun =="exp") wsFun <- 2 
  else if(wsFun == "none") wsFun <- 3
  else if(wsFun == "lwp") wsFun <- 4
  else if(wsFun == "thresh") wsFun <- 5
  
  list(FieldC=FieldC,WiltP=WiltP,phi1=phi1,phi2=phi2,soilDepth=soilDepth,iWatCont=iWatCont,
       soilType=soilType,soilLayers=soilLayers,soilDepths=soilDepths, wsFun=wsFun,
       scsf = scsf, transpRes = transpRes, leafPotTh = leafPotTh,
       hydrDist=hydrDist, rfl=rfl, rsec=rsec, rsdf=rsdf, smthresh=smthresh,
       lrt=lrt, lrf=lrf, respcoef=respcoef, acoef=acoef)
}

nitroParms <- function(iLeafN=2, kLN=0.5, Vmax.b1=0, alpha.b1=0,
                       kpLN=0.2, lnb0 = -5, lnb1 = 18, lnFun=c("none","linear")){

  lnFun <- match.arg(lnFun)
  if(lnFun == "none"){
    lnFun <- 0
  }else{
    lnFun <- 1
  }
  
  list(iLeafN=iLeafN, kLN=abs(kLN), Vmax.b1=Vmax.b1, alpha.b1=alpha.b1, kpLN=kpLN,
       lnb0 = lnb0, lnb1 = lnb1, lnFun = lnFun)

}

phenoParms <- function(tp1=562, tp2=1312, tp3=2063, tp4=2676, tp5=3211, tp6=7000,
                       kStem1=0.37, kLeaf1=0.33, kRoot1=0.3, kRhizome1=-8e-4, 
                       kStem2=0.85, kLeaf2=0.14, kRoot2=0.01, kRhizome2=-5e-4, 
                       kStem3=0.63, kLeaf3=0.01, kRoot3=0.01, kRhizome3=0.35, 
                       kStem4=0.63, kLeaf4=0.01, kRoot4=0.01, kRhizome4=0.35, 
                       kStem5=0.63, kLeaf5=0.01, kRoot5=0.01, kRhizome5=0.35, 
                       kStem6=0.63, kLeaf6=0.01, kRoot6=0.01, kRhizome6=0.35, kGrain6=0){

  if(kGrain6 < 0)
    stop("kGrain6 should be positive (zero is allowed)")

  list(tp1=tp1, tp2=tp2, tp3=tp3, tp4=tp4, tp5=tp5, tp6=tp6,
       kStem1=kStem1, kLeaf1=kLeaf1, kRoot1=kRoot1, kRhizome1=kRhizome1, 
       kStem2=kStem2, kLeaf2=kLeaf2, kRoot2=kRoot2, kRhizome2=kRhizome2, 
       kStem3=kStem3, kLeaf3=kLeaf3, kRoot3=kRoot3, kRhizome3=kRhizome3, 
       kStem4=kStem4, kLeaf4=kLeaf4, kRoot4=kRoot4, kRhizome4=kRhizome4, 
       kStem5=kStem5, kLeaf5=kLeaf5, kRoot5=kRoot5, kRhizome5=kRhizome5, 
       kStem6=kStem6, kLeaf6=kLeaf6, kRoot6=kRoot6, kRhizome6=kRhizome6, kGrain6=kGrain6)

  
}

seneParms <- function(senLeaf=3000,senStem=3500,senRoot=4000,senRhizome=4000){

  list(senLeaf=senLeaf,senStem=senStem,senRoot=senRoot,senRhizome=senRhizome)

}

## Function to automatically plot objects of
## BioGro class

## Colors Stem, Leaf, Root, Rhizome, LAI
plot.BioGro <- function (x, obs = NULL, stem = TRUE, leaf = TRUE, root = TRUE, 
                         rhizome = TRUE, LAI = TRUE, grain = TRUE,
                         xlab=NULL,ylab=NULL,ylim=NULL,
                         pch=21, lty=1, lwd=1,
                         col=c("blue","green","red","magenta","black","purple"),
                         x1=0.1,y1=0.8,plot.kind=c("DB","SW","ET","cumET","stress"),...) 
{

  if(missing(xlab)){
    xlab = expression(paste("Thermal Time (",degree,"C d)"))
  }

  if(missing(ylab)){
    ylab = expression(paste("Dry Biomass (Mg ",ha^-1,")"))
  }  

  pchs <- rep(pch,length=6)
  ltys <- rep(lty,length=6)
  cols <- rep(col,length=6)
  lwds <- rep(lwd,length=6)
  plot.kind <- match.arg(plot.kind)
  if(plot.kind == "DB"){
  if (missing(obs)) {
        sim <- x
        if(missing(ylim)) ylim <- c(0, I(max(sim$Stem,na.rm=TRUE) + 5)) 
        plot1 <- xyplot(sim$Stem ~ sim$ThermalT, type = "l", ...,
                        ylim = ylim,
                        xlab = xlab,
                        ylab = ylab, 
                        panel = function(x, y, ...) {
                          if (stem == TRUE) {
                            panel.xyplot(sim$ThermalT, sim$Stem, col = cols[1], 
                                         lty = ltys[1], lwd = lwds[1],...)
                          }
                          if (leaf == TRUE) {
                            panel.xyplot(sim$ThermalT, sim$Leaf, col = cols[2], 
                                         lty = ltys[2], lwd = lwds[2],...)
                          }
                          if (root == TRUE) {
                            panel.xyplot(sim$ThermalT, sim$Root, col = cols[3], 
                                         lty=ltys[3], lwd = lwds[3],...)
                          }
                          if (rhizome == TRUE) {
                            panel.xyplot(sim$ThermalT, sim$Rhizome, col = cols[4], 
                                         lty = ltys[4], lwd = lwds[4],...)
                          }
                          if (grain == TRUE) {
                            panel.xyplot(sim$ThermalT, sim$Grain, col = cols[5], 
                                         lty=ltys[5], lwd = lwds[5],...)
                          }
                          if (LAI == TRUE) {
                            panel.xyplot(sim$ThermalT, sim$LAI, col = cols[6], 
                                         lty = ltys[6], lwd = lwds[6],...)
                          }

                        }, key = list(text = list(c("Stem", "Leaf", "Root", 
                                        "Rhizome", "Grain", "LAI")), col = cols, lty = ltys, lwd = lwds,
                             lines = TRUE, x = x1, y = y1))
        print(plot1)
    }
    else {
      if(ncol(obs) != 7)
        stop("obs should have 7 columns")
      sim <- x
      if(missing(ylim)) ylim <- c(0, I(max(sim$Stem,na.rm=TRUE) + 5)) 
      plot1 <- xyplot(sim$Stem ~ sim$ThermalT, ..., ylim = ylim,
                      xlab = xlab,
                      ylab = ylab, 
                      panel = function(x, y, ...) {
                        if (stem == TRUE) {
                          panel.xyplot(sim$ThermalT, sim$Stem, col = cols[1], 
                                       lty = ltys[1], lwd = lwds[1], type = "l", ...)
                        }
                        if (leaf == TRUE) {
                          panel.xyplot(sim$ThermalT, sim$Leaf, col = cols[2], 
                                       lty = ltys[2], lwd = lwds[2], type = "l", ...)
                        }
                        if (root == TRUE) {
                          panel.xyplot(sim$ThermalT, sim$Root, col = cols[3], 
                                       lty = ltys[3], lwd = lwds[3], type = "l", ...)
                        }
                        if (rhizome == TRUE) {
                          panel.xyplot(sim$ThermalT, sim$Rhizome, col = cols[4], 
                                       lty = ltys[4], lwd = lwds[4], type = "l", ...)
                        }
                        if (grain == TRUE) {
                          panel.xyplot(sim$ThermalT, sim$Grain, col = cols[5], 
                                       lty = ltys[5], lwd = lwds[5], type = "l", ...)
                        }
                        if (LAI == TRUE) {
                          panel.xyplot(sim$ThermalT, sim$LAI, col = cols[6], 
                                       lty = ltys[6], lwd = lwds[6], type = "l", ...)
                        }
                        
                        panel.xyplot(obs[, 1], obs[, 2], col = cols[1], 
                                     pch=pchs[1],...)
                        panel.xyplot(obs[, 1], obs[, 3], col = cols[2], 
                                     pch=pchs[2],...)
                        panel.xyplot(obs[, 1], obs[, 4], col = cols[3], 
                                     pch=pchs[3],...)
                        panel.xyplot(obs[, 1], obs[, 5], col = cols[4], 
                                     pch=pchs[4],...)
                        panel.xyplot(obs[, 1], obs[, 6], col = cols[5], 
                                     pch=pchs[5],...)
                        panel.xyplot(obs[, 1], obs[, 7], col = cols[6], 
                                     pch=pchs[6],...)
                      }, key = list(text = list(c("Stem", "Leaf", "Root", 
                                      "Rhizome", "Grain", "LAI")), col = cols, lines = TRUE, points=TRUE,
                           lty = ltys, pch = pchs, lwd = lwds, x = x1, y = y1))
      print(plot1)
    }
}else
  if(plot.kind == "SW"){
    matplot(x$ThermalT,as.matrix(x$cwsMat),type="l",ylab="Soil Water Content",xlab="Thermal Time")
  }else
  if(plot.kind == "ET"){
    ## First summarize by day
    tmp <- aggregate(x$CanopyTrans, by = list(doy = x$DayofYear), FUN = sum)
    et <- tmp$x * 1e-1
    ## Soil evaporation
    tmp2 <- aggregate(x$SoilEvaporation, by = list(doy = x$DayofYear), FUN = sum)
    se <- tmp2$x * 1e-1
    xyplot(et + se ~ tmp$doy,
           ylab = "Daily EvapoTranspiration (mm)",
           xlab = "DOY",
           key = simpleKey(text = c("transp", "evapo")), ...)
  }else
  if(plot.kind == "cumET"){
    ## First summarize by day
    tmp <- aggregate(x$CanopyTrans, by = list(doy = x$DayofYear), FUN = sum)
    et <- tmp$x * 1e-1
    cumet <- cumsum(et)
    ## Soil evaporation
    tmp2 <- aggregate(x$SoilEvaporation, by = list(doy = x$DayofYear), FUN = sum)
    se <- tmp2$x * 1e-1
    cumse <- cumsum(se)
    xyplot(cumet + cumse + I(cumet+cumse) ~ tmp$doy, type="l",
           ylab = "Cummulative EvapoTranspiration (mm)",
           xlab = "DOY",
           key = simpleKey(text = c("transp", "evapo", "ET")), ...)
  }else
    if(plot.kind == "stress"){
    ## First summarize by day
    xyplot(x$StomatalCondCoef +
           x$LeafReductionCoefs ~ x$DayofYear, type="l",
           ylab = "Stress Indeces",
           xlab = "DOY",
           key = simpleKey(text = c("Stomatal", "Leaf")), ...)
  }

}

print.BioGro <- function(x,level=1,...){

  if(level == 0){
    print(summary(as.data.frame(unclass(x)[1:23])))
  }else
  if(level == 1){
    print(summary(as.data.frame(unclass(x)[c(1,2,5:11)])))
  }else
  if(level == 2){
    print(summary(as.data.frame(unclass(x)[c(1,2,11,12,23)])))
  }else
  if(level == 3){
    print(summary(as.data.frame(unclass(x)[c(1,2,11:23)])))
  }

}

