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
  VarList      = (/"NUMLIQ","NUMICE","CCN3","OMEGA500","TH7001000","U10","LHFLX","SHFLX"/)
  VstList      = (/"Integrated liq num", "Integrated ice num", "CCN3","OMEGA500","TH7001000","U10","LHFLX","SHFLX"/)
  UnitList     = (/"x10~S~6~N~ kg~S~-1~N~","x10~S~3~N~ kg~S~-1~N~","# cm~S~-3~N~","hPa day~S~-1~N~", "K","m s~S~-1~N~","W m~S~-2~N~", "W m~S~-2~N~"/)
  PltNums      = (/"", "", "", "", "", "", "", "", "", "", ""/)
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

  if(Varname.eq."NUMLIQ".or.Varname.eq."NUMICE".or.Varname.eq."CCN3") then

    xpivar = File0[:]->$Varname$(:,:,:,{MinLat:MaxLat},{MinLon:MaxLon})
    xpdvar = File1[:]->$Varname$(:,:,:,{MinLat:MaxLat},{MinLon:MaxLon})

   else

    xpivar = File0[:]->$Varname$(:,:,{MinLat:MaxLat},{MinLon:MaxLon})
    xpdvar = File1[:]->$Varname$(:,:,{MinLat:MaxLat},{MinLon:MaxLon})

  end if

  if(Varname.eq."NUMLIQ")then
    opivar  = dim_sum_n_Wrap(xpivar,2)
    opdvar  = dim_sum_n_Wrap(xpdvar,2)
    opivar  = opivar*1e-6
    opdvar  = opdvar*1e-6
  else if (Varname.eq."NUMICE")then
    opivar  = dim_sum_n_Wrap(xpivar,2)
    opdvar  = dim_sum_n_Wrap(xpdvar,2)
    opivar  = opivar*1e-3
    opdvar  = opdvar*1e-3
  else if (Varname.eq."CCN3")then
    opivar  = xpivar(:,:,{900},:,:)
    opdvar  = xpdvar(:,:,{900},:,:)
  else
    opivar  = xpivar
    opdvar  = xpdvar
  end if
  end if
  end if
  delete([/xpivar,xpdvar/])

  if (Varname .eq. "TS") then
   opivar = opivar - 273.15
   opdvar = opdvar - 273.15
  end if

  if (Varname .eq. "OMEGA500") then
   opivar = opivar*24.0*3600.0/100.0
   opdvar = opdvar*24.0*3600.0/100.0
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

;;;processe the zonal mean data;;;;
 if (plot_zonal_mean) then
  nlat = dimsizes(lat)
  plotdiff      = new((/3,nlat/),typeof(pivar))
  vardiff       = pdvar - pivar
  zmean         = dim_avg_n_Wrap(vardiff,2)
  zrmsd         = sqrt(dim_variance_n_Wrap(zmean,0))
  plotdiff(0,:) = dim_avg_n_Wrap(zmean,0)
  plotdiff(1,:) = plotdiff(0,:) - zrmsd
  plotdiff(2,:) = plotdiff(0,:) + zrmsd
 end if

 delete([/pdvar,pivar/])

;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots
    res                      = True              ; Plot modes desired.
    res@gsnDraw              = False
    res@gsnFrame             = False
    res@gsnMaximize          = False              ; Maximize plot

    res@tmXTOn               = False
    res@tmYROn               = False
    res@tiMainFontHeightF    = 0.022
    res@tmYLLabelFontHeightF = 0.022
    res@tmXBLabelFontHeightF = 0.022

    mpres                    = res

    res@lbLabelFontHeightF   = 0.018
    res@gsnStringFontHeightF = 0.040

    res@cnFillOn             = True              ; color plot desired
   ;res@cnFillPalette        = "ViBlGrWhYeOrRe";"testcmap" ;"NCV_jaisnd";"temp_19lev"
    res@cnLinesOn            = False             ; turn off contour lines
    res@cnLineLabelsOn       = False             ; turn off contour labels
   ;res@cnFillMode           = "RasterFill"      ; turn raster on
    res@cnMissingValFillColor = "White"
    res@lbLabelBarOn            = False      ; Will turn on in panel later
    res@pmLabelBarParallelPosF  = 0.61 
    res@pmLabelBarOrthogonalPosF= 0.15
    res@lbOrientation           = "Horizontal";"vertical"        ; vertical label bar
    res@pmLabelBarHeightF       = 0.2 ;0.65
    res@pmLabelBarWidthF        = 0.75 ;0.1
    ;res@lbTitleString           = "" ;Varunt;Varstr+ " ("+Varunt+")";
    ;res@lbTitlePosition         = "Right"                           ; title location
    ;res@lbTitleDirection        = "Across"                          ; letter angle
    ;res@lbTitleAngleF           = 90.                               ; title angle
    ;res@lbTitleFontHeightF      = 0.022                              ; font height


    leftstr                  = "" ;"Surface Temperature ("+ts@units+")"
    res@gsnLeftString        = "" ; leftstr ;var_name0    ; long_name is too long!
    res@gsnRightString       = "" ;" ("+Varunt+")";""
 ;  res@tiMaingString        = "Annual Mean Response to Present-day climate"

