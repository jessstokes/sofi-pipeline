pro sky_subtract,dir,sky_dir,mask=mask,skip_illum=skip_illum
;sky subtract data
readcol,dir+'/tpos.txt',xtarg,ytarg,time,num,filt,files,format='(f,f,d,f,a,a)'

restore,dir+'/sky_info.sav'
nf=n_elements(file)
sdir=sky_dir
t1=systime(1)

if keyword_set(mask) then begin
   yy=ones(1024)#findgen(1024)
   xx=transpose(yy)
   mask0=replicate(1.,1024,1024)
   restore,dir+'/xypos.sav'
   nref=n_elements(xypos[0,*,0])
endif

mflat=readfits(dir+'/mflat.fits')
mflat/=median(mflat)
restore,dir+'/illum_cor.sav'
if ~keyword_set(skip_illum) then mflat*=zz
print, 'Key_word skip_illum set? '+trim(keyword_set(skip_illum))
stop

;bad pixel flagging
med0=median_iter(mflat,3,3)
rms=robust_sigma(mflat)
ind=where(abs(mflat-med0) gt 10.*rms)
tmp=mflat
tmp[ind]=!values.f_nan
mflat=tmp
;^tmp is a relic from some code testing; comment out this line
;to skip bad pixel flagging

if keyword_set(mask) then begin
   restore,dir+'/fwhm.sav'
   fwmed=median(fwhm[0,*,*])
endif
for i=0,nf-1 do begin
   if nsky[i] gt 15 then nsky[i]=15
   if nsky[i] lt 3 then continue
   if nsky[i] mod 2 eq 0 then nsky[i]-=1
   print, 'Nsky= '+trim(nsky[i])
   im=readfits(file[i],hdr)
   sky=mk_cube(skyfiles[i,0:nsky[i]-1])
   if keyword_set(mask) then masks=fltarr(1024,1024,nsky[i])
   islices=skyind[i,0:nsky[i]-1]
   
   ;mask out (user selected) bright stars
   if keyword_set(mask) then begin
      for j=0,nsky[i]-1 do begin
         islice=islices[j]
         mtmp=fltarr(1024,1024)+1.
         fw=median(fwhm[*,islice,*])/fwmed
         for k=0,nref-1 do begin
            mind=where(sqrt((xx-xypos[0,k,islice])^2+(yy-xypos[1,k,islice])^2) lt 3.*2.35*fw,nmask)
            if nmask gt 0 then mtmp[mind]=!values.f_nan
         endfor
         masks[*,*,j]=mtmp
         sky[*,*,j]=sky[*,*,j]*mtmp
      endfor  
   endif
 
  ;scale the skies, and median combine
   for j=0,nsky[i]-1 do sky[*,*,j]/=median_iter(sky[*,*,j],3,3)
   msky=median(sky,dim=3)       ;median sky--> (dark+bias + med(sky))
   
   ;scale sky to image and subtract
   scl=median_iter(im,3,3)/median_iter(msky,3,3)
   im0=(im-(msky*scl))/mflat ;subtract sky then flat field
   
   pos1=strpos(file[i],'.fits')
   pos2=strpos(file[i],'SOFI')
   tmp=strmid(file[i],pos2,pos1-pos2)
   fname=tmp+'_skysub.fits'
   writefits,sdir+'/'+fname,im0,hdr
   tvdl, im0,pc=95 ;visualize in real time
   print, 'sky subtracted....'+trim(i)+'/'+trim(nf)+'...files'
endfor 
t2=systime(2)
print, 'Sky subtraction of '+trim(nf)+' files took '+trim(t2-t1)+' seconds'
end
