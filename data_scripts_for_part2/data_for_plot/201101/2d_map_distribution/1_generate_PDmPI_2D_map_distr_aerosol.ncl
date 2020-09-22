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

;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  Regions   = (/"Global"/)
  nregs     = dimsizes(Regions)
  MinLat    = -90.
  MaxLat    =  90.
  MinLon    =   0.
  MaxLon    = 360.

;;;;;;;date strings for the data directory;;;;;;;;
  anlyyyymm    = "201101"

;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  Casdir1      = (/"PI_ENSNDG_ERA5_Hind_d0","PI_EDAUVT_Hind_d0","PI_EDAUVT_Hind_d1","PI_EDAUVT_Hind_d2","PI_EDAUVT_Hind_d5"/)
  Casdir2      = (/"PD_ENSNDG_ERA5_Hind_d0","PD_EDAUVT_Hind_d0","PD_EDAUVT_Hind_d1","PD_EDAUVT_Hind_d2","PD_EDAUVT_Hind_d5"/)
  Casdir1      = Casdir1 + "_"+anlyyyymm
  Casdir2      = Casdir2 + "_"+anlyyyymm
  Groups       = (/"ENSNDG_ERA5","EDAUVT_Hind_d0", "EDAUVT_Hind_d1","EDAUVT_Hind_d2","EDAUVT_Hind_d5"/)
  ngrps        = dimsizes(Groups)


  LabList0     = (/"PI (ENSNDG_ERA5)", "PI (EDAUVT_Hind_d0)", "PI (EDAUVT_Hind_d1)", "PI (EDAUVT_Hind_d2)", "PI (EDAUVT_Hind_d5)"/)
  LabList      = (/"PD ~F19~:~N~~F~ PI (ENSNDG_ERA5)", "PD ~F19~:~N~~F~ PI (EDAUVT_Hind_d0)", "PD ~F19~:~N~~F~ PI (EDAUVT_Hind_d1)", "PD ~F19~:~N~~F~ PI (EDAUVT_Hind_d2)", "PD ~F19~:~N~~F~ PI (EDAUVT_Hind_d5)"/)

;;;;;data source to be plotted (e.g. annual mean, seasonal mean, montly mean etc.)
  Plttim       = (/"*ens*.cam.h0"/)
  nptim        = dimsizes(Plttim)

  plot         = new(ngrps,graphic)
  plot0        = new(ngrps,graphic) 

 ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"AODVIS","AODALL","BURDEN1","BURDEN2","BURDEN3"/)
  VstList      = (/"AODVIS","AODALL","BURDEN1","BURDEN2","BURDEN3"/)
  VnmList      = (/"AODVIS","AODALL","BURDEN1","BURDEN2","BURDEN3"/)
  UnitList     = (/"unitless","unitless","10~S~-5~N~ kg m~S~-2~N~","10~S~-7~N~ kg m~S~-2~N~","10~S~-5~N~ kg m~S~-2~N~"/)
  PltNums      = (/"", "", "", "", "", ""/)
  nvars        = dimsizes(VarList)

 ;;; flags to control the plot style
  plotcntl          = True   ; if True, plot the CNTL origianl field on the leftmost panel

  plot_ttest_mskout = False  ; if True, mask the non-significant region as missing values

  plot_ttest_hatch  = True  ; if True, plot the significant region as hatch region

  plot_ttest_hatrv  = False  ; if True, plot the non-significant region as hatch region

  plot_contour      = False   ; if True, plot the contour in the figure

  plot_leftstr      = True   ; if True, the lefadd igure captions as left string

  plot_msktrop      = False   ; if True, mask out the tropics region [-20,20]

 ;;;these flags control the zonal mean plot
  plot_zonal_mean   = False  ; whether or not plot zonal mean 
  add_fill_line     = False  ; Turn off (on if True) fill color below the zonal mean line 
  add_std_shading   = False ; If true, the grey shading is added for uncertainty of zonal mean
  add_std_line      = False  ; If true, the dash red lines are added for upper and bottom bounds 
                            ; of uncertainty for zonal mean

 ;;color for the map boundary line
  lndcolor = "Grey28"

 ;;flags to perform significant test;;;;;;;;
  l_studentttest    = False ; True if perform student-t test
  l_pairedttest     = True  ; True if perform parired-t test
  l_kstest          = False  ; True if perform K-S test, see https://www.ncl.ucar.edu/Document/Functions/Built-in/kolsm2_n.shtml

 ;;;;open netcdf file and save data for the pfigures;;;;;;;
  setfileoption("nc", "Format",  "NetCDF4")
  out_file_name = "5day_hindcast_variation_"+Subreg(irg)+".nc"
  replaceSingleChar(out_file_name, " ", "_")
  system("rm " + out_file_name)
  fout = addfile(out_file_name,"c")

