pro sofi_reduc_script,indir,outdir,tname=tname,skip_xtalk=skip_xtalk,skip_flat=skip_flat,skip_illum=skip_illum,skip_apply_illum=skip_apply_illum,only_phot=only_phot,aperture=aperture,rms_cut=rms_cut,mskip=mskip,avg=avg,allow_src=allow_src
;+
; NAME:
;     SOFI_REDUC_SCRIPT:
; PURPOSE:
;     Perform a basic reduction of Js band SoFI time-series data from
;     the BAM survey (Wilson et al. 2014) as found in the re-analysis
;     by Radigan et al. 2014, including:
;        -xtalk correction 
;        -sky subtraction (also removes dark current and bias)
;        -flat fielding
;        -illumination correction
;        -point source identification  
;        -aperture photometry
;
;     By default all steps are performed, but individual steps can be
;     skipped using keywords.
;
;    The code is intended for instructive purposes only, and the author
;    makes no guarantees regarding its general use. This code should
;    work with the sample BAM data included, but may require some
;    user-modification to work with other data sets.
;    Please report bugs to radigan@stsci.edu.
;
; EXPLANATION:
;     This script is intended to be run for one target at a time.
;     Before starting, all science files pertaining to
;     a single target should be collected in the <indir> directory,
;     and an empty <outdir> directory should be created.  The script
;     takes <indir> and <outdir> as arguments. Calibration files for
;     the special dome flats and illumination correction should be
;     placed in <indir>/flats/ and <indir>/illum/ before beginning.  
;
;     It is recommended to run this code from the folder containing
;     <outdir> and <indir>. 
;     Reduced products and auxillary files are created in <outdir>.
;
;     WARNING: if <outdir> is not empty, old files will be clobbered.
;     
;     Explanations of the reduction procedures can be found in the
;     following documents or web resources:
;
;     SoFI manual:
;     xtalk correction:
;     special dome flat fields: 
;     illumination correction:
;
; CALLING SEQUENCE
;     sofi_reduc_script,indir,outdir,skip_xtalk=skip_xtalk,skip_skysub=skip_skysub,skip_flat=skip_flat,skip_illum=skip_illum,manual_src_pos=manual_src_pos
; INPUT PARAMETERS:
;    indir - directory with input science files (and flats/ and illum/
;            folders containing flat field and illumination calibration files)
;    outdir - directory where output files will be stored (should be
;             empty to begin with)
; OUTPUT PARAMETERS:
;    This script creates .fits files with photometric data. Example
;    .eps files of the time series are also produced, but figures
;    may require user-modification on a case-by-case basis.
;   
; OPTIONAL INPUT PARAMETERS:
;   tname - string to label target in plots
;   rms_cut - use only reference stars with rms < rms_cut * rms_target
;             (default is 2.5)
;   mskip - used to identify indices of reference stars to
;           skip for inclusion in the calibration curve.
;   avg - take an average rather than median when constructing the
;         calibration curve (may be appropriate when N_refs is small)
;   only_phot - set keyword to skip reduction and just do aperture
;               photometry
;   
;   skip_<reduction_step> - set to skip particular reduction step (see
;                           calling sequence).  Provides ability to
;                           redo main reduction without having to redo
;                           xtalk correction, and prepare calibration files. 
;                       
;  skip_apply_illuim - skip the application of the illumination
;                      correction
;  aperture - photometry aperture in units of pixels x 1.5
;  allow_src - reference star index-->overrides the fwhm clipping
;              (useful if the only bright references are somewhat
;              extended) 
; 
;                    
; DEPENDENCIES:
;    IDL Astronomy User's Library
;    grab_im_coords.pro
;    obslog.pro
;    remove_xtalk.pro
;    writecol.pro   
;    xtalk.pro  
;
; REVISION HISTORY:
;
;    Written,   J. Radigan May 2014
;-


flat_dir=indir+'/flats'
illum_dir=indir+'/illum'
sky_dir=outdir+'/skysub'

if keyword_set(only_phot) then goto, only_phot

;//////////////// [[ Step 1 ]] Apply xtalk correction to all files
xtalk_dir=outdir+'/xtalk'
if ~keyword_set(skip_xtalk) then begin
   if ~file_test(xtalk_dir) then begin
      spawn, 'mkdir '+xtalk_dir
      remove_xtalk,indir,xtalk_dir
   endif
   ;if ~file_test(flat_dir+'/xtalk') and ~keyword_set(skip_flat) then begin
   ;   spawn, 'mkdir '+flat_dir+'/xtalk'
   ;   remove_xtalk,flat_dir,flat_dir+'/xtalk'
   ;endif
   ;if ~file_test(illum_dir+'/xtalk') and ~keyword_set(skip_illum) then begin
   ;   spawn, 'mkdir '+illum_dir+'/xtalk'
   ;   remove_xtalk,illum_dir,illum_dir+'/xtalk'
   ;endif