;---Control appearance of map.
    ;mpres@gsnMajorLatSpacing     = 30
    ;mpres@gsnMajorLonSpacing     = 45
    ;mpres@gsnMinorLatSpacing     = 15
    ;mpres@gsnMinorLonSpacing     = 15
    mpres@mpProjection           = "Robinson"       ; choose projection
    mpres@mpLabelsOn             = False
    mpres@mpPerimOn              = False
    mpres@mpFillOn               = False
    mpres@mpGeophysicalLineColor = lndcolor  ; color of cont. outlines
    mpres@mpGeophysicalLineThicknessF = 1.0          ; thickness of outlines
   mpres@mpOutlineOn            = True
   mpres@mpOutlineDrawOrder     = "PostDraw"
   mpres@mpFillDrawOrder        = "Predraw"
   mpres@mpGridAndLimbOn        = True
   mpres@mpGridLatSpacingF      = 90.0
   mpres@mpGridLonSpacingF      = 180.0
   mpres@mpGridLineThicknessF   = 3.0
   mpres@mpGridAndLimbDrawOrder="PreDraw"
   mpres@mpMinLonF              = 0  ;-180.
   mpres@mpMaxLonF              = 360;180.
    mpres@mpCenterLonF           = 180 ;150.0
;   mpres@mpCenterLatF           = -90.     ; This is necessary to get the correct map
;   mpres@mpOceanFillColor       = "lightskyblue1"
;   mpres@mpLandFillColor        = "gray33"

    ;if (igp.eq.0) then
    ; mpres@tmYLLabelsOn           = True
    ; mpres@tmYLOn                 = True
    ; plot(igp) = gsn_csm_map(wks1,mpres)
    ;else if (igp.lt.ngrps-1) then
    ; mpres@tmYLLabelsOn           = False
    ; mpres@tmYLOn                 = False
    ; plot(igp) = gsn_csm_map(wks1,mpres)
    ;else
    ; mpres@tmYLLabelsOn           = False
    ; mpres@tmYLOn                 = False
    ; mpres@tmYROn                 = True
     plot(igp) = gsn_csm_map(wks1,mpres)
    ;end if
    ;end if

    mpres@tmYLLabelsOn           = True
    mpres@tmYLOn                 = True
    plot(igp) = gsn_csm_map(wks1,mpres)

