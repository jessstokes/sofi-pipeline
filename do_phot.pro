pro do_phot,dir,skydir,aperture_type=aperture_type,aperture_size=aperture_size,aperture_array=aperture_array,sky_annulus=sky_annulus,cntrd_type=cntrd_type,rms_cut=rms_cut,manual_skip=manual_skip,aperture_plot_index=aperture_plot_index,tname=tname,mskip=mskip,avg=avg,return_ref_rms=return_ref_rms,test_apertures=test_apertures,allow_src=allow_src
;+
;Input parameters are explained in sofi_reduc_script.pro
;-

if ~keyword_set(tname) then tname='IDENJ 00:00:00.0 +00:00:00.0'
if ~keyword_set(rms_cut) then rms_cut=2.5
if ~keyword_set(aperture_plot_index) then aperture_plot_index=0 
;choice of aperture index for plotting data

;read in file lists
readcol,dir+'/tpos.txt',xtarg,ytarg,time,num,filt,files,format='(f,f,d,f,a,a)'
restore,dir+'/xypos.sav' ;star positions in each slice
restore,dir+'/cen_xypos.sav'
restore,dir+'/sky_info.sav'
restore,dir+'/fwhm.sav'

;Target-specific intrstructions
if dir eq 'out_1010' then begin
   ind=indgen(137)
   remove,indgen(40),ind
   files=files[ind] ;remove 1st 40 frames which are offset
   ;from all other frames, and do not share same references
   xypos=xypos[*,*,ind]
   xtarg=xtarg[ind]
   ytarg=ytarg[ind]
   cenxypos=cenxypos[*,*,ind]
   nsky=nsky[ind]
   fwhm=fwhm[*,ind,*]
   time=time[ind]
end
if dir eq 'out_0348' then begin
   ind=indgen(76)
   remove,indgen(6)+69,ind
   files=files[ind]  ;remove portion where observations are clouded out
   xypos=xypos[*,*,ind]
   xtarg=xtarg[ind]
   ytarg=ytarg[ind]
   cenxypos=cenxypos[*,*,ind]
   nsky=nsky[ind]
   fwhm=fwhm[*,ind,*]
   time=time[ind]
end

;store information we will need later
nf=n_elements(files)
nstar=n_elements(xypos[0,*,0])
nap=n_elements(aperture_array)
fluxes=fltarr(nstar,nf,nap)
err=fltarr(nstar,nf,nap)
skyarr=fltarr(nstar,nf)
serr=fltarr(nstar,nf)
epadu=5.4 ;electrons per adu
badpix=[0,0] ;input to aper.pro, no bad pixel flagging

;Identify extended sources.
;MOST REFERENCES MUST BE POINT SOURCES FOR THIS TO WORK
fwhm_flag=bytarr(nstar) ;=0 if OK, =1 if failed or extended
ind=where(~finite(fwhm))
fwhm[ind]=0.
fwx=fwhm[*,*,0]*2.35
fwy=fwhm[*,*,1]*2.35
fw=0.5*fwx+0.5*fwy ;avg of x- and y- fwhm

;iteratively flag extended sources
niter=3
nsig=5
fw_ratio=fltarr(nstar)
for iter=0,niter-1 do begin
   fwhm_flag_old=fwhm_flag
   fwhm_flag*=0
   ind=where(fwhm_flag_old eq 0)
   fwmed=median(fw[ind,*],dim=1,/even) ;take median over all non-flagged sources
   
   for i=0,nstar-1 do fw_ratio[i]=median(fw[i,*]/fwmed)
      
   rms=robust_sigma(fw_ratio[ind])
   med=median(fw_ratio[ind])
   iflag=where(abs(fw_ratio-med) gt rms*nsig,nflag)
   if nflag gt 0 then fwhm_flag[iflag]=1
endfor

save,fwhm_flag,filename=dir+'/fwhm_flag.sav'
;Determine the median FWHM of all point sources on chip in each frame
ind=where(fwhm_flag eq 0)
fwmed=median(fw[ind,*],dim=1)

