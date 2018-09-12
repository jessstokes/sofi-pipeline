pro illum_cor,illum_dir,outdir

;read in illumination correction files
files=file_search(illum_dir+'/*.fits')
nf=n_elements(files)

;extract times from headers
mjd=dblarr(nf)
filt=strarr(nf)
for i=0,nf-1 do begin
   h=headfits(files[i])
   mjd[i]=sxpar(h,'MJD-OBS')
   filt[i]=esosxpar(h,'HIERARCH ESO INS FILT1 NAME')
endfor
t=24d*(mjd-min(mjd)) ;hours
ind=where(filt eq 'Ks')
remove,ind,files,t,mjd,filt

;split sets separated by at least 5 hours
;Illum. grids were taken on multiple days,
;we only need one (best) set of 16.
split_sets,t,5.,parts,nparts=nparts,starts=starts,len=len

fluxes=fltarr(16,nparts)
zsurf=fltarr(1024,1024,nparts)

;for first BAM run
xpos=[90,90,84,90,80]
ypos=[100,100,100,110,100]

;for second BAM run
;xpos=[100,100,100,105,110,110]
;ypos=[115,105,110,115,110,115]

;choose which set to use
for k=0,nparts-1 do begin
   ind=where(parts eq k)
   files0=files[ind]
   nf=n_elements(files0)

;read in illumination grid
   grid=mk_cube(files0)

;remove xtalk for each file
   alpha=1.4d-5
   for i=0,nf-1 do begin
      im=grid[*,*,i]
      xtalk,im,alpha
      grid[*,*,i]=im
   endfor

;construct a sky frame from the grid
   ;sky=grid
   ;illum_level=fltarr(nf)
   ;for i=0,nf-1 do illum_level[i]=median_iter(grid[*,*,i],3,3)
   ;for i=0,nf-1 do sky[*,*,i]/=illum_level[i]
   ;msky=median(sky,dim=3)

   mflat=readfits(outdir+'/mflat.fits',h)
   mflat/=median(mflat)
   ;subtract sky from grid and flat field
                                ;since the illumination corrections
                                ;are done at the beginning/end of the
                                ;night, the illumination is changing
                                ;quite significantly.  Therefore,
                                ;instead of subtracting a
                                ;median-combined sky, it is actually
                                ;better just to subtract adjacent images. 
                                ; for i=0,nf-1 do
                                ; grid[*,*,i]=(grid[*,*,i]-(msky*illum_level[i]))/mflat
   tmp = grid[*,*,nf-2]
   for i=0,nf-2 do grid[*,*,i]=(grid[*,*,i]-(grid[*,*,i+1]))/mflat
   grid[*,*,nf-1]=(grid[*,*,nf-1]-(tmp))/mflat
   