do iv = 0,nvars-1, 1

 Varname = VarList(iv)
 Varunt  = UnitList(iv)
 Varstr  = VstList(iv)

 plotFileLabel = Varname+""
 if (plot_msktrop) then
  plotFileLabel = Varname+"_msktrop"
 end if 
 ;;;;;;;open a wks for plot;;;;;;;;;;;;;;;;;;;
 OUTDir  = "./"
 wtype = "png"
 wtype@wkWidth = 2500
 wtype@wkHeight = 2500 
 ;wtype@wkPaperSize     = "A4"
 ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
 ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  wks1 = gsn_open_wks(wtype,OUTDir+"fig_sensitivity_"+plotFileLabel)

 ;;;set up the plot information;;;;
 load "./var_share_colorbar.ncl"

 do igp = 0, ngrps-1,1

  Figstr  = "" ;PltNums(iv*(ngrps-1)+ igp-1)
  refcase = Casdir1 (igp)
  tescase = Casdir2 (igp)

;;;;;;;begin to work with the simulations;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Filnam0 = systemfunc("cd "+ModelOutRoot+refcase+"/"+"; ls *"+Plttim+"*")
  File0   = addfiles(ModelOutRoot+refcase+"/"+Filnam0,"r")
  Filnam1 = systemfunc("cd "+ModelOutRoot+tescase+"/"+"; ls *"+Plttim+"*")
  File1   = addfiles(ModelOutRoot+tescase+"/"+Filnam1,"r")
  ListSetType (File0, "join")
  ListSetType (File1, "join")

  ;print(Filnam0)
  ;print(Filnam1)

  lat       = File0[0]->lat({MinLat:MaxLat})
  lon       = File0[0]->lon({MinLon:MaxLon})

  opivar = File0[:]->$Varname$(:,:,{MinLat:MaxLat},{MinLon:MaxLon})
  opdvar = File1[:]->$Varname$(:,:,{MinLat:MaxLat},{MinLon:MaxLon})

  if(Varname.eq."BURDEN1" .or.Varname.eq."BURDEN3") then
   opivar = opivar*100000.0  ;; g/m2
   opdvar = opdvar*100000.0
  end if

  if(Varname.eq."BURDEN2") then
   opivar = opivar*10000000.0  ;; g/m2
   opdvar = opdvar*10000000.0
  end if

  printVarSummary(opivar)

  ;;;calculate monthly mean;;;;;;;;;;;
  fpivar  = dim_avg_n_Wrap(opivar,1)
  fpdvar  = dim_avg_n_Wrap(opdvar,1)

  printVarSummary(fpivar)
  print(min(fpivar)+ " "+max(fpivar))
  print(min(fpdvar)+ " "+max(fpdvar))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;20ens for PD x 20ens for PI = 400 combinations for PD - PI calculation;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  dimx = dimsizes(fpivar)
  nsta = dimx(0)*dimx(0)
  pivar = new((/nsta,dimx(1),dimx(2)/),typeof(fpivar))
  pdvar = new((/nsta,dimx(1),dimx(2)/),typeof(fpivar))
  ist = 0
  do ien0 = 0,dimx(0)-1
   do ien1 = 0, dimx(0)-1
    pivar(ist,:,:) = fpivar(ien1,:,:)
    pdvar(ist,:,:) = fpdvar(ien0,:,:)
    ist  = ist +1
   end do
  end do

  pivar!0="ncl_join"
  pivar!1="lat"
  pivar!2="lon"
  pdvar!0="ncl_join"
  pdvar!1="lat"
  pdvar!2="lon"

  pdmpi  = pdvar
  pdmpi  = pdvar -pivar
  ;;;;calculate ensmeble mean;;;;
  mpivar  = dim_avg_n_Wrap(pivar,0)
  mpdvar  = dim_avg_n_Wrap(pdvar,0)
  mpdmpi  = dim_avg_n_Wrap(pdmpi,0)

  ;printVarSummary(opivar)
  printVarSummary(mpdmpi)
  delete([/opivar,opdvar/])
  ;;;mask out the data over land
  ;mpivar = where(lndmsk.gt.0.0,32766,mpivar)
  ;mpdvar = where(lndmsk.gt.0.0,32766,mpdvar)
  ;mpivar@_FillValue = 32766
  ;mpdvar@_FillValue = 32766
  ;print(num(ismissing(mpivar)))

  ;;;;calculate the global mean and standard deviation;;;;;;;
  rad       = 4.*atan(1.)/180.    ;
  cost      = cos(lat*rad)       ; cosine weights
  pimean    = wgt_areaave (pivar,cost,1.,0)
  pdmean    = wgt_areaave (pdvar,cost,1.,0)
  pdmpim    = wgt_areaave (pdmpi,cost,1.,0)
  mpistr    = sprintf("%5.2f", dim_avg_n(pimean,0))+" ~F34~1~N~~F~ "+sprintf("%5.2f", dim_stddev_n(pimean,0))
  mpdstr    = sprintf("%5.2f", dim_avg_n(pdmean,0))+" ~F34~1~N~~F~ "+sprintf("%5.2f", dim_stddev_n(pdmean,0))
  mdfstr    = sprintf("%5.2f", dim_avg_n(pdmpim,0))+" ~F34~1~N~~F~ "+sprintf("%5.2f", dim_stddev_n(pdmpim,0))

  print(mpistr)
  print(mpdstr)
  print(mdfstr)

  sigr = 0.05                        ; critical sig lvl for r
  prob = (/mpdmpi/)
  prob = sigr
  if (l_studentttest) then
    rad  = 4.*atan(1.)/180.    ;
    wgty = cos(lat*rad)
    xtmp = pivar(lat|:,lon|:,ncl_join|:)
    ytmp = pdvar(lat|:,lon|:,ncl_join|:)
    xAve = dim_avg (xtmp)              ; calculate means at each grid point
    yAve = dim_avg (ytmp)
    xVar = dim_variance (xtmp)         ; calculate variances
    yVar = dim_variance (ytmp)
    xEqv    = equiv_sample_size (xtmp, sigr,0)
    yEqv    = equiv_sample_size (ytmp, sigr,0)
    xN      = dim_avg_wgt_n(xEqv, wgty, 1, 0)    ; wgty could be gaussian weights
    yN      = dim_avg_wgt_n(yEqv, wgty, 1, 0)
    iflag   = False                        ; population variance similar
    prob    = ttest(xAve,xVar,xN, yAve,yVar,yN, iflag, False)
    delete([/xtmp,ytmp,xAve,yAve,xVar,yVar,xEqv,yEqv,xN,yN/])
  end if

  if (l_pairedttest) then
    xtmp     = pivar(lat|:,lon|:,ncl_join|:)
    ytmp     = pdvar(lat|:,lon|:,ncl_join|:)
    nexpmembers = dimsizes(xtmp(0,0,:))
    vdiff    = ytmp - xtmp
    diff_avg = dim_avg(vdiff)
    diff_std = dim_stddev(vdiff)
    diff_std@_FillValue = -999.
    allzeros = diff_avg.eq.0. .and. diff_std.eq.0.
    diff_std_tmp = where( .not.allzeros, diff_std, diff_std@_FillValue )
    tval   = where(.not.allzeros, diff_avg*sqrt(1.*nexpmembers)/diff_std_tmp, 0.)
    df     = nexpmembers - 1
    paramA = conform(tval, df/2.0, 0) ; see example 2 at https://www.ncl.ucar.edu/Document/Functions/Built-in/betainc.shtml
    paramB = conform(tval, 0.5, 0)     ; see example 2 at https://www.ncl.ucar.edu/Document/Functions/Built-in/betainc.shtml
    ;printVarSummary(tval)
    ;print(min(paramA) + " "+max(paramA))
    ;print(min(paramB) + " "+max(paramB))
    prob = where( .not.allzeros, betainc( df/(df+tval^2), paramA, paramB), 2. )
    prob = prob*0.5 ; one-sided
    delete([/xtmp,ytmp,nexpmembers,vdiff,diff_avg,diff_std,allzeros,diff_std_tmp,tval,df,paramA,paramB/])
  end if


  if (l_kstest) then
    xtmp     = pivar(lat|:,lon|:,ncl_join|:)
    ytmp     = pdvar(lat|:,lon|:,ncl_join|:)
    prob     = kolsm2_n(pivar, pdvar,0)
    delete([/xtmp,ytmp/])
  end if




  v1mnts1 = mpdmpi 
  v1mnts1 = where(prob.le.sigr,mpdmpi, 32766)

  if(plot_ttest_hatrv) then
    v1mnts1 = mpdmpi
    v1mnts1 = where(prob.gt.sigr,mpdmpi, 32766)
  end if
  v1mnts1@_FillValue = 32766

  if(isvar("prob"))then
    delete([/prob/])
  end if 

 delete([/pdvar,pivar/])

end do ; end of var loop
end