if keyword_set(allow_src) then fwhm_flag[allow_src]=0 ;allow an extended source as phot reference
;^Careful.  This may be useful to include a slightly extende source
;(e.g. a binary) if there are not many reference stars available.
;However, it will likely require a larger phot. aperture.  And,
;depending on how extended (e.g. galaxy), may not be a stable
;reference in general (not only due to aperture size, but also due to 
;imperfect sky subtraction with a compact dither pattern).

;Do aperture photometry
for i=0,nf-1 do begin
   ;get image file name for slice i
   pos1=strpos(files[i],'.fits')
   pos2=strpos(files[i],'SOFI')
   fname=strmid(files[i],pos2,pos1-pos2)+'_skysub.fits'
   test=file_test(skydir+'/'+fname) ;check that file exists
   
   ;Files may be missing when there were not enough sky frames
   ;for sky subtraction.
   if test eq 0 or nsky[i] lt 3 then begin
      print, 'Skipping slice...'+trim(i)
      if test eq 0 or nsky[i] lt 3 then continue
   endif
   im=readfits(skydir+'/'+fname,hdr,/silent)
   
   ;load stored centroids
   if cntrd_type eq 0 then begin
      xc=xypos[0,*,i]         
      yc=xypos[1,*,i]         
   endif else begin
      xc=cenxypos[0,*,i]         
      yc=cenxypos[1,*,i]
   endelse

   ;determine phot. apertures
   if aperture_type eq 0 then apr=aperture_size*aperture_array else $
      apr=fwmed[i]*aperture_array
   
   ;determine sky_annulus
   skyrad=sky_annulus
   
   ;aperture photometry
   aper,im,xc-0.5,yc-0.5,flux0,errap,sky,skyerr,epadu,apr,skyrad,badpix,/FLUX,/SILENT,/NAN
   
   ;add estimate of sky contribution to Poisson noise
   for k=0,nap-1 do begin
      area=!pi*apr[k]^2
      skyflux=area*illum[i]
      errap[k,*]=sqrt((epadu*errap[k,*])^2 + skyflux*epadu)
   endfor

   ;store results for image slice
   for k=0,nap-1 do fluxes[*,i,k]=flux0[k,*]
   err[*,i,*]=transpose(errap)
   skyarr[*,i]=sky
   serr[*,i]=skyerr
  
   ;print what slice I'm on every tenth index
   if i mod 10 eq 0 then print, 'Phot for slice...'+trim(i)
endfor

;save fluxes,errors,and sky arrays
save,fluxes,err,skyarr,serr,filename=dir+'/fluxes.sav'


;--------------------Light curve analysis----------------------
;preserve original flux array
flux=fluxes[*,*,*]
errflux=err
nslice=n_elements(flux[0,*,0])
;normalize fluxes
fnorm=fltarr(nstar,nap)
for i=0,nstar-1 do for j=0,nap-1 do begin
   fnorm[i,j]=median(fluxes[i,*,j])
   flux[i,*,j]/=fnorm[i,j]
   errflux[i,*,j]/=fnorm[i,j]
endfor

;compute 'global trend' (i.e. calibration curves)
cal=fltarr(nstar,nslice,nap)
fcal=flux*0.
rms=fltarr(nstar,nap)
skip=where(fwhm_flag eq 1)

;first pass
if ~keyword_set(mskip) then skip=[0,skip] else skip=[0,skip,mskip]
for j=0,nstar-1 do begin
   for i=0,nap-1 do begin
      cal[j,*,i]=medflux(transpose(flux[*,*,i]),skip=[j,skip],avg=avg)
      fcal[j,*,i]=flux[j,*,i]/cal[j,*,i]
      rms[j,i]=robust_sigma(fcal[j,*,i]-shift(fcal[j,*,i],1))/sqrt(2) ;stddev with low-pass filtering
   endfor
endfor

print, 'Source RMS values for plot aperture in array:'
print, rms[*,aperture_plot_index]
print, 'Sources skipped on first pass:'
print, skip
skip0=skip ;stars skipped due to fwhm cut and mskip