;get standard position in image
  ; Field too crowded for point-and-click. 
  ; print, '>>>>>>>>>> Identify standard star by clicking once, then middle click (alt-click on Mac) to exit'
  ; stop
  ; grab_im_coords,grid[*,*,0],xpos0,ypos0
  
   ;Standard stars used were identified by name from ESO headers,
   ;and in the images using finder charts from SIMBAD/Aladin
   ;the approximate pixel positions of the STD are encoded in xpos0,ypos0
   xpos0=xpos[k]
   ypos0=ypos[k]
   xx=fltarr(nf)
   yy=fltarr(nf)

   ;grid dither pattern
   yy[0:3]=ypos0
   yy[4:7]=ypos0+260.
   yy[8:11]=ypos0+260.*2
   yy[12:15]=ypos0+260.*3.
   xvec=findgen(4)*260.+xpos0
   xx[0:3]=xvec
   xx[4:7]=reverse(xvec)
   xx[8:11]=xvec
   xx[12:15]=reverse(xvec)
   
   ;refine positions and measure flux
   ;To-do: centroiding for Run-2 on out-of-focus stars could be improved,
   ;but in practive this doesn't matter much since we are using a large
   ;photometry aperture
   
   flux=fltarr(nf)
   fwhm=fltarr(nf,2)
   for i=0,nf-1 do begin
      x0=xx[i]
      y0=yy[i]
      im=grid[*,*,i]
      ;box=21
      box=25
      subim=subarr(im,box,round([x0,y0]))
      cntrd,subim,box/2,box/2,xxx,yyy,10
      xtmp1=round(x0)-box/2+xxx+0.5
      ytmp1=round(y0)-box/2+yyy+0.5
      tvdl,subim,/med
      ;stop
      box=21
      subim=subarr(im,box,round([xtmp1,ytmp1]))
      guess=[0,500.,3.,3.,box/2,box/2,0]
      g0=mpfit2dpeak(subim,pars0,estimates=guess,/tilt)
      xtmp=round(xtmp1)-box/2+pars0[4]+0.5
      ytmp=round(ytmp1)-box/2+pars0[5]+0.5
      tvdl,subim,/med
      ;stop
      
      box=11
      pars0[[4,5]]=[box/2,box/2]
      subim=subarr(im,box,round([xtmp,ytmp]))
      g=mpfit2dpeak(subim,pars,estimates=pars0,/tilt)
      tvdl,subim,/med
      ;stop
      
      xx[i]=round(xtmp)-box/2+pars[4]+0.5
      yy[i]=round(ytmp)-box/2+pars[5]+0.5
      loadct,1
      plotimage,im,range=[-20,500]
      oplot,[xx[i]],[yy[i]],psym=4,col=200,thick=2
      ;stop
      
      fwhm[i,*]=pars[2:3] 
      apr=10.     ;set this =10 for run 1 where STD star is in-focus and field is crowded, =15 for run 2.
      skyrad=[21,31]  
      aper,im,xx[i]-0.5,yy[i]-0.5,flux0,errap,sky,skyerr,5.4,apr,skyrad,badpix,/FLUX,/SILENT,/EXACT,/NAN
      flux[i]=flux0
endfor
   guess=fltarr(6)
   guess[0]=1.
   pars=mpfit2dfun('surf2d',xx,yy,flux/median(flux),replicate(1.,nf),guess)
   xxx=findgen(1024)#ones(1024)
   yyy=transpose(xxx)
   zz=surf2d(xxx,yyy,pars)
   fluxes[*,k]=flux
   zsurf[*,*,k]=zz
endfor

;plot fluxes to check consistency
for i=0,nparts-1 do begin
   if i eq 0 then plot,fluxes[*,i]/median(fluxes[*,i]),yr=[0.8,1.2] else $
      oplot,fluxes[*,i]/median(fluxes[*,i])
endfor
stop

;Of the 6 repeats, the fluxes from set #2,4 do no match, so we will discard these (run 1)
;Of the 6 repeats, the fluxes from set #0,1 do no match, so we will discard these (run 2)

ind=indgen(nparts)
;remove,[2,4],ind ;(run 1)
;remove,[0,1],ind ;(run 2)
fluxes=fluxes[*,ind]
zsurf=zsurf[*,*,ind]
nparts=n_elements(ind)

;take the average of fluxes (works fine for run 1, but median better
;for run 2 due to outliers)

meanflux=fltarr(16)
for i=0,15 do meanflux[i]=total(fluxes[i,*])/float(nparts)
oplot,meanflux/median(meanflux),thick=3
;meanflux=median(fluxes,dim=2) ;(run 2)

;refit surface
guess=fltarr(6)
guess[0]=1.
pars=mpfit2dfun('surf2d',xx,yy,meanflux/median(meanflux),replicate(1.,nf),guess)
xxx=findgen(1024)#ones(1024)
yyy=transpose(xxx)
zz=surf2d(xxx,yyy,pars)
save,zz,flux,filename=outdir+'/illum_cor.sav'
arr=reform(meanflux/median(meanflux),4,4)

;visualize
arr[*,1]=reverse(arr[*,1])
arr[*,3]=reverse(arr[*,3])
tvdl,arr,0.98,1.02
stop
tvdl,zz,0.98,1.02
stop
end
