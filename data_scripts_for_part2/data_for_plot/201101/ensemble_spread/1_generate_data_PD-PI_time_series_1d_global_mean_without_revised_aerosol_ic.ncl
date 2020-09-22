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
  Regions      = (/"NP"/)
  nregs        = dimsizes(Regions)

;;;;;;;date strings for the data directory;;;;;;;;
  anlyyyymm    = "201101"
  xstring      = "Days since 01 January 2011"

;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  Casdir0      = (/"PI_ENSNDG_ERA5_Hind_d0","PI_EDAUVT_Hind_d0","PI_EDAUVT_Hind_d1","PI_EDAUVT_Hind_d2","PI_EDAUVT_Hind_d5"/)
  Casdir1      = (/"PD_ENSNDG_ERA5_Hind_d0","PD_EDAUVT_Hind_d0","PD_EDAUVT_Hind_d1","PD_EDAUVT_Hind_d2","PD_EDAUVT_Hind_d5"/)
  Casdir0      = Casdir0 + "_"+anlyyyymm
  Casdir1      = Casdir1 + "_"+anlyyyymm
  Groups       = (/"ENSNDG_ERA5","EDAUVT_Hind_d0", "EDAUVT_Hind_d1","EDAUVT_Hind_d2","EDAUVT_Hind_d5"/)
  ngrps        = dimsizes(Groups)
  labels       = (/"  PD - PI (NDG)", "  PD - PI (EDA)"/)

;;;;;data source to be plotted (e.g. annual mean, seasonal mean, montly mean etc.)
  Plttim       = (/"*ens*.cam.h0"/)
  nptim        = dimsizes(Plttim)

 ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"SWCF","LWCF","FSNT","FLNT"/)
  VstList      = (/"SW CRE","LW CRE", "FSNT", "FLNT"/)
  UnitList     = (/"W m~S~-2~N~","W m~S~-2~N~","W m~S~-2~N~","W m~S~-2~N~"/)
  PltNums      = (/"", "", "", "", "", "", "", "", "", "", ""/)
  nvars        = dimsizes(VarList)

 ;;; flags to control the plot style
  plotcntl          = False   ; if True, plot the CNTL origianl field on the leftmost panel

  plotrdif          = False  ; True  ; if True, plot the relative difference with respect to CNTL

  plot_ttest_mskout = False  ; if True, mask the non-significant region as missing values

  plot_ttest_hatch  = True  ; if True, plot the significant region as hatch region

  plot_ttest_hatrv  = False  ; if True, plot the non-significant region as hatch region

  plot_contour      = False  ; True   ; if True, plot the contour in the figure

  plot_leftstr      = True   ; if True, the lefadd igure captions as left string

  plot_lndmsk       = False ;
 ;;;these flags control the zonal mean plot
  plot_zonal_mean   = False  ; whether or not plot zonal mean
  add_fill_line     = False  ; Turn off (on if True) fill color below the zonal mean line
  add_std_shading   = False ; If true, the grey shading is added for uncertainty of zonal mean
  add_std_line      = False  ; If true, the dash red lines are added for upper and bottom bounds
                            ; of uncertainty for zonal mean

 ;;color for the map boundary line
  lndcolor = "Black" ;"Grey50"

 ;;flags to perform significant test;;;;;;;;
  l_studentttest    = False ; True if perform student-t test
  l_pairedttest     = True ;False ; True  ; True if perform parired-t test
  l_kstest          = False ;True  ; True if perform K-S test, see https://www.ncl.ucar.edu/Document/Functions/Built-in/kolsm2_n.shtml

 ;;;loop the regions and plot the PDF
 load "./sc_cloud_region.ncl"
 do irg = 0,0 ;nsubreg-1
  MinLat = minlat(irg)
  MaxLat = maxlat(irg)
  MinLon = minlon(irg)
  MaxLon = maxlon(irg)

 ;;;;open netcdf file and save data for the pfigures;;;;;;;
 setfileoption("nc", "Format",  "NetCDF4")
 out_file_name = "Global_distribution_10year_mean_cloud_and_cloud_forcing.nc"
 system("rm " + out_file_name)
 fout = addfile(out_file_name,"c")

 do iv = 0,nvars-1, 1

  Varname = VarList(iv)
  Varunt  = UnitList(iv)
  Varstr  = VstList(iv)
  Figstr  = PltNums(iv)

  plotFileLabel = VarList(iv)+"_PD-PI"
 ;;;;;;;open a wks for plot;;;;;;;;;;;;;;;;;;;
  OUTDir  = "./"
  wtype = "png"
  wtype@wkWidth = 2500
  wtype@wkHeight = 2500
  ;wtype@wkPaperSize     = "A4"
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  wks1 = gsn_open_wks(wtype,OUTDir+"fig_"+Subreg(irg)+"_"+plotFileLabel)
  load "./var_share_colorbar.ncl"


 do igp = 0, ngrps-1,1

  refcase = Casdir0 (igp)
  tescase = Casdir1 (igp)