npass=3
;additional passes with rms cut
for p=1,npass-1 do begin
   for i=0,nap-1 do begin
      ind=where(rms[*,i] gt rms_cut*rms[0,i] or fnorm[*,i]/fnorm[0,i] gt 10. or rms[*,i] lt 0)
      skip=[skip0,ind]
      if i eq aperture_plot_index then begin
         skip3=skip ;keep track of sources skipped for primary aperture
      endif
      for j=0,nstar-1 do begin
         cal[j,*,i]=medflux(transpose(flux[*,*,i]),skip=[j,skip],avg=avg)
         fcal[j,*,i]=flux[j,*,i]/cal[j,*,i]
         rms[j,i]=robust_sigma(fcal[j,*,i]-shift(fcal[j,*,i],1))/sqrt(2) ;stddev with low-pass filtering
      endfor
   endfor
   print, 'Source RMS values for plot aperture in array:'
   print, rms[*,aperture_plot_index]
   print, 'Sources skipped on pass '+trim(p)+':'
   print, skip3
endfor
rind=where(skip3 eq -1,nr)
if nr gt 0 then remove,rind,skip3

;make a list of "good", similar brightness references
goodrefs=indgen(nstar)
remove,skip3,goodrefs

;clean calibrated flux arrays by clipping 3-sigma outliers
;this step is important if we wish to bin the data as in 
;Wilson et al. 2014. without biasing the points 
clip=3.
t=(time-min(time))*24d
;split data into individual ~15 min epochs
split_sets,t,0.07,parts,nparts=nparts,starts=starts,len=len
fcal2=fcal   ;store sigma-clipped fluxes
for j=0,nparts-1 do begin
   for i=0,nstar-1 do begin
      for k=0,nap-1 do begin
         part_inds=indgen(len[j])+starts[j]
         ftmp=fcal[i,part_inds,k]
                                ; box=21 ;box for running median
                                ;  fmed=ftmp*0. ;running median 
                                ;  for j=0,n_elements(ftmp)-1 do fmed[j]=median(ftmp[max([0,j-box/2]):min([n_elements(ftmp)-1,j+box/2])])
         rms1=robust_sigma(ftmp)
         med1=median_iter(ftmp,3,3)
         ind1=where(abs(ftmp-med1) gt clip*rms1,n1)
         if n1 gt 0 then fcal2[i,part_inds[ind1],k]=!values.f_nan
      endfor
   endfor 
endfor

;-------compute uncertainties in the calibrated fluxes
fcal_errs=fltarr(nstar,nslice)
i=aperture_plot_index
for j=0,nstar-1 do begin
   skip=[j,skip3]
   good=indgen(nstar) ;indices of all stars
   remove,skip,good ;indices of calibrators
   ng=n_elements(good)
   refbinerrs=fltarr(nparts,ng)
   for k=0,nparts-1 do begin ;loop over 15-min epochs
       npts=float(len[k])
      for q=0,ng-1 do begin
         refbinerrs[k,q]=stddev(flux[good[q],starts[k]:starts[k]+len[k]-1,i],/nan)*sqrt(npts/(npts-1.)) ;use unbiased estimator
      endfor
       ref_err=total(refbinerrs[k,*]^2)/float(ng)
       star_err=stddev(flux[j,starts[k]:starts[k]+len[k]-1.])*sqrt(npts/(npts-1.)) ;use unbiased estimator
       fcal_errs[j,starts[k]:starts[k]+len[k]-1.]=sqrt(ref_err^2 +star_err^2) ;same uncertainty for each point in given epoch
   endfor
endfor


;Bin fluxes in their ~15 minute groupings as in Wilson et al. 2014
;(Wilson et al. stack the actual images before doing photometry,
;but here I am simply going to bin together the higher cadence data).
binflux=fltarr(nparts,nstar)
binflux_err=fltarr(nparts,nstar)
bintimes=fltarr(nparts)
max_min_err=fltarr(nstar)
ind=indgen(nparts)
bad=where(len lt 5,nbad) ;ignore epochs with <5 points (sometimes 
;there is a final epoch with only a couple of images, likely the 
;dither pattern was interrupted to finish the observation) 
if nbad gt 0 then remove,bad,ind
if nbad gt 0 then begin
   bintimes=bintimes[ind]
   binflux=binflux[ind,*]
   binflux_err=binflux_err[ind,*]
   nparts-=nbad