;---Resources for plotting original data
;;;---Resources for plotting original data
  if(plotcntl)then
    plot0(igp)                = gsn_csm_map(wks1,mpres)
    res1=res
    res1@gsnAddCyclic         = True
    res1@cnFillPalette                   = ocname
   ;res1@cnLevelSelectionMode            = "ManualLevels"
   ;res1@cnMinLevelValF                  = mnmxint(0)
   ;res1@cnMaxLevelValF                  = mnmxint(1)
   ;res1@cnLevelSpacingF                 = mnmxint(2)
    res1@cnLevelSelectionMode           = "ExplicitLevels"
    res1@cnLevels                       := orglev
   ;res1@cnFillColors                   := orgcolors
    res1@lbBoxLinesOn                   = True
   ;res1@lbBoxSeparatorLinesOn          = False
   ;res1@lbLabelStride                  = 15
    res1@gsnAddCyclic                   = True
    res1@tiMainString                   = Figstr + LabList0(igp)
    res1@gsnLeftString                  = ""
    res1@gsnLeftStringOrthogonalPosF    = 0.02
   ;res1@gsnLeftStringParallelPosF      = 0.05
    res1@gsnRightString                 = "";
    res1@gsnRightStringOrthogonalPosF   = 0.02
   ;res1@gsnRightStringParallelPosF     = 0.9
    res1@gsnCenterString                 = "Global mean: "+ mpistr
    res1@gsnCenterStringOrthogonalPosF     = 0.04
    res1@cnLinesOn                      = plot_contour
    res1@cnLineLabelsOn                 = False
    res1@cnInfoLabelOn                  = False
    res1@cnLineLabelDensityF            = 2.0
    res1@cnLineLabelFontHeightF         = 0.018
    res1@cnLineLabelBackgroundColor     = -1
    res1@gsnContourLineThicknessesScale = 1.0
    res1@cnLineThicknessF               = 1.0
    res1@cnLineColor                    = "Black"
    res1@gsnContourZeroLineThicknessF   = 2.
    res1@gsnContourNegLineDashPattern   = 1
    plot_org1  = gsn_csm_contour(wks1,mpivar,res1)

    resb                   = True ; polyline mods desired
    resb@gsLineColor       = "black" ; color of lines
    resb@gsLineThicknessF  = 8.0 ; thickness of lines
    txres                  =  True
    txres@txFontHeightF    = 0.014
    txres@txFontColor      = resb@gsLineColor
    txres@txFontThicknessF = 10 ;resb@gsLineThicknessF
    txres@txJust           = "CenterCenter"
    do irg = 0,nsubreg-1
     if (irg.eq.0)then
      reg1=new((/4,nsubreg/),graphic)
      reg2=new((/nsubreg/),graphic)
     end if
     yptsb = (/maxlat(irg), minlat(irg), minlat(irg), maxlat(irg), maxlat(irg)/) ;define lat points for each line
     xptsb = (/minlon(irg), minlon(irg), maxlon(irg), maxlon(irg), minlon(irg)/) ; define lon points for each line
     if(irg.eq.nsubreg-1)then
      resb@gsLineColor = "Purple" ; color of lines
     else
      resb@gsLineColor = "Black" ; color of lines
     end if
     ;do i = 0,3
     ; reg1(i,irg)=gsn_add_polyline(wks1,plot_org1,xptsb(i:i+1),yptsb(i:i+1),resb)
     ;end do
     ;if(irg.lt.nsubreg-1)then
     ;  reg2(irg) = gsn_add_text(wks1,plot_org1,Subreg(irg),0.5*(maxlon(irg)+minlon(irg)),0.5*(maxlat(irg)+minlat(irg)),txres)
     ;end if
     end do
    overlay(plot0(igp),plot_org1)

    delete([/res1/])
   end if 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    res2=res
    res2@gsnAddCyclic                   = True
   ;res2@cnFillPalette                  = dcname
   ;res2@cnLevelSelectionMode          = "ManualLevels"
   ;res2@cnMinLevelValF                = mnmxint(0)
   ;res2@cnMaxLevelValF                = mnmxint(1)
   ;res2@cnLevelSpacingF               = mnmxint(2)
    res2@cnLevelSelectionMode           = "ExplicitLevels"
    res2@cnLevels                       := diffgrp1
    res2@cnFillColors                   := colorgroup1
    res2@lbBoxLinesOn                   = True
   ;res2@lbBoxSeparatorLinesOn          = False
   ;res2@lbLabelStride                  = 15
    res2@cnLinesOn                      = False             ; turn off contour lines
    res2@cnLineLabelsOn                 = False            ; turn off contour labels
    res2@cnInfoLabelOn                  = False
    res2@tiMainString                   = Figstr + LabList(igp) ;"PD300 - CNTL"
    res2@gsnLeftString                  = "" ;Varstr +"" + "  ("+ Varunt + ")" ;Groups(igp) + " ~F19~:~N~~F~ " + Groups(0)
    res2@gsnLeftStringOrthogonalPosF     = 0.04
    ;res2@gsnLeftStringParallelPosF      = 0.05 
    res2@gsnRightString                  = "" ;
    res2@gsnRightStringOrthogonalPosF    = 0.04
    ;res2@gsnRightStringParallelPosF     = 0.9
    res2@gsnCenterString                 = "Global mean: "+ mdfstr 
    res2@gsnCenterStringOrthogonalPosF     = 0.04
    if(plot_ttest_mskout) then
     plot_rgd1                  = gsn_csm_contour(wks1,v1mnts1,res2)
    else
     plot_rgd1                  = gsn_csm_contour(wks1,mpdmpi,res2)  
    end if 

    if(plot_contour)
     res21 = res2
     res21@gsnLeftString                  = ""
     res21@gsnRightString                 = ""
     res21@gsnCenterString                = ""
     res21@cnFillOn                       = False
     res21@cnLinesOn                      = True
     res21@cnLineLabelsOn                 = False            ; turn off contour labels
     res21@cnInfoLabelOn                  = False
     res21@cnLineLabelDensityF            = 2.0
     res21@cnLineLabelFontHeightF         = 0.018
     res21@cnLineLabelBackgroundColor     = -1
     res21@gsnContourLineThicknessesScale = 1.0
     res21@cnLineThicknessF               = 1.0
     res21@cnLineColor                    = "Black"
     res21@gsnContourZeroLineThicknessF   = 2.
     res21@gsnContourNegLineDashPattern   = 1
     plot_cont1                  = gsn_csm_contour(wks1,mpdmpi,res21)
     overlay(plot_rgd1,plot_cont1)
     delete([/res21/])
    end if
    overlay(plot(igp),plot_rgd1)
    delete([/res2/])

    ;---Add test shading to plot
    if(plot_ttest_hatch.or.plot_ttest_hatrv)then
     res3=res
     res3@cnFillOn              = True     ; color plot desired
     res3@lbLabelBarOn          = False    ; turn off contour labels
     res3@cnLinesOn             = False    ; turn off contour lines
     res3@cnLineLabelsOn        = False    ; turn off contour labels
     res3@cnMissingValFillColor = -1
     res3@cnMonoFillColor       = True     ; default color is fground [black]
     res3@cnMonoFillPattern     = True     ; want multiple patterns
     res3@cnMonoFillScale       = True     ; want patterns w/ diff densities
     res3@cnFillColor           = FillColor
     res3@cnFillPattern         = FillPattern
     res3@cnFillScaleF          = FillScaleF
     res3@cnFillDotSizeF        = FillDotSizeF
     res3@cnFillOpacityF        = FillOpacityF
     res3@tiMainString          = "" ;label
     res3@cnInfoLabelOn         = False
     str=unique_string("tmp1")
    ;wrf_smooth_2d(v1mnts1,3)
     plot@str                = gsn_csm_contour(wks1,v1mnts1,res3)
     overlay(plot(igp),plot@str)
     delete([/res3/])
    end if

    tres                      = True                ; text mods desired
    tres@txFontHeightF        = 0.020               ; make smaller
    txid1 = gsn_create_text(wks1, Varunt, tres)
    txid2 = gsn_create_text(wks1, Varunt, tres)
    txid3 = gsn_create_text(wks1, "%", tres)
    amres = True
    amres@amParallelPosF   =  0.43    ; This is the right edge of the plot.
    amres@amOrthogonalPosF = -0.5    ; This is the bottom edge of the plot.
    ;annoid1 = gsn_add_annotation(mpid1, txid1, amres)
    ;annoid2 = gsn_add_annotation(mpid2, txid2, amres)
    ;annoid3 = gsn_add_annotation(mpid3, txid3, amres)
    delete([/res/])
 end do ;end of experiment group loop 

