;*************************************************
; histo_4.ncl
;
; Concepts illustrated:
;   - Drawing a histogram using exact min/max of data
;   - Generating dummy data using "rand"
;   - Drawing X axis labels at a 45 degree angle
;
;************************************************
;
; This file is loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
;************************************************
begin

  ldatalocal = True
  ldatalocal = False

  if (ldatalocal) then
     ModelOutRoot = "./"
  else
     ModelOutRoot = "/pic/projects/E3SM_DA/zhan391/e3sm_dart_NE30/diagnostics/EAM_NE30_Diags_2010-12_fnl/"
  end if

  outdir = "./"

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Casdir       = (/"FV80",  "FV20"/)
  Groups       = (/"EAMv0 (80 members)", "EAMv0 (20 members)"/)
  ngrps        = dimsizes(Groups)
  labels       = Groups

  filname  = "obs_diag_output_6hourly_mean.nc"

  VarNameList = (/"RADIOSONDE_U_WIND_COMPONENT",\
                  "RADIOSONDE_V_WIND_COMPONENT",\
                  "RADIOSONDE_TEMPERATURE",\
                  "RADIOSONDE_SPECIFIC_HUMIDITY"/)
  nvars    = dimsizes(VarNameList)
  subvar   = (/"rmse","bias","Nposs","Nused"/)

  facts    = (/1,1,1e3,1e3/)
  nsubvs   = dimsizes(subvar)

  MinY     = 40.0 ; top level
 
  regions  = (/"Northern Hemisphere", "Southern Hemisphere", "Tropics", "North America"/)
  lonlim1  = (/  0.0,   0.0,   0.0, 235.0/)
  lonlim2  = (/360.0, 360.0, 360.0, 295.0/)
  latlim1  = (/ 20.0, -20.0, -90.0, 25.0/)
  latlim2  = (/ 90.0,  20.0, -20.0, 55.0/)

;;;;;;read the shared information;;;;;;;
  fxx         = addfile(ModelOutRoot+"/"+Casdir(0)+"/"+filname,"r")
  region      = fxx->region
  regnam      = fxx->region_names
  obstypes    = chartostring(fxx->ObservationTypes)
  rank_bins   = fxx->rank_bins
  plevel      = fxx->plevel
  plevel_edg  = fxx->plevel_edges
  timecenters = fxx->time
  timeedges   = fxx->time_bounds
  vNames      = getfilevarnames(fxx)
  copynams    = chartostring(fxx->CopyMetaData)
  ncops       = dimsizes(copynams)
  nregs       = dimsizes(region)
  nlevs       = dimsizes(plevel)
  ntimes      = dimsizes(timecenters)
  ;print(timecenters)
  ;print(timeedges)

  ;;;create the time string;;;
  date_str = new(2,string)
  do itim = 0,1
   if (itim.eq.0)then
    tmptim = timecenters(0) ;timeedges(0,itim)
   else
    tmptim = timecenters(ntimes-1) ;timeedges(0,itim)
   end if
   utc_date = cd_calendar(tmptim, 0)
   year   = tointeger(utc_date(:,0))    ; Convert to integer for
   month  = tointeger(utc_date(:,1))    ; use sprinti 
   day    = tointeger(utc_date(:,2))
   hour   = tointeger(utc_date(:,3))
   minute = tointeger(utc_date(:,4))
   second = utc_date(:,5)
   date_str(itim) = sprinti("%0.4i", year)+ \
              "-"+sprinti("%0.2i", month) + \
              "-"+sprinti("%0.2i", day) + \
              "_"+sprinti("%0.2iZ", hour)

  end do
  timrange = "00Z 05 -- 00Z 19 Dec. 2010" ;date_str(0) + "  --  " + date_str(1)
  print(timrange) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  plot        = new(ngrps,graphic)

  do iv = 0,nvars-1,1

  do irg   = 0, nregs-1

  pltreg  = str_squeeze(chartostring(regnam(irg,:)))
  plotlabel =   outdir + VarNameList(iv)+"_"+str_sub_str(str_strip(pltreg)," ","_")+"_profile_"+subvar(0)+ "_"+subvar(1)

  wks = gsn_open_wks("pdf",plotlabel)             ; send graphics to PNG file
  gsn_define_colormap(wks,"temp1")              ; choose colormap
  gsn_define_colormap(wks,"cb_9step")
  ;colors  = (/1,2,6,28,59/)
  ;gsn_merge_colormaps(wks1,"StepSeq25","cb_9step")
  ;colors  = (/1,2,17,85,55/) ;(/1,55,2,17,85/)       ;;(/18,4,9,18,4,9/); (/"palegreen4","orange4","navy"/)
  colors  = (/2,6,28,1,36/)

  markers = (/16, 4, 3, 6, 16/)
  mkszf   = (/0.8, 0.8, 0.8, 0.8/)*2.0
  dashind = (/0,0,0,0,0/)       ;;line dash pattern
  lnthick = (/3,3,3,3,3/)/1.5   ;;line thichness

  varname = VarNameList(iv)+"_VPguess"
  pltdat1 = new((/ngrps,nsubvs,nlevs/),typeof(fxx->$varname$))

  do igp = 0, ngrps-1, 1

  fxx     = addfile(ModelOutRoot+"/"+Casdir(igp)+"/"+filname,"r")
  tempvar = fxx->$varname$(:,:,irg)
  printVarSummary(tempvar)
  ;;;;;;;get the data to be plotted 
  do isv  = 0,nsubvs-1,1
  do icp  = 0,ncops-1,1
   if (str_squeeze(copynams(icp)).eq.subvar(isv))then
     print(copynams(icp) + "  "+subvar(isv))
     pltdat1(igp,isv,:) = tempvar(icp,:)/facts(isv)
   end if   
  end do 
  end do 

  end do 

 ;print(pltdat@_FillValue)
  pltdat1@_FillValue = 32766
 ;print(pltdat)
  xmin1  = floor(min(pltdat1(:,0:1,:)))
  xmax1  = ceil(max(pltdat1(:,0:1,:)))
  xmin2  = floor(min(pltdat1(:,2:3,:)))
  xmax2  = ceil(max(pltdat1(:,2:3,:)))

 do igp = 0, ngrps-1,1

  pltdat = pltdat1(igp,:,:)

  dplev = plevel_edg(1:nlevs)-plevel_edg(0:nlevs-1)
  mdat  = dim_avg_n(pltdat,1)