endif

for j=0,nstar-1 do begin
   tmp=fcal2[j,*,aperture_plot_index] 
   for i=0,nparts-1 do begin
      tmp2=tmp[starts[i]:starts[i]+len[i]-1]
      good=where(finite(tmp2),ng)
      if ng gt 0. then binflux[i,j]=mean(tmp2[good]) else binflux[i,j]=1000.
      if ng gt 0 then binflux_err[i,j]=stddev(tmp2[good])/sqrt(ng*1.) else binflux_err[i,j]=1000.
      tmp2=t[starts[i]:starts[i]+len[i]-1]
      good=where(finite(tmp2),ng)
      if ng gt 0 then bintimes[i]=mean(tmp2[good]) else bintimes[i]=0.    
   endfor
   max_ind=where(binflux[*,j] eq max(binflux[*,j]),nmax)
   min_ind=where(binflux[*,j] eq min(binflux[*,j]),nmin)
   if nmax eq 1 and nmin eq 1 then begin
      if len[max_ind] lt 5 then binflux[max_ind,j]=0.
      if len[min_ind] lt 5 then binflux[min_ind,j]=0.
      max_ind=where(binflux[*,j] eq max(binflux[*,j]))
      min_ind=where(binflux[*,j] eq min(binflux[*,j]))
      max_min_err[j]=sqrt(binflux_err[max_ind,j]^2 + binflux_err[min_ind,j]^2)
      print, max_min_err
   endif
   ;stop
endfor

;determine the MAX-MIN of the binned time series 
maxmin=fltarr(nstar)
for i=0,nstar-1 do maxmin[i]=max(binflux[*,i])-min(binflux[*,i])

;determine the relative flux rms of all good references
ngoodref=n_elements(goodrefs)
rel_flux_rms=fltarr(ngoodref)
for i=0,ngoodref-1 do begin
   rel_flux_rms[i]=stddev(binflux[*,goodrefs[i]])
endfor
return_ref_rms={refs:goodrefs,rms:rel_flux_rms}
if keyword_set(test_apertures) then return
;^return before plotting when when looping over
;multiple apertures

;-----------------------Plotting------------------------------
;May require user modification
;To do: clean this up!
load8colors

;Make an unbinned plot of target and 1st good reference
plot,t,fcal[0,*,aperture_plot_index],psym=4,yr=[0.9,1.1],xtit='Time (hr)',ytit='Rel. Flux',chars=1
oplot,[-100,100],[1,1]
oplot,[-100,100],[1,1]
oplot,t,fcal[goodrefs[0],*,aperture_plot_index],psym=4,col=2
xyouts,0.1,1.09,'Target star',chars=1
xyouts,0.1,1.08,'Ref star',col=2,chars=1
stop

;make binned plots of target and all good references
ploterror,bintimes,binflux[*,0]/mean(binflux[*,0]),psym=4,binflux_err[*,0],yr=[0.94,1.08],xtit='Time (hr)',ytit='Rel. Flux',chars=1,/ys,thick=3
oploterror,bintimes,binflux[*,0]/mean(binflux[*,0]),binflux_err[*,0],psym=4,thick=3
oploterror,bintimes,binflux[*,0]/mean(binflux[*,0]),binflux_err[*,0],psym=0,thick=3
oplot,[-100,100],[1,1]
oplot,[-100,100],[1,1]
ng=n_elements(goodrefs)
for i=0,ng-1 do begin
   oploterror,bintimes,binflux[*,goodrefs[i]]/mean(binflux[*,goodrefs[i]]),binflux_err[*,goodrefs[i]],psym=4,col=i+2,errcol=i+2
   oploterror,bintimes,binflux[*,goodrefs[i]]/mean(binflux[*,goodrefs[i]]),binflux_err[*,goodrefs[i]],psym=0,col=i+2,errcol=i+2
endfor

