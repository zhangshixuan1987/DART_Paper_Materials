;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;This script used to calculate and plot the zonal mean variables from CAM;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;The terms zonal and meridional are used to describe directions on a globe;;;;;;;
;;;;;;;Zonal means "along a latitudinal circle" or "in the west–east direction";;;;;;;;
;;;;;;;while meridional means "along a longitudinal circle" (a.k.a. meridian) ;;;;;;;;;
;;;;;;;or "in the north–south direction" [2];;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;;;;;;;date strings for the data directory;;;;;;;;
  year         = 2011
  month        = 1
  nday         = 31
  ymstr1       = sprinti("%04d",year)+sprinti("%02d",month)
  ymstr2       = sprinti("%04d",year)+"-"+sprinti("%02d",month)
  xstring      = "" ;"Days since 01 January 2011"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  load "./NCL_experiment_information.ncl"

  Casdir1      = PD_Exp_Names
  Plttim       = Data_File_Key

  Casdir1      = Casdir1 + "_"+ymstr1
  ngrps        = dimsizes(Casdir1)

  OBSTR        = (/"TRMM", "NOAA-HIRS"/)
  OUTSTR       = (/"OBS", "CLIM","Transpose-AMIP","DART-DA"/)

 ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"PRECT","FLUT"/)
  VstList      = (/"Total precipitation","Outgoing longwave radiation (OLR)"/)
  UnitList     = (/"mm day~S~-1~N~","W m~S~-2~N~"/)
  PltNums      = (/"", "", "", "", "", "", "", "", "", "", ""/)
  nvars        = dimsizes(VarList)

 ;;;;open netcdf file and save data for the pfigures;;;;;;;
 ;;;;open netcdf file and save data for the pfigures;;;;;;;
  setfileoption("nc", "Format",  "NetCDF4")
  out_file_name = "EAMv0_hindcast_5day_monthly_mean_variation_OLR_PRECT.nc"
  system("rm " + out_file_name)
  fout = addfile(out_file_name,"c")

 ;;;loop the regions and plot the PDF
 load "./sc_cloud_region.ncl"
  replaceSingleChar(Subreg, " ", "_")

 do irg = 0,nsubreg-1,1
  mpMinLatF = minlat(irg)
  mpMaxLatF = maxlat(irg)
  mpMinLonF = minlon(irg)
  mpMaxLonF = maxlon(irg)

 do iv = 0,nvars-1, 1

  Varname = VarList(iv)
  Varunt  = UnitList(iv)
  Varstr  = VstList(iv)

  ;;;;read the observations;;;;;;;;;;;;;; 
  if (Varname.eq."PRECT")then
   trmmdat0 = systemfunc("cd "+trmmdir+"/"+"; ls -1 "+Plttim(0))
   trmmdat  = trmmdat0(1:)
   Filobs  = addfiles(trmmdir+"/"+trmmdat,"r")
   ListSetType (Filobs, "join")
   Obname  = OBSTR(0)
   obsdat1 = Filobs[:]->precipitation
   lat1    = Filobs[0]->lat
   lon1    = Filobs[0]->lon
   ;;process the daily mean data
   dimx = dimsizes(obsdat1)
   dim1 = dimx(0)
   dim2 = dimx(1)
   dim3 = dimx(2)
   obsdat = new((/dim1/8,dim2,dim3/),typeof(obsdat1))
   do j = 0, dim1/8-1
      obsdat(j,:,:) = dim_avg_n(obsdat1(j*8:(j+1)*8-1,:,:),0) * 24.0
   end do
   obsdat!0   = "time"
   obsdat!1   = "lat"
   obsdat!2   = "lon"
   obsdat&lat = lat1
   obsdat&lon = lon1 
   print(dim1+ " "+dim1/8)
   printVarSummary(obsdat)
   delete([/trmmdat0,trmmdat,obsdat1/])
  else if (Varname.eq."FLUT")then
   olrdat  = olrdir+"olr.day.mean_1.9x2.5.nc"
   Filob1  = addfile(olrdat,"r")
   Obname  = OBSTR(1)
   ;lat1    = Filob1->lat
   ;lon1    = Filob1->lon
   obsdat0 = Filob1->olr
   tmptim  = Filob1->time
   tmptim  = tmptim+1
   ;;note that we should use 2010-12-31 instead of 2011-01-01 for hindcast;;;;;
   obstim  = cd_convert( tmptim, "days since 2010-12-31 00:00")
   indxx   = ind(obstim.ge.1.and.obstim.le.nday)
   ;print(indxx)
   obsdat  = obsdat0(indxx,:,:)
   ;printVarSummary(obsdat)
   delete([/tmptim,obsdat0,obstim,indxx/])
  end if 
  end if 

  ;print(obstim)

  ;;;read the climatological data;;;;;;;;
  Fnmclim  = systemfunc("cd "+climdir+"/"+"; ls -1 "+Plttim(1))
  Filclim  = addfiles(climdir+"/"+Fnmclim,"r")

  if(Varname.eq."PRECT") then
    climdat   = Filclim[:]->PRECC
    climdat   = Filclim[:]->PRECC + Filclim[:]->PRECL
    climdat   = climdat*1000.0 *24.0 *3600.0 ;; mm/day
  else if(Varname.eq."NETCF") then
    climdat   = Filclim[:]->LWCF
    climdat   = Filclim[:]->LWCF + Filclim[:]->SWCF
  else
   climdat    = Filclim[:]->$Varname$
  end if
  end if

  plotdatmn = new((/4,5/),typeof(climdat)) 
  plotdatsd = new((/4,5/),typeof(climdat))
 
  plotdatmn!0 = "nvars"
  plotdatmn!1 = "ndays"
  plotdatsd!0 = "nvars"
  plotdatsd!1 = "ndays"
 
  if(iv .eq.0)
   plotdatmn@long_name = "Total precipitation rate (liq + ice)" ;
   plotdatsd@long_name = "Total precipitation rate (liq + ice)" ;
  else
   plotdatmn@long_name = "Outgoing longwave radiation" ;
   plotdatsd@long_name = "Outgoing longwave radiation" ;
  end if

  ;;;;;calculate regional mean ;;;;;;
  lat       = Filclim[0]->lat
  lon       = Filclim[0]->lon
  rad       = 4.*atan(1.)/180.    ;
  cost      = lat
  cost      = cos(lat*rad)
  pncreobs  = dim_avg_wgt_n_Wrap(obsdat(:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,1)
  plotdatmn(0,:) = (/dim_avg_n_Wrap(dim_avg_n_Wrap(pncreobs,1),0)/)
  plotdatsd(0,:) = 0.0
 
   
  pncreclim      = dim_avg_wgt_n_Wrap(climdat(:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,1)
  plotdatmn(1,:) = (/dim_avg_n_Wrap(dim_avg_n_Wrap(pncreclim,1),0)/)
  plotdatsd(1,:) = (/dim_stddev_n_Wrap(dim_avg_n_Wrap(pncreclim,1),0)/)

  varmean = OUTSTR(0)+"_"+Varname + "_mean_"  +  Subreg(irg)
  varrmse = OUTSTR(0)+"_"+Varname + "_stddev_"+  Subreg(irg)
  fout->$varmean$ = plotdatmn(0,:)
  fout->$varrmse$ = plotdatsd(0,:)

  varmean = OUTSTR(1)+"_"+Varname + "_mean_"  +  Subreg(irg)
  varrmse = OUTSTR(1)+"_"+Varname + "_stddev_"+  Subreg(irg)
  fout->$varmean$ = plotdatmn(1,:)
  fout->$varrmse$ = plotdatsd(1,:)

  delete([/lat,lon,rad,cost,pncreobs,pncreclim/])

 do igp = 2, ngrps-1,1

  ;;;;;;;begin to work with the simulations;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  tescase = Casdir1 (igp)
  Filnam1 = systemfunc("cd "+ModelOutRoot+tescase+"/"+"; ls -1 "+Plttim(igp))
  File1   = addfiles(ModelOutRoot+tescase+"/"+Filnam1,"r")
  ListSetType (File1, "join")
  lat       = File1[0]->lat
  lon       = File1[0]->lon
  times     = File1[0]->time

  if(Varname.eq."PRECT") then
    wxcre0300 = File1[:]->PRECC
    wxcre0300 = File1[:]->PRECC + File1[:]->PRECL
    wxcre0300 = wxcre0300*1000.0 *24.0 *3600.0 ;; mm/day
  else if(Varname.eq."NETCF") then
    wxcre0300 = File1[:]->LWCF
    wxcre0300 = File1[:]->LWCF + File1[:]->SWCF
  else
    wxcre0300 = File1[:]->$Varname$
  end if
  end if

  ;printVarSummary(wxcre0300)
  ;printVarSummary(wxcre0300)
  Ptimes    = cd_convert(times, "days since "+ymstr2+"-01 00:00")
  datestr   = cd_calendar(Ptimes, -2 )      ; yyyymmdd

  ;;zonal mean;;;;;;;
  rad     = 4.*atan(1.)/180.    ;
  cost    = lat
  cost    = cos(lat*rad)
  if(igp.le.6)then
    wncre0300  = dim_avg_wgt_n_Wrap(wxcre0300(:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,1)
  else
    wncre0300  = dim_avg_wgt_n_Wrap(wxcre0300(:,:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,2)
  end if
  ;printVarSummary(wncre0300)
  ;exit

  if(igp.le.6)then
    plotdatmn(2,igp-2) = (/dim_avg_n_Wrap(dim_avg_n_Wrap(wncre0300,1),0)/)
    plotdatsd(2,igp-2) = 0.0
  else
    plotdatmn(3,igp-7) = (/dim_avg_n_Wrap(dim_avg_n_Wrap(dim_avg_n_Wrap(wncre0300,2),1),0)/)
    plotdatsd(3,igp-7) = (/dim_stddev_n_Wrap(dim_avg_n_Wrap(dim_avg_n_Wrap(wncre0300,2),1),0)/)
  end if 

  delete([/wxcre0300,Filnam1,File1/])
  delete([/wncre0300,times/])

 end do ; end of igp loop

  varmean = OUTSTR(2)+"_"+Varname + "_mean_"+  Subreg(irg)
  varrmse = OUTSTR(2)+"_"+Varname + "_stddev_"+Subreg(irg)
  fout->$varmean$ = plotdatmn(2,:)
  fout->$varrmse$ = plotdatsd(2,:)

  varmean = OUTSTR(3)+"_"+Varname + "_mean_"+  Subreg(irg)
  varrmse = OUTSTR(3)+"_"+Varname + "_stddev_"+Subreg(irg)
  fout->$varmean$ = plotdatmn(3,:)
  fout->$varrmse$ = plotdatsd(3,:)

 end do ; end of var loop

end do ; end of subreg loop

end

