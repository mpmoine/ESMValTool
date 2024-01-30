; #############################################################################
; ESMValTool CMORizer for NIWA-BS data
; #############################################################################
;
; Tier
;    Tier 3: restricted dataset.
;
; Source
;    https://zenodo.org/records/7447757 
;
; Last access
;    20190207
;
; Download and processing instructions
;    To get the access data send an email to greg@bodekerscientific.com
;    Download all files from
;      https://zenodo.org/records/7447757 
;    Newer versions may become available over time, but make sure to download
;    the filled one. Only complete years should be downloaded.
;
; Modification history
;    20240126-marie-pierre_moine: adaptation to NIWA-BS v3.4.1.
;    20190207-righi_mattia: renamed to NIWA-BS and adapted to v2.
;    20140528-gottschaldt_klaus-dirk: written.
;
; #############################################################################
loadscript(getenv("esmvaltool_root") + \
           "/data/formatters/interface.ncl")

begin

  ; Script name (for logger)
  DIAG_SCRIPT = "niwa_bs.ncl"

  ; Source name
  OBSNAME = "NIWA-BS"

  ; Tier
  TIER = 3

  ; Period
  YEAR1 = get_year(start_year, 1979)
  YEAR2 = get_year(end_year, 2019)

  ; Selected variable (standard name)
  VAR = (/"toz", "tozStderr"/)

  ; Name in the raw data
  NAME = (/"tco", "tco_uncert"/)

  ; MIP
  MIP = (/"Amon", "Amon"/)

  ; Frequency
  FREQ = (/"mon", "mon"/)

  ; CMOR table
  CMOR_TABLE = getenv("cmor_tables") + "/custom/CMOR_" + VAR + ".dat"

  ; Type
  TYPE = "sat"

  ; Version
  VERSION = "V3.4.1"

  ; Global attributes
  SOURCE = "https://zenodo.org/records/7447757"
  REF = "Publication: Bodeker et al., Atmos. Chem. Phys., doi:10.5194/acp-5-2603-2005, 2005 | Dataset: Bodeker et al., 2022, doi:10.5281/zenodo.3908787"
  COMMENT = ""

end

begin

  files = systemfunc("ls " + input_dir_path + \
                     "BSFilledTCO_" + VERSION + \
                     "_????_Monthly.nc")

  do vv = 0, dimsizes(VAR) - 1

    log_info("Processing " + VAR(vv) + " (" + MIP(vv) + ")")

    f = addfiles(files, "r")
    output = f[:]->$NAME(vv)$

    ; Format coordinates
    output!0 = "time"
    output!1 = "lat"
    output!2 = "lon"
    format_coords(output, YEAR1 + "0101", YEAR2 + "1231", FREQ(vv))

    ; Set variable attributes
    tmp = format_variable(output, VAR(vv), CMOR_TABLE(vv))
    delete(output)
    output = tmp
    delete(tmp)

    ; Calculate coordinate bounds
    bounds = guess_coord_bounds(output, FREQ(vv))

    ; Set global attributes
    gAtt = set_global_atts(OBSNAME, TIER, SOURCE, REF, COMMENT)
    
    ; Add global attributes for details on the dataset
    gAtt@description = "BS Filled Total Column Ozone Database"
    gAtt@version = OBSNAME + " " + VERSION
    gAtt@time_range = YEAR1 + "-" + YEAR2

    ; Output file
    DATESTR = YEAR1 + "01-" + YEAR2 + "12"
    fout = output_dir_path + \
      str_join((/"OBS", OBSNAME, TYPE, str_sub_str(VERSION, "V", "v"), \
                 MIP(vv), VAR(vv), DATESTR/), "_") + ".nc"

    ; Write variable
    write_nc(fout, VAR(vv), output, bounds, gAtt)
    delete(gAtt)
    delete(output)
    delete(bounds)

  end do

end