;---Draw both plots in a panel
    pnres                         = True
    pnres@gsnMaximize             = True
    pnres@gsnPanelLabelBar        = True
    pnres@gsnPanelMainString      = "";Varstr; "Surface Temperature ("+ts@units+")"
    pnres@gsnPanelMainFontColor   = "Black"
    pnres@lbOrientation           = "vertical"        ; vertical label bar
    pnres@pmLabelBarHeightF       = 0.12
    pnres@pmLabelBarWidthF        = 0.03
    pnres@gsnPanelMainFontHeightF = 0.022
    pnres@lbLabelFontHeightF      = 0.006               ; make labels smaller
    pnres@pmLabelBarParallelPosF  = -0.005
    pnres@pmLabelBarOrthogonalPosF= 0.005
    pnres@lbTitleString           = Varstr +"" + "  ("+ Varunt + ")" 
    pnres@lbTitlePosition         = "Right"                           ; title location
    pnres@lbTitleDirection        = "Across"                          ; letter angle
    pnres@lbTitleAngleF           = 90.                               ; title angle
    pnres@lbTitleFontHeightF      = 0.006                              ; font height
    pnres@gsnPanelBottom          = 0.05
    pnres@gsnPanelYWhiteSpacePercent = 2

    ;if (plot_zonal_mean) then
    ;  pnres@gsnPanelXF = (/0.05,0.24,0.43,0.495/)    ; Adjust rightmost plots
    ;else
    ;  pnres@gsnPanelXF = (/0.05,0.34,0.63/)    ; Adjust rightmost plots
    ;end if

    pres1  = pnres
    pres1@gsnFrame  = False      ; don't advance frame yet
    pres1@gsnPanelBottom      = 0.4        ; move bottom up from 0.0 to 0.4
    gsn_panel(wks1,plot0,(/1,ngrps/),pres1)

    pres2  = pnres
    pres2@gsnFrame  = False 
   ;pres2@gsnPanelTop         = 0.4        ; draw up to the bdry of upper plot
    pres2@gsnPanelBottom      = 0.1        ; move bottom up so size is 0.3
    gsn_panel(wks1,plot,(/1,ngrps/),pres2)

  ; now advance frame for all plots
    frame(wks1)
   
   delete([/pnres,pres1,pres2/])

end do ; end of var loop
end

