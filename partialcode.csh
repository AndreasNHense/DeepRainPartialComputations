#!/bin/bash
##fin[1]=target(observational)
##fin[2]=model2
##fin[3]=   conditioned on model 3
# bash script example to perform the computations acc to Glowienka-Hense et al (2020)=GHHBB20
# Glowienka-Hense, R., Hense, A., Brune, S., & Baehr, J. (2020). 
# Comparing forecast systems with multiple correlation decomposition based on partial correlation.
# Advances in Statistical Climatology, Meteorology and Oceanography, 6(2), 103-113.
###################################################################################
## example on netCDF variable tas
###################################################################################
var='tas'
lead1='2-5low'
lead2='2-5low'
lead3='2-5low'
ja=1962
je=2012
#
txt='y'$lead$ja'-'$je
###############################
# prepare name convention for I/O
#################################
name1='Had'
name2='Kalman'
name3='Preop'
###########
dir=$txt'-'$name1'-'$name2'-'$name3'/'
rm -f -r $dir
dir2=ppng
mkdir $dir
mkdir $dir$dir2
###############################################################################
# prepare input files of observations=1 and two model runs=2,3, need to be netCDF
#######################################################################
##obs name 1
fin[1]='../HadCRU/tas_HADCRUT4-median_4_v20180125_196101-201712-4ys.nc'
##.  number (name) 2. corr target 1 compared to base corr target and vice versa
fin[2]='../dkfen4_tas/tas_Amon_MPI-ESM-LR_dkfen4_rmean_195911-201512_lead-2-5low.nc'
##base number (name) 3
fin[3]='../dpes4e_tas/tas_Amon_MPI-ESM-LR_dpes4e_rmean_196011-201512_lead-2-5low.nc'
ls ${fin[3]}
###############################################################################
#  prepare namings for output files acc to GHHBB20 and further developements in DeepRain
###############################################################################
##output
###2x1 above 3x1:name $var_..name2-name3....nc
##fout2 partial 12.3
fout2=$dir$var'_'$name2'-'$name3'-'$txt'par.nc'
fout22=$dir$var'_'$name2'-'$name3'-'$txt'added.nc'
###3x1 above 2x1:name $var_..name3-name2....nc
fout3=$dir$var'_'$name3'-'$name2'-'$txt'par.nc'
fout33=$dir$var'_'$name3'-'$name2'-'$txt'added.nc'
###2x3 given 1 added value both wrong
fout4=$dir$var'_'$name2'-'$name3'-'$txt'negpar.nc'
fout44=$dir$var'_'$name2'-'$name3'-'$txt'false.nc'
fout55=$dir$var'_'$name3'-'$name2'-'$txt'false.nc'
######multiple corr**2
fout123=$dir$var'_'$name2'-'$name3'-'$txt'mcorr.nc'
######common corr**2
fout1213=$dir$var'_'$name2'-'$name3'-'$txt'shared.nc'
###########################
## intermediate help files
##########################
rm -f hlf*.nc
h1='hlf1.nc';h2='hlf2.nc';h3='hlf3.nc'
h4='hlf4.nc';h5='hlf5.nc';h6='hlf6.nc'

###################
## prepare CDO commands.
## Modali, K., Schulzweida, U., Mueller, R., Kornblueh, L., & Mueller, W. (2013, April).
## Climate Data Operators for quick look visualization. In EGU General Assembly Conference Abstracts (pp. EGU2013-11713).
###################
c12=$dir'corr'$name1'-'$name2'.nc'
c13=$dir'corr'$name1'-'$name3'.nc'
c23=$dir'corr'$name2'-'$name3'.nc'
pc12=$dir'pcorr'$name1'-'$name2'.nc'
pc13=$dir'pcorr'$name1'-'$name3'.nc'
pc23=$dir'pcorr'$name2'-'$name3'.nc'
##############################################
## now apply CDO to compute anomalies (here from annual means), each imput files
#############################################
###yearly means
#obs era hadcru h4
cdo  sub ${fin[1]} -timmean ${fin[1]} $h4

