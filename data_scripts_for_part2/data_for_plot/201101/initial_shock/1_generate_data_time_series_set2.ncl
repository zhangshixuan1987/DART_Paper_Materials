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

  ldatalocal = True
  ldatalocal = False

  if (ldatalocal) then
     ModelOutRoot = "./"
  else
     ModelOutRoot = "/pic/projects/E3SM_DA/zhan391/final_analysis/post_processing/post_processing_data/"
  end if

;;;;;;;;;weight files for ESMF regrid function;;;;;
  wgt_dir  = "./"
  wgt_file = wgt_dir+"SE_NE30_to_FV_192x288.bilinear.nc"

;;;;;;;date strings for the data directory;;;;;;;;
  year         = 2011
  month        = 1
  nday         = 31
  ymstr1       = sprinti("%04d",year)+sprinti("%02d",month)
  ymstr2       = sprinti("%04d",year)+"-"+sprinti("%02d",month)
  xstring      = "" ;"Days since 01 January 2011"

;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  climdir      = ModelOutRoot+"PD_CLIM_5YR_2011-2015_"+sprinti("%02d",month)+"/"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Casdir1      = (/"CLIM","PD_Transpose-AMIP_Hind_d1","PD_Transpose-AMIP_Hind_d2","PD_Transpose-AMIP_Hind_d3","PD_Transpose-AMIP_Hind_d4","PD_Transpose-AMIP_Hind_d5","PD_EDAUVT_Hind_d1","PD_EDAUVT_Hind_d2","PD_EDAUVT_Hind_d3","PD_EDAUVT_Hind_d4","PD_EDAUVT_Hind_d5","REV_PD_EDAUVT_Hind_d1","REV_PD_EDAUVT_Hind_d2","REV_PD_EDAUVT_Hind_d3","REV_PD_EDAUVT_Hind_d4","REV_PD_EDAUVT_Hind_d5"/)
  Casdir1      = Casdir1 + "_"+ymstr1
  ngrps        = dimsizes(Casdir1)
  Plttim       = (/"*cam.h0.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc","*ens*.cam.h2.*.nc"/)

  labels       = (/"CLIM (5yr)","Transpose-AMIP","DART DA without revied IC","DART DA with revied IC"/)
  outexpnam    = (/"CLIM","Transpose-AMIP","DART_org_aerosol_ic","DART_rev_aerosol_ic"/)

 ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"ccn","ccn.1bl","ccn.3bl","cdnum"/)
  VstList      = (/"CCN number concentration at 0.3%","CCN concentration at S=0.1% (1km)","CCN concentration at S=0.1% (3km)","Grid-cell mean column-integrated droplet number concentrations"/)
  UnitList     = (/"# m~S~-3~N~","# m~S~-3~N~","# m~S~-3~N~","# m~S~-2~N~"/)
  PltNums      = (/"", "", "", "", "", "", "", "", "", "", ""/)
  nvars        = dimsizes(VarList)

 ;;;loop the regions and plot the PDF
 load "./sc_cloud_region.ncl"

 do irg = 0,nsubreg-1,1
  mpMinLatF = minlat(irg)
  mpMaxLatF = maxlat(irg)
  mpMinLonF = minlon(irg)
  mpMaxLonF = maxlon(irg)

 ;;;;open netcdf file and save data for the pfigures;;;;;;;
  setfileoption("nc", "Format",  "NetCDF4")
  out_file_name = "5day_hindcast_variation_"+Subreg(irg)+"_ccn.nc"
  replaceSingleChar(out_file_name, " ", "_")
  system("rm " + out_file_name)
  fout = addfile(out_file_name,"c")

 do iv = 0,nvars-1, 1

  Varname = VarList(iv)
  Varunt  = UnitList(iv)
  Varstr  = VstList(iv)

  ;;;read the climatological data;;;;;;;;
  Fnmclim  = systemfunc("cd "+climdir+"/"+"; ls -1 "+Plttim(0))
  Filclim  = addfiles(climdir+"/"+Fnmclim,"r")

  ;;we do not have ccn in climo files;;;;
  climdat  = Filclim[:]->LWCF
  climdat  = climdat@_FillValue

  plotdatmn = new((/4,5/),typeof(climdat)) ;; mean
  plotdatsd = new((/4,5/),typeof(climdat)) ;; standard deviation

  ;;;;;calculate regional mean ;;;;;;
  lat       = Filclim[0]->lat
  lon       = Filclim[0]->lon
  rad       = 4.*atan(1.)/180.    ;
  cost      = lat
  cost      = cos(lat*rad)

  pncreclim      = dim_avg_wgt_n_Wrap(climdat(:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,1)
  plotdatmn(0,:) = dim_avg_n_Wrap(dim_avg_n_Wrap(pncreclim,1),0)
  plotdatsd(0,:) = dim_stddev_n_Wrap(dim_avg_n_Wrap(pncreclim,1),0)

  delete([/lat,lon,rad,cost,pncreclim/])

 do igp = 1, ngrps-1,1

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

  if(Varname.eq."TGCLDLWP".or.Varname.eq."TGCLDIWP")then
    wxcre0300 = wxcre0300 * 1000.0
  end if

  if(Varname.eq."CDNUMC") then
    wxcre0300 = wxcre0300  * 1e-9
  end if

  printVarSummary(wxcre0300)
  Ptimes    = cd_convert(times, "days since "+ymstr2+"-01 00:00")
  datestr   = cd_calendar(Ptimes, -2 )      ; yyyymmdd
  print(datestr)

  ;;zonal mean;;;;;;;
  rad     = 4.*atan(1.)/180.    ;
  cost    = lat
  cost    = cos(lat*rad)
  if(igp.le.5)then
    wncre0300  = dim_avg_wgt_n_Wrap(wxcre0300(:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,1)
  else
    wncre0300  = dim_avg_wgt_n_Wrap(wxcre0300(:,:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,2)
  end if
  ;printVarSummary(wncre0300)
  ;exit

  if(igp.le.5)then
    plotdatmn(1,igp-1) = dim_avg_n_Wrap(dim_avg_n_Wrap(wncre0300,1),0)
    plotdatsd(1,igp-1) = 0.0
  else if (igp.le.10)
    plotdatmn(2,igp-6) = dim_avg_n_Wrap(dim_avg_n_Wrap(dim_avg_n_Wrap(wncre0300,2),1),0)
    plotdatsd(2,igp-6) = dim_stddev_n_Wrap(dim_avg_n_Wrap(dim_avg_n_Wrap(wncre0300,2),1),0)
  else
    plotdatmn(3,igp-11) = dim_avg_n_Wrap(dim_avg_n_Wrap(dim_avg_n_Wrap(wncre0300,2),1),0)
    plotdatsd(3,igp-11) = dim_stddev_n_Wrap(dim_avg_n_Wrap(dim_avg_n_Wrap(wncre0300,2),1),0)
  end if  
  end if 

  delete([/wxcre0300,Filnam1,File1/])
  delete([/wncre0300,times/])

 end do ; end of igp loop

 plotdatmn!0 = "nexps"
 plotdatmn!1 = "ndays"
 plotdatsd!0 = "nexps"
 plotdatsd!1 = "ndays"
 plotdatmn@units = Varunt
 plotdatsd@units = Varunt

 do iexps = 0,dimsizes(outexpnam)-1
   outvarname1 = Varname+"_mean_"+outexpnam(iexps)
   outvarname2 = Varname+"_std_"+outexpnam(iexps)
   fout->$outvarname1$=plotdatmn(iexps,:)
   fout->$outvarname2$=plotdatsd(iexps,:) 
 end do

 end do ; end of var loop

end do ; end of subreg loop

end

