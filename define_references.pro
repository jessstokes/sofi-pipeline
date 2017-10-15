pro define_references,dir,ref_frame=ref_frame
readcol,dir+'/tpos.txt',xtarg,ytarg,time,num,filt,file,format='(f,f,d,f,a,a)'

if ~keyword_set(ref_frame) then ref_frame=0
;^set this keyword to using Nth image in sequence
;as the positional referece (i.e. because of a large
;offset early in the sequence, changing the references
;in the FoV

;file names are from xtalk/ folder.  need to append _skysub for files
;in skysub/ folder
nf=n_elements(file)
skyfile=strarr(nf)
for i=0,nf-1 do begin
   pos2=strpos(file[i],'.fits')
   pos1=strpos(file[i],'SOFI')
   tmp=strmid(file[i],pos1,pos2-pos1)
   skyfile[i]=dir+'/skysub/'+tmp+'_skysub.fits'
endfor

restore,dir+'/sky_info.sav'
if ~file_test(dir+'/ref_pos.sav') then begin
   ;read in first file and id references by clicking
   ind=where(nsky ge 3)
   im=readfits(skyfile[ind[ref_frame]],hdr)
   print, '>>>>>>>>>> ID the target and reference stars in the image'
   print, '>>>>>>>>>> click on target FIRST, and then references'
   print, '>>>>>>>>>> Middle click (option/alt-click on a Mac) to exit'
   grab_im_coords,im,xpos,ypos

   n=n_elements(xpos)
   xy=fltarr(2,n)

;refine clicked positions
for i=0,n-1 do begin
   box=21
   subim=subarr(im,box,round([xpos[i],ypos[i]]))
   guess=[0,500.,3.,3.,box/2,box/2,0]
   g0=mpfit2dpeak(subim,pars0,estimates=guess,/tilt)

   xtmp=round(xpos[i])-box/2+pars0[4]+0.5
   ytmp=round(ypos[i])-box/2+pars0[5]+0.5
   
   box=15
   pars0[[4,5]]=[box/2,box/2]
   subim=subarr(im,box,round([xtmp,ytmp]))
   g=mpfit2dpeak(subim,pars,estimates=pars0,/tilt)
   
   xy[0,i]=round(xtmp)-box/2+pars[4]+0.5
   xy[1,i]=round(ytmp)-box/2+pars[5]+0.5

   ;visual check on centroiding
   plotimage,subim,range=[0,500],/iso   
   oplot, [pars[4]]+0.5,[pars[5]+0.5],psym=4,col=2
   wait,0.1
endfor
save,xy,filename=dir+'/ref_pos.sav'
endif else begin
   print, 'WARNING: reading reference positions from ref_pos.sav... delete this file to choose new reference stars'
   restore,dir+'/ref_pos.sav'
   n=n_elements(xy[0,*])
endelse

;now get precise reference star positions in each frame
nf=n_elements(file)
xoff=reform(xy[0,1:*]-xy[0,0],n-1)
yoff=reform(xy[1,1:*]-xy[1,0],n-1)
xoff=[0.,xoff]
yoff=[0.,yoff]
xypos=fltarr(2,n,nf)
cenxypos=xypos
fwhm=fltarr(n,nf,2)
psf_flux=fltarr(n,nf)
for i=0,nf-1 do begin
   im=readfits(skyfile[i],hdr)
   for j=0,n-1 do begin
      x0=xtarg[i]+xoff[j]
      y0=ytarg[i]+yoff[j]
      flag=0
      if x0 ge 1022 or y0 ge 1022 or x0 le 2 or y0 le 2 or nsky[i] lt 3 then begin
         flag=1
         goto,skip_cent
      endif
      box=21
      subim=subarr(im,box,round([x0,y0]))
      guess=[0,500.,3.,3.,box/2,box/2,0]
      g0=mpfit2dpeak(subim,pars0,estimates=guess,/tilt)
      xtmp=round(x0)-box/2+pars0[4]+0.5
      ytmp=round(y0)-box/2+pars0[5]+0.5
    
      box=15
      pars0[[4,5]]=[box/2,box/2]
      subim=subarr(im,box,round([xtmp,ytmp]))
      g=mpfit2dpeak(subim,pars,estimates=pars0,/tilt)
      
      xypos[0,j,i]=round(xtmp)-box/2+pars[4]+0.5
      xypos[1,j,i]=round(ytmp)-box/2+pars[5]+0.5

     ; visual check on subimages---uncomment if desired
     ; plotimage,subim,range=[0,500],/iso   
     ; oplot, [pars[4]]+0.5,[pars[5]+0.5],psym=4,col=2
     
      ;keep information on source FWHM
      if pars[2] eq 3. then pars[2]=0. ;error checking for returned guess parameter
      if pars[3] eq 3. then pars[3]=0. 
      fwhm[j,i,*]=pars[2:3]
      if pars[2] eq guess[2] then stop
      
      ;keep flux information from a basic Gaussian PSF fit
      psf_flux[j,i]=total(g-pars[0])
      
      ;centroid using a weighted mean as well
      cntrd, im, xypos[0,j,i], xypos[1,j,i], xcen, ycen, fwhm[j,i,0], /silent
      cenxypos[0,j,i]=xcen
      cenxypos[1,j,i]=ycen

     ;if star position outside range then
     ;skip centroiding and store error values
      skip_cent:
      if flag eq 1 then begin
         xypos[0,j,i]=x0
         xypos[1,j,i]=y0
         fwhm[j,i]=!values.f_nan
         psf_flux[j,i]=!values.f_nan
         ;if j eq 2 then stop
      endif
   endfor  
   
   if flag eq 1 then continue
   ;visualization of star positions via PSF fitting and weighted mean 
   ;in a slice
   tvdl,im,z1,z2,pc=99
   plotimage,im,range=[z1,z2],/iso
   oplot,[xtarg[i]],[ytarg[i]],psym=4,thick=3
   oplot,xypos[0,*,i],xypos[1,*,i],col=2,psym=4
   oplot,cenxypos[0,*,i],cenxypos[1,*,i],col=3,psym=4

   ;Progress indicator
   print, 'Finished finding positions for...'+trim(i)+'/'+trim(nf)+'...slices'
endfor

;save some useful stuff
save,xypos,filename=dir+'/xypos.sav'
save,fwhm,filename=dir+'/fwhm.sav'
save,psf_flux,filename=dir+'/psf_flux.sav'
save,cenxypos,filename=dir+'/cen_xypos.sav'
end