##############################################
#fin[2] model 2 h5
cdo  sub ${fin[2]} -timmean ${fin[2]} $h5

##############################################
#fin[3] model 3 h6
cdo  sub ${fin[3]} -timmean ${fin[3]} $h6

##############################################
#corr: era - model 2 
### now lets compeute the correlations acc to GHHBB20
##############################################
cdo timcor $h4 $h5 $c12

##positive part of c12
cdo divc,2 -add $c12 -abs $c12 $pc12
#corr: era - model 3 
cdo timcor $h4 $h6 $c13
##positive part of c13
cdo divc,2 -add $c13 -abs $c13 $pc13
#corr: model 2 model 3
cdo timcor $h5 $h6 $c23
##positive part of c23 
cdo divc,2 -add $c23 -abs $c23 $pc23
##############################################
rm -f $h1 $h
$h2 $h3 $h4 $h5 $h6
##############################################
#nominator partial corr 12.3
cdo mul $pc13 $pc23 $h1
cdo sub $pc12 $h1 $h2
mv $h2 $h1
#denominator  term 1,2
cdo sqrt -addc,1 -mulc,-1 -pow,2 $pc13  $h2
cdo sqrt -addc,1 -mulc,-1 -pow,2 $pc23  $h3
##h3 often used
##ratio partial correlation
cdo div $h1 -mul $h2 $h3 $fout2
##ratio pcorr**2*(1-pcorr13**2)
cdo div -pow,2 $h1  -pow,2 $h3  $fout22
###############
#nominator partial corr 13.2
cdo mul $pc12 $pc23 $h1
cdo sub $pc13 $h1 $h2
mv $h2 $h1
#denominator  term 1,2
cdo sqrt -addc,1 -mulc,-1 -pow,2 $pc12  $h2
#cdo sqrt -addc,1 -mulc,-1 -pow,2 $pc23  $h3
##ratio partial correlation
cdo div $h1 -mul $h2 $h3 $fout3
##ratio pcorr**2*(1-pcorr12**2)
cdo div -pow,2 $h1  -pow,2 $h3  $fout33
#
##############wrong-neg value
#nominator partial corr 23.1 for false redundance and partial correlation
cdo mul $pc12 $pc13 $h1
cdo sub $pc23 $h1 $h2
mv $h2 $h1
#denominator
cdo sqrt -addc,1 -mulc,-1 -pow,2 $pc13 $h2
cdo sqrt -addc,1 -mulc,-1 -pow,2 $pc12 $h4
#partial correlation corr23.1
cdo div $h1 -mul $h2 $h4 $fout4
#false redundance semi partial corr23.1
cdo div -pow,2 $h1 -pow,2 $h2 $fout44
#false redundance semi partial corr32.1
cdo div -pow,2 $h1 -pow,2 $h4 $fout55
##############################################
rm -f $h1 $h2 $h4
##############################################
## multivariate corr
cdo add -pow,2 $pc12 -pow,2 $pc13 $h1
cdo mul -mulc,2 $pc12 -mul $pc13 $pc23 $h2
cdo sub $h1 $h2 $h4
cdo div $h4 -pow,2 $h3 $fout123
###############################################
rm -f $h1 $h2 $h4
###############################################
###shared corr
cdo mul -mulc,2 $pc12 -mul $pc13 $pc23 $h1
cdo mul -pow,2 $pc23 -add -pow,2 $pc12 -pow,2 $pc13 $h2
cdo sub $h1 $h2 $h4
mv $h4 $h1
cdo div $h1 -pow,2 $h3 $fout1213
################################################
 rm -f hlf*.nc
## output *.nc files need to be plotted using a standard plot program
################################################
# rm -f corr*.nc 
# rm -f pcorr*.nc 
 
 