;;;;;;;begin to work with the simulations;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Filnam0 = systemfunc("cd "+ModelOutRoot+refcase+"/"+"; ls *"+Plttim+"*")
  File0   = addfiles(ModelOutRoot+refcase+"/"+Filnam0,"r")
  Filnam1 = systemfunc("cd "+ModelOutRoot+tescase+"/"+"; ls *"+Plttim+"*")
  File1   = addfiles(ModelOutRoot+tescase+"/"+Filnam1,"r")
  ListSetType (File0, "join")
  ListSetType (File1, "join")

  xlat       = File0[0]->lat ;({MinLat:MaxLat})
  xlon       = File0[0]->lon ;({MinLon:MaxLon})

  if(Varname.eq."PRECT") then
   opxcre0300 = File0[:]->PRECC
   owxcre0300 = File1[:]->PRECC
   opxcre0300 = File0[:]->PRECC \
              + File0[:]->PRECL
   owxcre0300 = File1[:]->PRECC \
              + File1[:]->PRECL  
  else if(Varname.eq."NETCF") then
   opxcre0300 = File0[:]->LWCF
   owxcre0300 = File1[:]->LWCF
   opxcre0300 = File0[:]->SWCF \
              + File0[:]->LWCF
   owxcre0300 = File1[:]->SWCF \
              + File1[:]->LWCF
  else
   opxcre0300 = File0[:]->$Varname$
   owxcre0300 = File1[:]->$Varname$
  end if
  end if 

  printVarSummary(opxcre0300)
  printVarSummary(opxcre0300)

  if(irg.eq.0.or.irg.eq.5.or.irg.eq.11)then
   ylon       = xlon
   xpxcre0300 = opxcre0300 
   xwxcre0300 = owxcre0300
   ypxcre0300 = xpxcre0300(:,:,{MinLat:MaxLat},{MinLon:MaxLon})
   ywxcre0300 = xwxcre0300(:,:,{MinLat:MaxLat},{MinLon:MaxLon})
   lat        = xlat({MinLat:MaxLat})
   lon        = ylon({MinLon:MaxLon})

  else

   ;;;flip the longitude;;;
   ylon       = lonPivot(xlon, 180)
   xpxcre0300 = lonPivot(opxcre0300, 180)
   xwxcre0300 = lonPivot(owxcre0300, 180)
   ypxcre0300 = xpxcre0300(:,:,{MinLat:MaxLat},{MinLon:MaxLon})
   ywxcre0300 = xwxcre0300(:,:,{MinLat:MaxLat},{MinLon:MaxLon})
   lat        = xlat({MinLat:MaxLat})
   lon        = ylon({MinLon:MaxLon})

  end if 

  printVarSummary(ypxcre0300)
  delete([/opxcre0300,owxcre0300,xpxcre0300,xwxcre0300,xlat,xlon,ylon/])

  dimx      = dimsizes(ypxcre0300)
  nsta      = dimx(0)*dimx(0)
  pxcre0300 = new((/nsta,dimx(1),dimx(2),dimx(3)/),typeof(ypxcre0300))
  wxcre0300 = new((/nsta,dimx(1),dimx(2),dimx(3)/),typeof(ypxcre0300))
  ist = 0
  do ien0 = 0,dimx(0)-1
   do ien1 = 0, dimx(0)-1
    pxcre0300(ist,:,:,:) = ypxcre0300(ien1,:,:,:)
    wxcre0300(ist,:,:,:) = ywxcre0300(ien0,:,:,:)
    ist  = ist +1
   end do
  end do

 ;;;;;;;;;;;;;;;;;;;;;
  dimy = dimsizes(pxcre0300)
  nx   = dimy(1)
  if(igp.eq.0)then
   yy1      = new ( (/ngrps,3,nx/), typeof(pxcre0300))
   yy2      = new ( (/ngrps,3,nx/), typeof(pxcre0300))
   ydf      = new ( (/ngrps,3,nx/), typeof(pxcre0300))
   ya1      = new ( (/ngrps/), typeof(pxcre0300))
   ya2      = new ( (/ngrps/), typeof(pxcre0300))
   yaf      = new ( (/ngrps/), typeof(pxcre0300))
   ys1      = new ( (/ngrps/), typeof(pxcre0300))
   ys2      = new ( (/ngrps/), typeof(pxcre0300))
   ysf      = new ( (/ngrps/), typeof(pxcre0300))
  end if 

  rad     = 4.*atan(1.)/180.    ;
  cost    = lat
  cost    = cos(lat*rad)       ; cosine weights
  ;;;choose the points within subregion
  pncre0300  = wgt_areaave(pxcre0300,cost,1.0,1)
  wncre0300  = wgt_areaave(wxcre0300,cost,1.0,1)
  wncredf1   = wncre0300 - pncre0300

  ydf(igp,0,:)=  dim_avg_n_Wrap(wncredf1,0)
  ydf(igp,1,:)=  ydf(igp,0,:) - dim_stddev_n_Wrap(wncredf1,0)
  ydf(igp,2,:)=  ydf(igp,0,:) + dim_stddev_n_Wrap(wncredf1,0)

 ;;calculate mean values
  yaf(igp)      = dim_avg_n(dim_avg_n(wncredf1,1),0)
  ysf(igp)      = dim_stddev_n(dim_avg_n(wncredf1,1),0)

 printVarSummary(yy1)
 delete([/pxcre0300,wxcre0300,pncre0300,wncre0300,cost,ypxcre0300,ywxcre0300/])

 end do ; end of grp loop
 
 ;;calculate mean values  
 print(ya1 + " "+ya2+ " "+yaf)
 print(ys1 + " "+ys2+ " "+ysf)

 end do ; end of var loop

end do ; end of subreg loop

end

