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
  VarList      = (/"UVS"/)
  VstList      = (/"Wind"/)
  UnitList     = (/"m s~S~-1~N~"/)
  PltNums      = (/"", "", "", "", "", "", "", "", "", "", ""/)
  nvars        = dimsizes(VarList)
  prelev      = (/1000.,850.,700.,500.,200./)
  nplev        = dimsizes(prelev)

 ;;; flags to control the plot style
  plotcntl          = True   ; if True, plot the CNTL origianl field on the leftmost panel

  plot_ttest_mskout = False  ; if True, mask the non-significant region as missing values

  plot_ttest_hatch  = True  ; if True, plot the significant region as hatch region

  plot_ttest_hatrv  = False  ; if True, plot the non-significant region as hatch region

  plot_contour      = False   ; if True, plot the contour in the figure

  plot_leftstr      = True   ; if True, the lefadd igure captions as left string

  plot_msktrop      = False   ; if True, mask out the tropics region [-20,20]

  plot_lndmsk       = False   ; if True, mask out the land region

 ;;;these flags control the zonal mean plot
  plot_zonal_mean   = False  ; whether or not plot zonal mean 
  add_fill_line     = False  ; Turn off (on if True) fill color below the zonal mean line 
  add_std_shading   = False ; If true, the grey shading is added for uncertainty of zonal mean
  add_std_line      = False  ; If true, the dash red lines are added for upper and bottom bounds 
                            ; of uncertainty for zonal mean
  add_subreg_box    = False  ; always false

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

 do iplev = 0,nplev-1,1

  MinY = prelev(iplev)

  plotFileLabel = Varname+"_"+MinY
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
  lev       = File0[0]->lev

  ilev = ind_nearest_coord (MinY, lev, 0)
  print(MinY + " " +lev(ilev))

  upxcre0300 = File0[:]->U(:,:,ilev,{MinLat:MaxLat},{MinLon:MaxLon})
  uwxcre0300 = File1[:]->U(:,:,ilev,{MinLat:MaxLat},{MinLon:MaxLon})
  vpxcre0300 = File0[:]->V(:,:,ilev,{MinLat:MaxLat},{MinLon:MaxLon})
  vwxcre0300 = File1[:]->V(:,:,ilev,{MinLat:MaxLat},{MinLon:MaxLon})
  tpxcre0300 = wind_speed(upxcre0300,vpxcre0300)
  twxcre0300 = wind_speed(uwxcre0300,vwxcre0300)

  ;;;calculate monthly mean;;;;;;;;;;;
  upycre0300  = dim_avg_n_Wrap(upxcre0300,1)
  uwycre0300  = dim_avg_n_Wrap(uwxcre0300,1)
  vpycre0300  = dim_avg_n_Wrap(vpxcre0300,1)
  vwycre0300  = dim_avg_n_Wrap(vwxcre0300,1)
  tpycre0300  = dim_avg_n_Wrap(tpxcre0300,1)
  twycre0300  = dim_avg_n_Wrap(twxcre0300,1)

  ;;calculate the rmsd at each grid point
  dimx = dimsizes(upycre0300)
  nsta = dimx(0)*dimx(0)
  upcre0300 = new((/nsta,dimx(1),dimx(2)/),typeof(upycre0300))
  uwcre0300 = new((/nsta,dimx(1),dimx(2)/),typeof(upycre0300))
  vpcre0300 = new((/nsta,dimx(1),dimx(2)/),typeof(upycre0300))
  vwcre0300 = new((/nsta,dimx(1),dimx(2)/),typeof(upycre0300))
  tpcre0300 = new((/nsta,dimx(1),dimx(2)/),typeof(upycre0300))
  twcre0300 = new((/nsta,dimx(1),dimx(2)/),typeof(upycre0300))

  ist = 0
  do ien0 = 0,dimx(0)-1
   do ien1 = 0, dimx(0)-1
    upcre0300(ist,:,:) = upycre0300(ien1,:,:)
    uwcre0300(ist,:,:) = uwycre0300(ien0,:,:)
    vpcre0300(ist,:,:) = vpycre0300(ien1,:,:)
    vwcre0300(ist,:,:) = vwycre0300(ien0,:,:)
    tpcre0300(ist,:,:) = tpycre0300(ien1,:,:)
    twcre0300(ist,:,:) = twycre0300(ien0,:,:)
    ist  = ist +1
   end do
  end do

  upcre0300!0="ncl_join"
  upcre0300!1="lat"
  upcre0300!2="lon"
  copy_VarCoords(upcre0300,uwcre0300)
  copy_VarCoords(upcre0300,vpcre0300)
  copy_VarCoords(upcre0300,vwcre0300)
  copy_VarCoords(upcre0300,tpcre0300)
  copy_VarCoords(upcre0300,twcre0300)

  ;;;;calculate ensmeble mean;;;;
  upncre0300  = dim_avg_n_Wrap(upcre0300,0)
  uwncre0300  = dim_avg_n_Wrap(uwcre0300,0)
  vpncre0300  = dim_avg_n_Wrap(vpcre0300,0)
  vwncre0300  = dim_avg_n_Wrap(vwcre0300,0)
  tpncre0300  = dim_avg_n_Wrap(tpcre0300,0)
  twncre0300  = dim_avg_n_Wrap(twcre0300,0)


  ;;;mask out the data over land
  ;pncre0300 = where(lndmsk.gt.0.0,32766,pncre0300)
  ;wncre0300 = where(lndmsk.gt.0.0,32766,wncre0300)
  ;pncre0300@_FillValue = 32766
  ;wncre0300@_FillValue = 32766
  ;print(num(ismissing(pncre0300)))

 ;;calculate the differences
  uwncredf1  = uwncre0300
  uwncredf1  = uwncre0300 - upncre0300
  vwncredf1  = vwncre0300
  vwncredf1  = vwncre0300 - vpncre0300
  twncredf1  = twncre0300
  twncredf1  = twncre0300 - tpncre0300

  ;;;;calculate the global mean and standard deviation;;;;;;;
  rad       = 4.*atan(1.)/180.    ;
  cost      = cos(lat*rad)       ; cosine weights
  upimean    = wgt_areaave (upcre0300,cost,1.,0)
  updmean    = wgt_areaave (uwcre0300,cost,1.,0)
  updmpim    = wgt_areaave (uwcre0300-upcre0300,cost,1.,0)
  vpimean    = wgt_areaave (vpcre0300,cost,1.,0)
  vpdmean    = wgt_areaave (vwcre0300,cost,1.,0)
  vpdmpim    = wgt_areaave (vwcre0300-vpcre0300,cost,1.,0)
  spimean    = wgt_areaave (tpcre0300,cost,1.,0)
  spdmean    = wgt_areaave (twcre0300,cost,1.,0)
  spdmpim    = wgt_areaave (twcre0300-tpcre0300,cost,1.,0)

  umpistr    = sprintf("%5.2f", dim_avg_n(upimean,0))+" ~F34~1~N~~F~ "+sprintf("%5.2f", dim_stddev_n(upimean,0))
  umpdstr    = sprintf("%5.2f", dim_avg_n(updmean,0))+" ~F34~1~N~~F~ "+sprintf("%5.2f", dim_stddev_n(updmean,0))
  umdfstr    = sprintf("%5.2f", dim_avg_n(updmpim,0))+" ~F34~1~N~~F~ "+sprintf("%5.2f", dim_stddev_n(updmpim,0))

  vmpistr    = sprintf("%5.2f", dim_avg_n(vpimean,0))+" ~F34~1~N~~F~ "+sprintf("%5.2f", dim_stddev_n(vpimean,0))
  vmpdstr    = sprintf("%5.2f", dim_avg_n(vpdmean,0))+" ~F34~1~N~~F~ "+sprintf("%5.2f", dim_stddev_n(vpdmean,0))
  vmdfstr    = sprintf("%5.2f", dim_avg_n(vpdmpim,0))+" ~F34~1~N~~F~ "+sprintf("%5.2f", dim_stddev_n(vpdmpim,0))

  smpistr    = sprintf("%5.2f", dim_avg_n(spimean,0))+" ~F34~1~N~~F~ "+sprintf("%5.2f", dim_stddev_n(spimean,0))
  smpdstr    = sprintf("%5.2f", dim_avg_n(spdmean,0))+" ~F34~1~N~~F~ "+sprintf("%5.2f", dim_stddev_n(spdmean,0))
  smdfstr    = sprintf("%5.2f", dim_avg_n(spdmpim,0))+" ~F34~1~N~~F~ "+sprintf("%5.2f", dim_stddev_n(spdmpim,0))

  print(smpistr)
  print(smpdstr)
  print(smdfstr)

  sigr = 0.05                        ; critical sig lvl for r
  prob = (/twncredf1/)
  prob = sigr
  if (l_studentttest) then
    rad  = 4.*atan(1.)/180.    ;
    wgty = cos(lat*rad)
    xtmp = tpcre0300(lat|:,lon|:,ncl_join|:)
    ytmp = twcre0300(lat|:,lon|:,ncl_join|:)
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
    xtmp     = tpcre0300(lat|:,lon|:,ncl_join|:)
    ytmp     = twcre0300(lat|:,lon|:,ncl_join|:)
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
    xtmp     = tpcre0300(lat|:,lon|:,ncl_join|:)
    ytmp     = twcre0300(lat|:,lon|:,ncl_join|:)
    prob     = kolsm2_n(tpcre0300, twcre0300,0)
    delete([/xtmp,ytmp/])
  end if


  v1mnts1 = twncredf1
  v1mnts1 = where(prob.le.sigr,twncredf1, 32766)
  if(plot_ttest_hatrv) then
    v1mnts1 = twncredf1
    v1mnts1 = where(prob.gt.sigr,twncredf1, 32766)
  end if
  v1mnts1@_FillValue = 32766
  delete([/prob/])

  if(isvar("prob"))then
    delete([/prob/])
  end if 

 if(plot_lndmsk)then
  twncredf1  = where(lndmsk.eq.1,32766,twncredf1)
  tpncre0300 = where(lndmsk.eq.1,32766,tpncre0300)
  twncre0300 = where(lndmsk.eq.1,32766,twncre0300)
  uwncredf1  = where(lndmsk.eq.1,32766,uwncredf1)
  upncre0300 = where(lndmsk.eq.1,32766,upncre0300)
  uwncre0300 = where(lndmsk.eq.1,32766,uwncre0300)
  vwncredf1  = where(lndmsk.eq.1,32766,vwncredf1)
  vpncre0300 = where(lndmsk.eq.1,32766,vpncre0300)
  vwncre0300 = where(lndmsk.eq.1,32766,vwncre0300)
  twncredf1@_FillValue = 32766
  tpncre0300@_FillValue = 32766
  twncre0300@_FillValue = 32766
  uwncredf1@_FillValue = 32766
  upncre0300@_FillValue = 32766
  uwncre0300@_FillValue = 32766
  vwncredf1@_FillValue = 32766
  vpncre0300@_FillValue = 32766
  vwncre0300@_FillValue = 32766
 end if

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

   ; res@cnFillOn             = True              ; color plot desired
   ;;res@cnFillPalette        = "ViBlGrWhYeOrRe";"testcmap" ;"NCV_jaisnd";"temp_19lev"
   ; res@cnLinesOn            = False             ; turn off contour lines
   ; res@cnLineLabelsOn       = False             ; turn off contour labels
   ;;res@cnFillMode           = "RasterFill"      ; turn raster on
   ; res@cnMissingValFillColor = "White"

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

    if (plotcntl) then
     mpres@tmYLLabelsOn           = True
     mpres@tmYLOn                 = True
     plot0(igp)                   = gsn_csm_map(wks1,mpres)
    end if

    res1=res
    res1@gsnAddCyclic                   = True
    res1@cnFillOn                       = True              ; color plot desired
   ;res1@cnFillMode                     = "RasterFill"      ; turn raster on
    res1@cnMissingValFillColor          = "White"
    res1@cnLinesOn                      = True ;plot_contour
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
    res1@lbBoxLinesOn                   = True
   ;res1@lbBoxSeparatorLinesOn          = False
   ;res1@lbLabelStride                  = 15