endif 

;//////////////// [[ Step 2 ]] Reduce special dome flats
if ~keyword_set(skip_flat) then flat_field,flat_dir,outdir ;-->writes mflat.fits


;//////////////// [[ Step 3 ]] Calculate illumination correction
if ~keyword_set(skip_illum) then illum_cor,illum_dir,outdir ;-->writes illum_cor.sav

;//////////////// [[ Step 3 ]] Create a log of xtalk corrected input files
obs_log,xtalk_dir,outdir ;--->writes obslog.txt

;//////////////// [[ Step 4 ]] Find preliminary target position in all slices
get_target_positions,outdir ;--->creates tpos.txt

;//////////////// [[ Step 5 ]] Get info req'd for sky subtraction
sky_info,outdir,d_thr=d_thr,i_thr=i_thr,t_thr=t_thr;--->outputs 'sky_info.sav'

;//////////////// [[ Step 6 ]] Initial sky subtraction.    
;Note that the sky subtraction serves
;to remove dark current and bias as well. Frames are flat-fielded
;after sky subtraction within the sky_subtract procedure. 
if ~file_test(sky_dir) then spawn, 'mkdir '+sky_dir
sky_subtract,outdir,sky_dir,skip_illum=skip_apply_illum ;-->writes files to 'skysub/'

;//////////////// [[ Step 7 ]] Get positions of target and reference
;stars in sky subtracted images
define_references,outdir,ref_frame=0 ;-->outputs a bunch of useful .sav files indicating 
;positions, FWHM, PSF fluxes of references   

;//////////////// [[ Step 8 ]] Redo sky subtraction masking references
;in median-combined sky frames.  
sky_dir2=sky_dir ;clobber old files by using same directory as before
;if ~file_test(skydir2) then spawn, 'mkdir '+sky_dir2 ;^no need to make new directory, let's save space
if keyword_set(skip_apply_illum) then skip_apply_illum=1 else $
   skip_apply_illum=0
sky_subtract,outdir,sky_dir2,/mask,skip_illum=skip_apply_illum ;-->writes new files to 'skysub/' (clobers old)


;//////////////// [[ Step 9 ]] Do aperture photometry on target
; and references.
only_phot:

;Edit options here:
aperture_size=aperture ;multiplier
aperture_array=[1.5] ;pixel units
sky_annulus=[21,31];fixed inner and outer radius of sky annulus to perform
ctrd_type=0 ;0=use PSF fitting centroiding, 1=use output of cntrd.pro (weighted means)
aperture_type=0 ;0=fixed, 1=scaled to FWHM

do_phot,outdir,sky_dir,aperture_type=aperture_type,aperture_size=aperture_size,aperture_array=aperture_array,sky_annulus=sky_annulus,cntrd_type=0,tname=tname,rms_cut=rms_cut,mskip=mskip,avg=avg,return_ref_rms=return_ref_rms,test_apertures=test_apertures,allow_src=allow_src

;Test array of aperture sizes-->output ap_array_<tname>.log
;---uncomment below if desired
;test_apertures=1
;aps=[2,3,4,5,6,7,8]
;nap=n_elements(aps)
;mean_rms=fltarr(nap)
;logname=outdir+'/ap_array_'+tname+'.log'
;openw,lun,logname,/get_lun
;printf,lun,'Log of reference star RMS as a function of aperture size (x1.5 pixels) '
;for i=0,nap-1 do begin
;   do_phot,outdir,sky_dir,aperture_type=aperture_type,aperture_size=aps[i],aperture_array=aperture_array,sky_annulus=sky_annulus,cntrd_type=0,tname=tname,rms_cut=rms_cut,mskip=mskip,avg=avg,return_ref_rms=return_ref_rms,allow_src=allow_src
;   printf,lun,'Aperture: '+trim(aps[i])+'    Mean RMS: '+trim(mean(return_ref_rms.rms),'(f6.4)')
;   printf,lun,trim(return_ref_rms.refs)+' '
;   printf,lun,trim(return_ref_rms.rms,'(f6.4)') 
;endfor  
;free_lun,lun
end 