xyouts,0.1,1.07,'Target Time Series',chars=1
maxmin0=max(binflux[*,0])-min(binflux[*,0])
xyouts,0.1,1.06,'MAX-MIN = '+trim(maxmin0),chars=1
cols=['red','blue','green','yellow','cyan','purple','orange', 'rose', 'ltgreen','pink',replicate('',21)]
xyouts,0.1,1.05,'Ref IDs:',chars=1.35
str=''
for i=0,ng-2 do str+=(trim(goodrefs[i])+' ('+cols[i]+'), ')
str+=(trim(goodrefs[ng-1])+' ('+cols[ng-1]+') ')
xyouts,0.5,1.05,str,chars=1.35
stop

;---------------------------Make .eps files---------------------
;***NOTE that /no_gv can be set on the mypsplot routine to supress
;opening the .eps files as they are created

;plot target and up to first 5 reference stars
plotsym,0,0.4,/fill
!p.thick=2
xtickname=replicate(' ',20)
xtitle=''
xmarg=[10.5,1]
ymarg=[0.1,0.5]
ysize=2.7
filename=dir+'/targ.eps'
mypsplot,file=filename,xsize=8,ysize=ysize,font=1,xmarg=xmarg,ymarg=ymarg

mednorm=median(fcal[0,*,aperture_plot_index])
plot,t,fcal[0,*,aperture_plot_index]/mednorm,psym=8,yr=[0.94,1.06],xtit=xtitle,ytit='',chars=0.45,xr=[0,max(t)*1.05],/xs,xtickname=xtickname
xyouts,-0.25,0.96, 'Rel. Flux',orient=90,chars=0.45
oplot,[-100,100],[1,1]
plotsym,8,0.9,thick=3,/fill
oploterror,bintimes,binflux[*,0]/mednorm,binflux_err[*,0],psym=8,thick=3,col=3,errcol=3
xyouts,0.18,0.83,tname,/norm,chars=0.45
xyouts,0.7,0.83,'MAX-MIN='+trim(maxmin[0],'(f5.3)'),/norm,chars=0.45,col=2
mypsplot,file=filename,/close
nrefs=n_elements(goodrefs)
ymarg=[0.1,0.5]

ytext=0.83
for i=0,nrefs-1 do begin
   if (i+2) mod 3 eq 0 or i eq nrefs-1 then begin
      ymarg=[4,0.5]
      xtickname=''
      xtitle='Time [hr]'
      ysize=2.7*1.35
      ytext=0.885
   endif else begin
      ymarg=[0.1,0.5]
      xtickname=replicate(' ',20)
      xtitle=''
      ysize=2.7
      ytext=0.83
   endelse
   plotsym,0,0.4,/fill
   filename=dir+'/ref_'+trim(i)+'_'+trim(goodrefs[i])+'.eps'
   mypsplot,file=filename,xsize=8,ysize=ysize,font=1,ymarg=ymarg,xmarg=xmarg
   mednorm=median(fcal[goodrefs[i],*,aperture_plot_index])
   plot,t,fcal[goodrefs[i],*,aperture_plot_index]/mednorm,psym=8,yr=[0.94,1.06],xtit=xtitle,ytit='Rel. Flux',chars=0.45,xr=[0,max(t)*1.05],/xs,xtickname=xtickname
   oplot,[-100,100],[1,1]
   plotsym,8,0.9,/fill
   oploterror,bintimes,binflux[*,goodrefs[i]]/mednorm,binflux_err[*,goodrefs[i]],psym=8,col=2,errcol=2
   xyouts,0.18,ytext,'Ref star #'+trim(goodrefs[i]),/norm,chars=0.45
   xyouts,0.7,ytext,'MAX-MIN='+trim(maxmin[goodrefs[i]],'(f5.3)'),/norm,chars=0.45,col=2
   mypsplot,file=filename,/close
endfor

;make seeing and global diagnostic
filename=dir+'/diag.eps'
plotsym,0,0.3,/fill
xmarg=[7,7]
mypsplot,file=filename,xsize=9.,ysize=ysize,font=1,xmarg=xmarg,ymarg=ymarg
plot,t,fwmed,psym=8,xtitle='Time [hr]',/nodata,chars=0.45,ys=5,yr=[0,10]
oplot,t,fwmed,psym=8,col=3
axis,yaxis=0,chars=0.45,ytitle='FWHM',col=3,yr=[0,10]
plot,t,cal[0,*,aperture_plot_index],psym=8,/noerase,xs=0,ys=5,xtitle='  ',ytickname=replicate(' ',20),chars=0.45,/nodata,yr=[0.2,1.2]
oplot,t,cal[0,*,aperture_plot_index],psym=8,col=8
axis,yaxis=1,chars=0.45,ytitle='Global trend',col=8,yr=[0.2,1.2]
mypsplot,file=filename,/close

