##
##  BioCro/R/sunML.R by Deepak Jaiswal and Joe Iverson  Copyright (C) 2012
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

##
##  This function was written by Deepak Jaiswal following Campbell and Norman
##  with contributions from Joe Iverson
##


sunML <- function(Idir,Idiff,LAI=8,nlayers=8,cos.theta=0.5,kd=0.7,chi.l=1,heightf=3,
                  maxIdir = 2235, maxIdiff = 119){
  ##    /*extinction coefficient evaluated here is defined as ratio of
  ##  shadow on the horizontal area projected from a zenith angle Theta.
  ##    Earlier version of the code was based on ratio of area projected in
  ##    the direction of incoming beam radiation.
  ##  Therefore, cosTheta term in numerator is removed
  ##  */
  ##  /** wishlist**/
  ##  /* currently a default value of kd is used, this value can be calculated, see page 254 of Campbell and Norman */
  ## /* Long Wave radiation balance has not been included in the canopy environment */
  ##  /*Long wave radiation balance is handled to first order in evapotrans/*
  
  alphascatter=0.8 ##/* This value is for PAR, for long wave radiation a smaller value = 0.2 
  ##is recommended see page  255 of campbell and Norman */
  k0 =  sqrt(chi.l ^ 2 + tan(acos(cos.theta))^2)
  k1 = chi.l + 1.744*(chi.l+1.183)^-0.733
  k = k0/k1
  if(k<0){
    k = -k}
  LAIi = LAI / nlayers
  layIdir <- rep(0,nlayers)
  layIdiff <- rep(0,nlayers)
  layItotal <- rep(0,nlayers)
  layIave <- rep(0,nlayers)
  layFsun <- rep(0,nlayers)
  layFshade <- rep(0,nlayers)
  layMaxIdir <- numeric(nlayers)
  layMaxIdiff <- numeric(nlayers)
  layHeight <- rep(0,nlayers)
  kvector <- rep(0,nlayers)
  for(i in 0:(nlayers-1)){
    CumLAI = LAIi * (i+1/2)
    
    Ibeam = Idir * cos.theta
    ##/* scattered radiation ##Eq 15.19 from Campbell and Norman pp 259 */
    Iscat= Ibeam * exp(-k *sqrt(alphascatter)* CumLAI)- Ibeam * exp(-k * CumLAI)
    
    Idiffuse = Idiff * exp(-kd * CumLAI) + Iscat ##/* Eq 15.19 from Campbell and Norman pp 259 */
    maxIdiffuse = maxIdiff * exp(-kd * CumLAI) + Iscat
    
    Isolar = Ibeam * k ##/* Average direct radiation on sunlit leaves */
    maxIsolar = maxIdir * k * cos.theta;
    
    Ls = (1-exp(-k*LAIi)) / k * exp(-k*CumLAI) #use this expression for sunlit leaf area that does 
    #not assume an infinitesmal step

    Ld = LAIi-Ls

    Fsun = Ls/(Ls+Ld)
    Fshade = Ld/(Ls+Ld)

    Itotal =(Fsun*Isolar + Idiffuse) * (1-exp(-k*LAIi))/k

    ## Iaverage = (Fsun*Isolar + Idiffuse) * (1 - exp(-k * LAIi)) / k ## Itot is the radiation
    ## ##intercepted by an average m^2 of leaf in a given layer
    ##print(k)
    Iaverage = (Fsun*(Isolar + Idiffuse) + Fshade*Idiffuse) * (1 - exp(-k * LAIi)) /k
    layIdir[i+1] = Isolar + Idiffuse
    layIdiff[i+1] = Idiffuse
    layItotal[i+1] = Itotal
    layIave[i+1] = Iaverage ## (Isolar + 2*Idiffuse)/2  ## This is the average radiation incident on a leaf
    layFsun[i+1] = Fsun
    layFshade[i+1] = Fshade
    layMaxIdir[i+1] = maxIsolar
    layMaxIdiff[i+1] = maxIdiffuse
    layHeight[i+1] = LAI/heightf - CumLAI / heightf
    ## Old version of the previous line
    ## Change FEM 10/27/2014
    ## layHeight[nlayers-i] = CumLAI / heightf
    Sun=data.frame(layIdir=layIdir,layIdiff=layIdiff,layItotal=layItotal, layIave=layIave,
        layFsun=layFsun,layFshade=layFshade,layHeight=layHeight, layMaxIdir=layMaxIdir, layMaxIdiff=layMaxIdiff)
  }
  return(Sun)
}

## sunML <- function(I.dir,I.diff,LAI=8,nlayers=8,kd=0.1,chi.l=1,cos.theta=0.5){