;---Resources for plotting original data
  if(plotcntl)then
     if(igp.eq.0)then
       minvar                   = floor(min(tpncre0300))
       maxvar                   = ceil(max(tpncre0300))
       maxLev                   = 16
       mnmxint                  = nice_mnmxintvl(minvar,maxvar,maxLev, False)
     end if
    res11=res1
    res11@cnFillPalette                   = ocname
    res11@cnLevelSelectionMode            = "ManualLevels"
    res11@cnMinLevelValF                  = mnmxint(0)
    res11@cnMaxLevelValF                  = mnmxint(1)
    res11@cnLevelSpacingF                 = mnmxint(2)
   ;res11@cnLevelSelectionMode            = "ExplicitLevels"
   ;res11@cnLevels                       := orglev
   ;res11@cnFillColors                   := orgcolors
    res11@tiMainString                   = Figstr + LabList0(igp)
    res11@gsnLeftString                  = ""
    res11@gsnLeftStringOrthogonalPosF    = 0.02
   ;res11@gsnLeftStringParallelPosF      = 0.05
    res11@gsnRightString                 = "";
    res11@gsnRightStringOrthogonalPosF   = 0.02
   ;res11@gsnRightStringParallelPosF     = 0.9
    res11@gsnCenterString                 = "Global mean: "+ smpistr
    res11@gsnCenterStringOrthogonalPosF     = 0.04
    plot_org1                            = gsn_csm_contour(wks1,tpncre0300,res11)
    overlay(plot0(igp),plot_org1)
    delete([/res11/])
   end if 

    if(igp.eq.0)
     tmpavg                               = avg(abs(ndtooned(twncredf1)))
     xminvar                              = -ceil(tmpavg*1.5)
     xmaxvar                              =  ceil(tmpavg*1.5)
     xmaxLev                              = 9
     xmnmxint                             = nice_mnmxintvl(xminvar,xmaxvar,xmaxLev, False)
    end if   

    res12 = res1
    res12@cnLinesOn                       = plot_contour
    res12@cnFillPalette                   = dcname
   ;res12@cnLevelSelectionMode            = "ManualLevels"
   ;res12@cnMinLevelValF                  = xmnmxint(0)
   ;res12@cnMaxLevelValF                  = xmnmxint(1)
   ;res12@cnLevelSpacingF                 = xmnmxint(2)
    res12@cnLevelSelectionMode            = "ExplicitLevels"
    res12@cnLevels                        = difflevs
   ;res12@cnFillColors                    = orgcolors
    res12@tiMainString                    = LabList(igp) ;Groups(igp)+ " ~F19~:~N~~F~ "+ Groups(0)
    res12@gsnLeftString                   = "" ;Varstr + "  ("+ Varunt + ")"
    res12@gsnLeftStringOrthogonalPosF     = 0.02
   ;res12@gsnLeftStringParallelPosF       = 0.05
    res12@gsnCenterString                 = "Global mean: "+ smdfstr
    res12@gsnCenterStringOrthogonalPosF   = 0.04
    res12@gsnRightString                  = "" ;Varstr + "  ("+ Varunt + ")"
    res12@gsnRightStringOrthogonalPosF    = 0.02
   ;res12@gsnRightStringParallelPosF      = 0.9
    plot_rgd1                             = gsn_csm_contour(wks1,twncredf1,res12)
    overlay(plot(igp),plot_rgd1)

 ;;set vector;;;;;;;;
    res_vc                            = res
    res_vc@vcGlyphStyle               = "LineArrow"
    res_vc@vcLineArrowThicknessF      = 3
    res_vc@vcMinDistanceF             = 0.03
    res_vc@vcRefLengthF               = 0.05
  ;wind barb resources don't apply
  ;res_vc@vcGlyphStyle                = "WindBarb"
  ;res_vc@vcWindBarbLineThicknessF    = 5
  ;res_vc@vcWindBarbColor             = "Gray40"
    res_vc@vcRefAnnoOn                = True
    res_vc@vcRefAnnoSide              = "Top"
    res_vc@vcRefAnnoString2On         = False
    res_vc@vcRefAnnoPerimOn           = False
    res_vc@vcRefAnnoFontHeightF       = 0.014
    res_vc@vcRefAnnoOrthogonalPosF    = 0.02
    res_vc@vcRefAnnoParallelPosF      = 0.999
    res_vc@vcRefAnnoBackgroundColor   = "White" ;"Purple"
    res_vc@vcVectorDrawOrder          = "PostDraw"
    res_vc@gsnRightString             = "" ;"Wind"

    if (plotcntl) then
     res_vc1                          = res_vc
     res_vc1@vcRefMagnitudeF          = refvec1
     res_vc1@vcRefAnnoString1         = sprintf("%3.1f",refvec1) ;"1.0"
     plot_vec1  = gsn_csm_vector(wks1,upncre0300,vpncre0300,res_vc1)
     overlay(plot0(igp),plot_vec1)
    end if


    res_vc2                           = res_vc
    res_vc2@vcRefMagnitudeF           =  refvec2
    res_vc2@vcRefAnnoString1          =  sprintf("%3.1f",refvec2) ;"1.0"
    res_vc2@vcLineArrowThicknessF     = 3
    res_vc2@vcMinDistanceF            = 0.018
    res_vc2@vcRefLengthF              = 0.05
    plot_vec2  = gsn_csm_vector(wks1,uwncredf1,vwncredf1,res_vc2)
    overlay(plot(igp),plot_vec2)

    ;;;add a box to indicate the Sc deck
    if (add_subreg_box)then
      resc                   = True ; polyline mods desired
      resc@gsLineColor       = "black" ; color of lines
      resc@gsLineThicknessF  = 5.0 ; thickness of lines
      txres1                  =  True
      txres1@txFontHeightF    = 0.014
      txres1@txFontColor      = resc@gsLineColor
      txres1@txFontThicknessF = 10 ;resb@gsLineThicknessF
      txres1@txJust           = "CenterCenter"
      do irg = 0,nsubreg-1
       if (irg.eq.0.and.iv.eq.0)then
        reg3=new((/4,nsubreg,nvars/),graphic)
        reg4=new((/nsubreg,nvars/),graphic)
       end if
       yptsc = (/maxlat(irg), minlat(irg), minlat(irg), maxlat(irg), maxlat(irg)/) ;define lat points for each line
       xptsc = (/minlon(irg), minlon(irg), maxlon(irg), maxlon(irg), minlon(irg)/) ; define lon points for each line
       if(irg.eq.nsubreg-1)then
        resc@gsLineColor = "Purple" ; color of lines
       else
        resc@gsLineColor = "Black" ; color of lines
       end if
       ;do i = 0,3
       ; reg3(i,irg,iv)=gsn_add_polyline(wks1,plot(igp),xptsc(i:i+1),yptsc(i:i+1),resc)
       ;end do
       ;if(irg.lt.nsubreg-1)then
       ; reg4(irg,iv) = gsn_add_text(wks1,plot(igp),Subreg(irg),0.5*(maxlon(irg)+minlon(irg)),0.5*(maxlat(irg)+minlat(irg)),txres1)
       ;end if
      end do
    end if

    ;;;mark the significance test
    res3=res
    res3@cnFillOn              = True     ; color plot desired
    res3@lbLabelBarOn          = False    ; turn off contour labels
    res3@cnLinesOn             = False    ; turn off contour lines
    res3@cnLineLabelsOn        = False    ; turn off contour labels
    res3@cnMissingValFillColor = -1
    res3@cnMonoFillColor       = True     ; default color is fground [black]
    res3@cnMonoFillPattern     = True     ; want multiple patterns
    res3@cnMonoFillScale       = True     ; want patterns w/ diff densities
    res3@cnFillColor           = FillColor1
    res3@cnFillPattern         = FillPattern1
    res3@cnFillScaleF          = FillScaleF1
    res3@cnFillDotSizeF        = FillDotSizeF1
    res3@cnFillOpacityF        = FillOpacityF1
    res3@tiMainString          = "" ;label
    res3@cnInfoLabelOn         = False
    str=unique_string("tmp1")
    plot@str   = gsn_csm_contour(wks1,v1mnts1,res3)
    overlay(plot(igp),plot@str)
    delete([/res3/])

    delete([/res/])
    delete([/mpres/])

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

 end do ; iplev loop

end do ; end of var loop
end