;make finder
;mk_stack,dir,stack,xtarg,ytarg
;set_plot,'x'
;loadct,0
;tvdl,stack,pc=99.75,z1,z2
;set_plot,'ps'
;delta_x=max(xtarg)-min(xtarg)
;delta_y=max(ytarg)-min(ytarg)
;substack=stack[delta_x/2:n_elements(stack[*,0])-delta_x/2,delta_y/2:n_elements(stack[0,*])-delta_y/2]
filename=dir+'/finder.eps'

mypsplot,file=filename,xsize=10,ysize=10
;TVLCT, r, g, b, /Get
;TVLCT, Reverse(r), Reverse(g), Reverse(b)
;side=4.91520
;xr=[-1.*(side/2),side/2]
;yr=xr
;plotimage,substack,range=[z1,z2],/iso,chars=0.45,xr=xr,yr=yr,imgxrange=xr,imgyrange=yr,col=255,tickinterval=0.5,xtitle='Arcminutes',ytitle='Arcminutes'
;plotimage,substack,range=[z1,z2];,/iso,chars=0.45,xr=xr,yr=yr,imgxrange=xr,imgyrange=yr,col=255,tickinterval=0.5,xtitle='Arcminutes',ytitle='Arcminutes'
plot,findgen(10),findgen(10)
;xtarg2=xtarg*0.288/60.-side/2.
;ytarg2=ytarg*0.288/60.-side/2.

;xtarg_global=max(xtarg2)-delta_x*0.288/60./2.
;ytarg_global=max(ytarg2)-delta_y*0.288/60./2.

;dx=xtarg_global-xtarg2[1]
;dy=ytarg_global-ytarg2[1]

;xpos=(xypos[0,*,1]*0.288/60.-side/2.)+dx
;ypos=(xypos[1,*,1]*0.288/60.-side/2.)+dy

;tmp=trim(indgen(n_elements(xpos)))
;xyouts,xpos-0.1,ypos+0.1,tmp,chars=0.45,col=255
;plotsym,0,1.2
;oplot,[xpos[0]],[ypos[0]],psym=8,col=3
stop
mypsplot,file=filename,/close
stop

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;Concatenate LC .eps files into single pdf
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if nrefs gt 2 then npage=2 else npage=1
nperpage=3
cnt=0
for k=0,npage-1 do begin

      ;make tex file for page
      texfile=dir+'/lcs_'+trim(k)+'.tex'
      openw,lun,texfile,/get_lun
      printf,lun,'\documentclass{standalone}'
      printf,lun,'\usepackage{graphicx}'
      printf,lun,'\usepackage{array}'
      printf,lun,'\begin{document}'
      printf,lun,' '
      if k eq 0 then num=nperpage else num=min([nperpage,nrefs-2])
      for i=0,num-1 do begin
         if cnt eq 0 then epsfile=dir+'/targ.eps' else $
            epsfile=dir+'/ref_'+trim(cnt-1)+'_'+trim(goodrefs[cnt-1])+'.eps'
         printf,lun,'\includegraphics[width=1\textwidth]{'+epsfile +'}'
         cnt++
      endfor

     printf,lun,' '
     printf,lun,'\end{document}'
     free_lun,lun
     dvifile='lcs_'+trim(k)+'.dvi'
     pdffile='lcs_'+trim(k)+'.pdf'
     spawn, 'latex '+texfile
     spawn, 'dvipdf '+dvifile
     spawn, 'open '+pdffile+'&'
     spawn,'mv lcs_'+trim(k)+'.dvi '+dir+'/'
     spawn,'mv lcs_'+trim(k)+'.pdf '+dir+'/' 
     free_lun,lun
  endfor 
set_plot,'x'
end
