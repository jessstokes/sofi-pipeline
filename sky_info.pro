pro sky_info,outdir,d_thr=d_thr,t_thr=t_thr,i_thr=i_thr

if ~keyword_set(d_thr) then d_thr=31. ;minimum offset for sky (pixels)
if ~keyword_set(t_thr) then t_thr=15. ;minimum time offset for sky (minutes) 
if ~keyword_set(i_thr) then i_thr=0.1 ;minimum illumination offset (<DN>)

readcol,outdir+'/tpos.txt',xtarg,ytarg,time,num,filt,file,format='(f,f,d,f,a,a)'
nf=n_elements(file)
nsky=fltarr(nf)
;use up to 15 dithered frames for sky subtraction
skyfiles=strarr(nf,15)
skyind=intarr(nf,15)

;get illumination for each file
illum=fltarr(nf)
for i=0,nf-1 do begin
   a=readfits(file[i],h)
   illum[i]=median_iter(a,3,3)
endfor
for i=0,nf-1 do begin
   dt=24d * abs(time[i]-time) * 60d
   dist=sqrt((xtarg[i]-xtarg)^2 + (ytarg[i]-ytarg)^2)
   d_illum=abs(illum[i]-illum)
   ;find images separated by less than 15
   ;minutes in time, and more than 31 pixels
   ;in spatial offset (use may want to 
   ;modify these depending on image FWHM)
   ;d_illum is difference in illumination
   ind=where(dt lt t_thr and dist gt d_thr and d_illum/illum[i] lt i_thr,ns) 
   nsky[i]=ns
   if nsky[i] lt 3 then stop
   if ns eq 0. then continue
   print, ns
   if ns gt 15 then begin
      ns=15
      sind=sort(dt[ind])
      tmp=file[ind[sind[0:ns-1]]]
      skyind[i,0:ns-1]=ind[sind[0:ns-1]]
   endif else begin
      tmp=file[ind]
      skyind[i,0:ns-1]=ind
   endelse
   skyfiles[i,0:ns-1]=tmp
endfor
ind=where(nsky lt 3,badsky)
if float(badsky)/float(n_elements(nsky)) gt 0.05 then print, $
   'WARNING: NSKY<3 in more than 5% of cases ('+trim(badsky)+' instances).  Consider modifying the {d,t,i}_thr keywords.' 
save,skyfiles,skyind,nsky,file,illum,filename=outdir+'/sky_info.sav'
end
