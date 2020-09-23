
;;;;data directory;;;;;;;;;;;;;
ModelOutRoot = "/pic/projects/E3SM_DA/zhan391/final_analysis/post_processing/post_processing_data/"

trmmdir      = "/pic/projects/E3SM_DA/zhan391/e3sm_dart/acme_init/Observations/TRMM/"+year+"/"+ymstr1+"/"
olrdir       = "/pic/projects/E3SM_DA/zhan391/e3sm_dart/acme_init/Observations/NOAA_HIRS/"
climdir      = ModelOutRoot+"PD_CLIM_5YR_2011-2015_"+sprinti("%02d",month)+"/"

;;;;Generate arrays for experiment names;;;;;;;;;;;;;;;;;;

confg_string = (/"Transpose-AMIP", "EDAUVT"/)
nconfg       = dimsizes (confg_string)

hincast_string = (/"Hind_d1","Hind_d2","Hind_d3","Hind_d4","Hind_d5"/)
nhind = dimsizes(hincast_string)

nexps = 2 * nhind + 2
PD_Exp_Names  = new (nexps, string)
PI_Exp_Names  = new (nexps, string)
Data_File_Key = new (nexps, string)

iexp = 0 
PD_Exp_Names(iexp)  = "OBS"
PI_Exp_Names(iexp)  = "OBS"
Data_File_Key(iexp) = "*" 

iexp = iexp +1 
PD_Exp_Names(iexp) = "CLIM"
PI_Exp_Names(iexp) = "CLIM"
Data_File_Key(iexp) = "*.cam.h0.*.nc"

do ic = 0,nconfg-1,1

 do ih = 0,nhind-1,1

  iexp = iexp + 1
  PD_Exp_Names(iexp)  = "PD_"+ confg_string(ic) + "_"+ hincast_string(ih)
  PI_Exp_Names(iexp)  = "PI_"+ confg_string(ic) + "_"+ hincast_string(ih)
  Data_File_Key(iexp) = "*ens*.cam.h0.*.nc"

 end do 

end do 