## 	# extinction coefficient evaluated here is defnied as ratio of 
## 	#  shadow on the horizontal area projected from a zenith angle Theta.
## 	#  Earlier version of the code was based on ratio of area projected in
## 	#  the direction of incoming beam radiation.
## 	#  Therefore, cosTheta term in numerator (k0) is removed. compare
##         # compare line 21 in sunML.R
## k0 = sqrt(chi.l^2 + tan(acos(cos.theta))^2);
## k1 = chi.l + 1.744*(chi.l + 1.183)^-0.733;
## k = abs(k0/k1);
## LAI.sun <- numeric(nlayers)
## LAI.shade <- numeric(nlayers)
## F.sun <- numeric(nlayers)
## F.shade <- numeric(nlayers)
## LAI.i = LAI/nlayers;
## I.solar <- numeric(nlayers)
## I.diffuse <- numeric(nlayers)
## I.total <- numeric(nlayers)

## # This value is for PAR, for long wave radiation a shorter value = 0.2 is recommended see page  255 of campbell and Norman 
## alphascatter=0.8

## for(i in 1:nlayers){
##   CumLAI = LAI.i * i
    
## 	if(i== 1)
## 		      {
		
## 			Iscat=I.dir * exp(-k *sqrt(alphascatter)* CumLAI)-I.dir * exp(-k * CumLAI)
## 			Idiffuse = I.diff * exp(-kd * CumLAI) + Iscat
## 			Isolar = I.dir * k
## 			Itotal = Isolar + Idiffuse
	                
## 			Fcanopy=CumLAI
## 			Ls = (1-exp(-k*CumLAI))/k
## 			Lssaved=Ls         
## 			Ld=Fcanopy-Ls       
## 			Ldsaved=Ld           
## 			Fsun=Ls/(Ls+Ld)         
## 			Fshade=Ld/(Ls+Ld)      
##                       }
##         else
##                        {
##                         Iscat=I.dir * exp(-k *sqrt(alphascatter)* CumLAI)-I.dir * exp(-k * CumLAI)
## 			Idiffuse = I.diff * exp(-kd * CumLAI) + Iscat
## 			Isolar = I.dir * k
## 			Itotal = Isolar + Idiffuse
	                
## 			Fcanopy=CumLAI
## 			Ls = (1-exp(-k*CumLAI))/k
##                         Ld=Fcanopy-Ls
##                         Ls=Ls-Lssaved         
##                         Lssaved = Ls+ Lssaved
## 			Ld=Ld-Ldsaved
##                         Ldsaved=Ld+Ldsaved
## 			Fsun=Ls/(Ls+Ld)         
## 			Fshade=Ld/(Ls+Ld)
##                       }

## I.solar[i] <- Isolar
## I.diffuse[i] <- Idiffuse
## I.total[i] <- Itotal
## F.sun[i] <- Fsun
## F.shade[i] <-Fshade
## LAI.sun[i] <- LAI.i*Fsun[i]
## LAI.shade[i] <- LAI.i*Fshade[i]

## }
## ##print(k)
## sun <- data.frame(I.solar=I.solar , I.diffuse=I.diffuse, I.total=I.total,
##      LAI.sun=LAI.sun,LAI.shade=LAI.shade,Fsun=F.sun,Fshade=F.shade)

## return(sun)
## }




## This is the old sunML function
## The function below is the old version by Fernando Miguez 

## sunML <- function(I.dir,I.diff,LAI=8,nlayers=8,kd=0.1,chi.l=1,cos.theta=0.5){

## k0 = cos.theta * sqrt(chi.l^2 + tan(acos(cos.theta))^2);
## k1 = chi.l + 1.744*(chi.l + 1.183)^-0.733;
## k = abs(k0/k1);
## LAI.sun <- numeric(nlayers)
## LAI.shade <- numeric(nlayers)
## F.sun <- numeric(nlayers)
## F.shade <- numeric(nlayers)
## LAI.i = LAI/nlayers;
## I.solar <- numeric(nlayers)
## I.diffuse <- numeric(nlayers)
## I.total <- numeric(nlayers)

## for( i in 0:nlayers){
## CumLAI = LAI.i * i;
##     if(i == 0){
##       Isolar = I.dir;
##       Idiffuse = I.diff;
##     }
##       else{
##         Isolar = I.dir * exp(-k * CumLAI);
##         Idiffuse = I.diff * exp(-kd * CumLAI);
##       }
##     Itotal = Isolar + Idiffuse;

##     Ls = (1-exp(-k*CumLAI))/k;
##     Ld = CumLAI - Ls;
##     Ls2 = (cos.theta * (1-exp(-k*Ls/cos.theta)))/k;
##     Ld2 = CumLAI - Ls2;

## I.solar[i] <- Isolar
## I.diffuse[i] <- Idiffuse
## I.total[i] <- Itotal
## F.sun[i] <- Ls2/CumLAI
## F.shade[i] <- Ld2/CumLAI
## LAI.sun[i] <- LAI*F.sun[i]
## LAI.shade[i] <- LAI*F.shade[i]

## }

## list(I.solar=I.solar , I.diffuse=I.diffuse, I.total=I.total,
##      LAI.sun=LAI.sun,LAI.shade=LAI.shade,Fsun=F.sun,Fshade=F.shade)
## }
