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
  ldatalocal = True

  if (ldatalocal) then
     ModelOutRoot = "../../data_for_plot/hindcast_initial_shock/"
  else
     ModelOutRoot = "/pic/projects/E3SM_DA/zhan391/final_analysis/post_processing/post_processing_data/"
  end if

  Pltfil   = (/"EAMv0_hindcast_5day_monthly_mean_variation_OLR_PRECT.nc"/)
  ndays    = 5

;;x-aix string 
  xstring      = "" ;"Days since 01 January 2011"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Groups       = (/"OBS","Transpose-AMIP","DART-DA"/)
  ngrps        = dimsizes(Groups)
  labels       = (/"Observations", "Transpose-AMIP","DART DA"/)
 
;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"PRECT","FLUT"/)
  VstList      = (/"Total precipitation","Outgoing longwave radiation (OLR)"/)
  UnitList     = (/"mm day~S~-1~N~","W m~S~-2~N~"/)
  PltNums      = (/"", "", "", "", "", "", "", "", "", "", ""/)
  nvars        = dimsizes(VarList)


;;;;;define arrays to save the plot data;;
  plotdatmn = new((/ngrps,ndays/),double) ;; mean
  plotdatd1 = new((/ngrps,ndays/),double); mean - std
  plotdatd2 = new((/ngrps,ndays/),double) ;; mean + std

 ;;;loop the regions and plot the PDF
 load "./sc_cloud_region.ncl"
 replaceSingleChar(Subreg, " ", "_")

 do irg = 0,nsubreg-1,1

 do iv = 0,nvars-1, 1

  Varname = VarList(iv)
  Varunt  = UnitList(iv)
  Varstr  = VstList(iv)

  if(iv.eq.0)then
    miny = pcpminy
    maxy = pcpmaxy
  else
    miny = olrminy
    maxy = olrmaxy
  end if 

  plotFileLabel = Varname+"_evolution"
 ;;;;;;;open a wks for plot;;;;;;;;;;;;;;;;;;;
  OUTDir  = "./"
  wtype = "png"
  wtype@wkWidth = 2500
  wtype@wkHeight = 2500
  ;wtype@wkPaperSize     = "A4"
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  wks1 = gsn_open_wks(wtype,OUTDir+"fig_day1_to_day5_"+Subrgs(irg)+"_"+plotFileLabel)

  load "./var_share_colorbar.ncl"
 
  file_in = addfile(ModelOutRoot+Pltfil,"r")

 do igp = 0, ngrps-1,1

  varmean = Groups(igp)+"_"+Varname + "_mean_"+  Subreg(irg)
  varrmse = Groups(igp)+"_"+Varname + "_stddev_"+Subreg(irg)
  plotdatmn(igp,:) = file_in->$varmean$ 
  plotdatd1(igp,:) = plotdatmn(igp,:) - file_in->$varrmse$ 
  plotdatd2(igp,:) = plotdatmn(igp,:) + file_in->$varrmse$ 

 end do ; end of igp loop


  xx = ispan(1,ndays,1)
;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots
  res          = True                   ; plot mods desired
  res@vpHeightF = 0.4
  res@vpWidthF =  0.8
  res@gsnDraw  = False
  res@gsnFrame = False

  FontHeight = 0.022
  res@gsnStringFontHeightF = FontHeight*1.0
  res@tmXBLabelFontHeightF = FontHeight
  res@tmYLLabelFontHeightF = FontHeight
  res@tmYRLabelFontHeightF = FontHeight
  res@tiMainFontHeightF    = FontHeight
  res@tiXAxisFontHeightF   = FontHeight
  res@tiYAxisFontHeightF   = FontHeight
  res@tiMainFontThicknessF  = 8.0
  res@tiYAxisFontThicknessF = 5.0
  res@tiXAxisFontThicknessF = 5.0

  res@tmBorderThicknessF    = 1.5 * 4.0
  res@tmXBMajorThicknessF   = 1.5 * 4.0
  res@tmXBMinorThicknessF   = res@tmXBMajorThicknessF/2.0

  res@tmXTOn  = False
  res@trXMinF               = 0.8 ;min(latrgd)
  res@trXMaxF               = 5.2 ;192 ;max(latrgd)
  res@tmXBMode              = "Explicit"
  res@tmXBValues            = ispan(1,5,1)
  res@tmXBLabels            = "" + (/"Day 1", "Day 2", "Day 3", "Day 4", "Day 5"/)
                             ;res@tmXBValues
  ;res@tmXBMinorValues       = ispan(res@trXMinF,res@trXMaxF,1)

  res@trYMinF               = miny(irg);min((/vavg1,vavg2/)) ;miny(iv)
  res@trYMaxF               = maxy(irg) ;max((/vavg1,vavg2/));maxy(iv)
 ;res@tmYLMode              = "Explicit"                ; explicit labels
 ;res@tmYLLabels            = ""+res@tmYLValues         ; make strings

  ;res@gsnXRefLine             = (/5.9/)      ; four X reference lines
  ;res@gsnXRefLineThicknesses  = 1.0
  ;res@gsnXRefLineDashPatterns = 5
  ;res@gsnXRefLineColors       = "Black"

