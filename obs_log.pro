pro obs_log,indir,outdir
;This procecure creates a log of all the input files

f=file_search(indir+'/*.fits') ;input files
n=n_elements(f)
t=dblarr(n) ;to store MJD times
filt=strarr(n) ;to store filter
texp=strarr(n) ;to store exp times
utdate=strarr(n) ;to store UT date string
obstype=strarr(n) ;to store observation type string

;extract log information from headers
for i=0,n-1 do begin
   h=headfits(f[i])
   filt[i]=esosxpar(h,'HIERARCH ESO INS FILT1 ID')
   utdate[i]=sxpar(h,'date-obs')
   t[i]=sxpar(h,'mjd-obs')
   texp[i]=sxpar(h,'exptime')
   obstype[i]=sxpar(h,'object')
endfor

;sort files according to MJD and write to log file called obslog.txt
ind=sort(t)
writecol,outdir+'/obslog.txt',obstype[ind],replicate('   ',n),utdate[ind],replicate('   ',n),t[ind],replicate('  ',n),filt[ind],replicate('   ',n),texp[ind],replicate('   ',n),f,format='(a,a,a,a,d,a,a,a,f,a,a)'
end
