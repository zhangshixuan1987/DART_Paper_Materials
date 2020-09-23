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
  Groups       = (/"EAMv0_En80", "EAMv0_En20"/)
  ngrps        = dimsizes(Groups)

  filname  = "obs_diag_output_6hourly_mean.nc"

  VarNameList = (/"RADIOSONDE_U_WIND_COMPONENT",\
                  "RADIOSONDE_V_WIND_COMPONENT",\
                  "RADIOSONDE_TEMPERATURE",\
                  "RADIOSONDE_SPECIFIC_HUMIDITY"/)
  VarShortNames = (/"U","V","T","Q"/)
  UnitList      = (/"m s~S~-1~N~", "m s~S~-1~N~","K","g kg~S~-1~N~"/)
  VarStrList    = (/"Zonal wind","Meridional wind", "Temperature","Specific humidity"/)
  nvars         = dimsizes(VarNameList)

  subvar   = (/"bias","rmse","Nposs","Nused"/)
  facts    = (/1,1,1e3,1e3/)
  nsubvs   = dimsizes(subvar)

  regions  = (/"Northern Hemisphere", "Southern Hemisphere", "Tropics", "North America"/)
  lonlim1  = (/  0.0,   0.0,   0.0, 235.0/)
  lonlim2  = (/360.0, 360.0, 360.0, 295.0/)
  latlim1  = (/ 20.0, -20.0, -90.0, 25.0/)
  latlim2  = (/ 90.0,  20.0, -20.0, 55.0/)

 ;;;;open netcdf file and save data for the pfigures;;;;;;;
  setfileoption("nc", "Format",  "NetCDF4")
  out_file_name = "EAMv0_80ens_vs_20ens_rmse_bias_with_respect_to_radiosonde.nc"
  system("rm " + out_file_name)
  fout = addfile(out_file_name,"c")

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

  do iv = 0, nvars-1,1

  do irg   = 0,nregs-1

  pltreg  = str_squeeze(chartostring(regnam(irg,:)))
  replaceSingleChar(pltreg, " ", "_")
  varname = VarNameList(iv)+"_VPguess"
  pltdat1 = new((/nsubvs,nlevs/),typeof(fxx->$varname$))
  pltdat2 = new((/3,nlevs/),typeof(fxx->$varname$))

  do igp = 0, ngrps-1, 1

   fxx     = addfile(ModelOutRoot+"/"+Casdir(igp)+"/"+filname,"r")
   tempvar = fxx->$varname$(:,:,irg)
   printVarSummary(tempvar)
   ;;;;;;;get the data to be plotted 
   do isv  = 0,nsubvs-1,1
   do icp  = 0,ncops-1,1
    if (str_squeeze(copynams(icp)).eq.subvar(isv))then
      print(copynams(icp) + "  "+subvar(isv))
      pltdat1(isv,:) = tempvar(icp,:)/facts(isv)
    end if   
   end do 
   end do 
 
  pltdat1 = where(pltdat1.eq.0,32766,pltdat1)
  pltdat1@_FillValue = 32766

  pltdat2(0:1,:) = (/pltdat1(0:1,:)/)
  ;;calculate the data rejection rate 
  pltdat2(2,:)  = (pltdat1(2,:) - pltdat1(3,:))*100.0/pltdat1(2,:)
  pltdat2@_FillValue = 32766
 
  if ((igp.eq.0).and.(irg.eq.0).and.(iv.eq.0))then
    dplev  = plevel_edg(1:nlevs)-plevel_edg(0:nlevs-1)
    dplev!0 = "lev"
    dplev&lev = dplev
    fout->plev = dplev
  end if

  pltdat2!0           = "nvars"
  pltdat2!1           = "lev"
  pltdat2&lev         = dplev
  pltdat2@units       = UnitList(iv)
  pltdat2@description = VarStrList(iv)
  pltdat2@timerange   = timrange

  varbias = Groups(igp)+"_"+VarShortNames(iv)+"_bias"+"_"+pltreg
  varrmse = Groups(igp)+"_"+VarShortNames(iv)+"_rmse"+"_"+pltreg
  varrate = Groups(igp)+"_"+VarShortNames(iv)+"_rejection_rate"+"_"+pltreg 
  fout->$varbias$ = pltdat2(0,:)
  fout->$varrmse$ = pltdat2(1,:)
  fout->$varrate$ = pltdat2(2,:)

  end do ; end of igp

 end do ; end of irg

end do ; end of iv

end