;;;;;;;first figure for PD origional values;;;;;;;;;;;;;;;;;;;;
  res1                         = res
  res1@gsnLeftString           = Varstr ;""
  res1@gsnLeftStringFontColor  = "Black"
  res1@gsnRightString          = "";Figstr ;"(PD)"
  res1@gsnRightStringFontColor = "Black"
  res1@tiMainString            = "" ;mainstr
  res1@xyMarkLineModes         = linemod(:)
  res1@xyLineThicknesses       = lnthick(:)            ; make thicker
  res1@xyDashPatterns          = dashind(:)
  res1@xyMarkerSizes           = mkszf(:)*0.1
  res1@xyMarkerThicknesses     = mkthk
  res1@xyLineColors            = colors(:)
  res1@xyMarkers               = markers(:)
  res1@xyMarkerColors          = colors(:)
  res1@tiXAxisString           = xstring
  res1@tiYAxisString           = Varunt
  plot                         = gsn_csm_xy(wks1,xx,plotdatmn,res1)

  gsres2                       = res                        ; poly res
  gsres2@tmYROn                = False            ; Turn off right tickmarks.
  gsres2@tmYLOn                = False            ; Turn off top tickmarks
  gsres2@tmXTOn                = False            ; Turn off top tickmarks
  gsres2@tmXBOn                = False            ; Turn off top tickmarks
  gsres2@gsnXYFillColors       = colors(2)                ; color chosen
  gsres2@gsnXYFillOpacities    = 0.1
  gsres2@xyLineColors          = (/-1,-1/)
  pltdatx2 = new((/2,5/),typeof(plotdatd1))
  pltdatx2(0,:) = plotdatd1(2,:)
  pltdatx2(1,:) = plotdatd2(2,:)
  dumm2   = gsn_csm_xy (wks1,xx,pltdatx2(:,:),gsres2)
  overlay(plot,dumm2)

;Attach a legend
;;manual legend
   lgres                    = True
   lgres@lgItemType         = "MarkLines"
   lgres@lgLineLabelFontThicknessF= 1.0
 ; lgres@lgLineDashSegLenF  = 0.01
   lgres@lgBoxMinorExtentF  = 0.25
   lgres@lgBoxMajorExtentF  = 0.1
   lgres@lgMonoDashIndex    = False
   lgres@lgMonoLineThickness= False
   lgres@lgMonoMarkerThickness = False
   lgres@lgPerimOn          = True
  ;lgres@lgRightMarginF     = 0.5
  ;lgres@lgLeftMarginF      = 0.5
  ;lgres@lgTopMarginF       = 0.5
  ;lgres@lgBottomtMarginF   = 0.5
   lgres@lgPerimThicknessF  = 1.0

   lgres1 = lgres
   lgres1@vpWidthF           = 0.28           ; width of legend (NDC)
   lgres1@vpHeightF          = 0.14           ; height of legend (NDC)
   lgres1@lgLineColors       = colors(:) ;(/"Black","Black","Black"/)
   lgres1@lgDashIndexes      = dashind(:)
   lgres1@lgLineThicknesses  = lnthick(:)
   lgres1@lgMarkerColors     = colors(:)
   lgres1@lgMarkerIndexes    = markers(:)
   lgres1@lgMarkerThicknesses= mkthk(:)

   label1  = "  " +labels
   legend1 = gsn_create_legend (wks1,dimsizes(label1), label1,lgres1)

   if(iv.eq.0)then
     amres                  = True
     amres@amJust           = "BottomRight"
     amres@amParallelPosF   =  0.40
     amres@amOrthogonalPosF =  0.48
   else
     amres                  = True
     amres@amJust           = "TopRight"
     amres@amParallelPosF   =  0.40
     amres@amOrthogonalPosF = -0.48
   end if 
   annoid1 = gsn_add_annotation(plot,legend1,amres)  ; add legend to the top figure

;---Draw both plots in a panel
    pnres                         = True
    pnres@gsnMaximize             = False
    pnres@gsnPanelMainString      = "" ;"Hovmoller diagrams of "+Varstr+" over " + Figstr 
    pnres@gsnPanelMainFontColor   = "Black"
    pnres@gsnPanelMainFontHeightF = 0.012
   ;pnres@gsnPanelBottom          = 0.05
    pnres@gsnPanelYWhiteSpacePercent = 4
   ;pnres@gsnPanelXF = (/0.05,0.17,0.29,0.41,0.53,0.65/)    ; Adjust rightmost plots
    pnres@gsnPanelXF = (/0.05,0.17,0.29,0.41/)
    gsn_panel(wks1,(/plot(:)/),(/1,1/),pnres)
   delete([/pnres,res,res1/])
 end do ; end of var loop

end do ; end of subreg loop

end