;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots
  res          = True                   ; plot mods desired
  res@vpHeightF = 0.8
  res@vpWidthF =  0.5
  res@gsnDraw  = False
  res@gsnFrame = False

  FontHeight = 0.024
  res@gsnStringFontHeightF = FontHeight
  res@tmXBLabelFontHeightF = FontHeight
  res@tmYLLabelFontHeightF = FontHeight
  res@tmYRLabelFontHeightF = FontHeight
  res@tiMainFontHeightF    = FontHeight*1.1
  res@tiXAxisFontHeightF   = FontHeight
  res@tiYAxisFontHeightF   = FontHeight

; add a legend
  res@pmLegendDisplayMode    = "Always"              ; turn on legend
  res@pmLegendSide           = "Top"                 ; Change location of
  res@pmLegendParallelPosF   = .75                   ; move units right
  res@pmLegendOrthogonalPosF = -0.35                  ; more neg = down
  res@pmLegendWidthF         = 0.14                  ; Change width and
  res@pmLegendHeightF        = 0.08                  ; height of legend.
  res@lgLabelFontHeightF     = .018                   ; change font height
  res@lgPerimOn              = False                 ; no box around

  res@trYReverse        = True                       ; reverse Y-axis
 ;res@xyYStyle          = "Log"
  res@tmYLMode          = "Explicit"                ; explicit labels
  if (MinY.ge.500)then
   res@tmYLValues        = (/ 1000,950,900,850,800,750,700,650,600,500,400,300,200,100,50,30,10,5,1/)
  else
   res@tmYLValues        = (/ 1000,850,700,600,500,400,300,200,100,10/)
  end if

  if(igp.eq.0)then
    res@tmYLOn           = True
    res@tiYAxisString   = "Pressure (hPa)";"log~B~10~N~(~F8~D~F10~t~F~)"
  else
    res@tmYLOn          = False
    res@tiYAxisString   = ""
  end if  

  res@tmYLLabels        = ""+res@tmYLValues         ; make strings
  res@tmXTOn  = False
  res@trYMaxF = 1000.0
  res@trYMinF = -200.0
  res@trXMaxF = xmax1 ; 4.0
  res@trXMinF = xmin1 ;-4.0

  res@gsnXRefLine             = (/0./)      ; four X reference lines
  res@gsnXRefLineThicknesses  = 1.0
  res@gsnXRefLineDashPatterns = 0
  res@gsnXRefLineColors       = "Grey"

  res@gsnRightString = "";VstList(0)
  res@gsnLeftString  = "" ;Groups(0)

 ; cloud fraction line variable
  res@tmXTOn                  = True
  resT                        = res
  resT@pmLegendDisplayMode    = "Always" ;"Never"
  resT@pmLegendSide           = "Top"                 ; Change location of
  resT@pmLegendParallelPosF   = .22                   ; move units right
  resT@pmLegendOrthogonalPosF = -0.35                ; more neg = down
  resT@pmLegendWidthF         = 0.12                  ; Change width and
  resT@pmLegendHeightF        = 0.08                  ; height of legend.
  resT@trXMaxF                := xmax2 ;0.21
  resT@trXMinF                := xmin2 ;0.0
  resT@gsnRightString         := ""
  resT@gsnLeftString          := ""
  resT@tiXAxisString          := "" ;"Cloud (fraction)";
  resT@xyDashPatterns         := 2                   ; dashed line for 2nd
  resT@xyMarkLineMode         := "Markers" ;"MarkLines"
  resT@xyLineColors           := colors(2:3)
  resT@xyMarkers              := markers(2:3)
  resT@xyMarkerColors         := colors(2:3)
  resT@xyLineThicknesses      := lnthick(2:3)              ; thicker line
  resT@xyMarkerSizes          := 0.015*mkszf(2:3)/1.1 
  resT@xyMarkerThicknesses    := lnthick(2:3)/2
  resT@tiXAxisString          = "# of observations" + " (x 10~S~"+log10(facts(3))+"~N~)";
  resT@tiXAxisOffsetYF        = -0.005
  resT@xyExplicitLegendLabels := "  "+(/"Possible","Assimilated"/) ;subvar(2:3)

  res@xyMarkLineMode         = "MarkLines"
  res@xyLineColors           = colors(0:1)
  res@xyMarkers              = markers(0:1)
  res@xyMarkerColors         = colors(0:1)
  res@xyMarkerSizes          = 0.015*mkszf(0:1)
  res@xyMarkerThicknesses    = lnthick(0:1)
  res@xyDashPatterns         = dashind(0:1)
  res@xyLineThicknesses      = lnthick(0:1)
  res@pmLegendParallelPosF   = .75                   ; move units right
  res@pmLegendOrthogonalPosF = -0.11
  res@pmLegendWidthF         = 0.14                  ; Change width and
  res@pmLegendHeightF        = 0.08                  ; height of legend.
 ; labels for the legend
  labls = subvar(0:1)
  do ii= 0,1
   labls(ii) = subvar(ii) + " ("+sprintf("%5.2f",mdat(ii))+")"
  end do

  res@xyExplicitLegendLabels = "  " + labls ;subvar(0:1)

  res@tiMainString         = Groups(igp) 
  res@tiMainOffsetYF       = 0.02
  res@tiMainFontThicknessF = 3.0

  res@gsnRightString       = "" ;VstList(0)
  res@gsnLeftString        = "" ;Groups(0)
  res@tiXAxisString        = "             RMSE and Bias" + "~C~" \
                             + ""+timrange
  res@tiXAxisOffsetYF = -0.015
  plot(igp)  = gsn_csm_x2y (wks,pltdat(0:1,:),pltdat(2:3,:),plevel,res,resT)   ; create plot

 end do 

;---Draw both plots in a panel
  pnres                         = True
  pnres@gsnMaximize             = False
  pnres@gsnPanelMainString      = "    "+VarNameList(iv) + " ("+ pltreg+")" ;"     "+ pltreg + "~C~"+ VarNameList(iv)
  pnres@gsnPanelMainFontColor   = "Black"
  pnres@gsnPanelMainFontHeightF = 0.020
  pnres@gsnPanelLabelBar        = False
  pnres@gsnPanelBottom          = 0.05
  pnres@gsnPanelYWhiteSpacePercent = 2
  pnres@gsnPanelXF = (/0.15,0.60/)    ; Adjust rightmost plots
  gsn_panel(wks,(/plot/),(/1,ngrps/),pnres)
  delete([/pnres/])

end do

end do 
end
