pro tvdl,imt,z1,z2,med=med,moy=moy,nsig=nsig,log=log,ls=ls,pc=pc,$
         box=box,im=im,setz=setz,silent=silent,true=true,nodisplay=nodisplay,ret_im=ret_im

;display an image
;ls=logarithmic scale factor
;pc=per centile
;true=1,2,3 pour truecolor images

on_error,2
im=imt[*,*,0]

if (keyword_set(box)) then begin
    s=size(im,/dimensions) & dimx=s[0] & dimy=s[1]
    bx=box[0]
    if (n_elements(box) eq 2) then by=box[1] else by=bx
    im=im[dimx/2-bx/2:dimx/2-bx/2+bx-1,dimy/2-by/2:dimy/2-by/2+by-1]
endif

tablesize=!d.table_size

minimum=min(im,/nan) & maximum=max(im,/nan)
if (keyword_set(log)) then begin
    if (not keyword_set(ls)) then ls=10000.

    if (n_elements(z1) ne 0 and not keyword_set(setz)) then begin
        im=(im-z1)/(z2-z1)*ls>0.+1.
        z1l=alog10(1.)
        z2l=alog10((z2-z1)/(z2-z1)*ls>0.+1.)
    endif else begin
        im=(im-minimum)/(maximum-minimum)*ls+1.
    endelse

    im=alog10(im)
endif

if (keyword_set(med) or keyword_set(moy)) then begin
    if (keyword_set(med)) then m=median(im)
    if (keyword_set(moy)) then m=mean(im,/nan)

    sig=stddev(im,/nan)
    if (n_elements(nsig) eq 0) then nsig=1.
    z1=m-nsig*sig
    z2=m+nsig*sig
endif

if (keyword_set(pc)) then begin
    npts=n_elements(im)
    sind=sort(im)
    pc1=pc[0]/100.
    if (n_elements(pc) eq 1) then pc2=pc1 else pc2=pc[1]/100.
    z1=im[sind[npts*(1.-pc1)/2.]]
    z2=im[sind[npts*(pc2+1.)/2.]]
endif

if ((n_elements(z1) eq 0 or keyword_set(setz)) and ~keyword_set(med)) then begin
    z1=min(im,/nan)
    z2=max(im,/nan)
    if (keyword_set(log)) then begin
        ;les z1 et z2 ont ete donnes par les valeur log
        ;donc on convertit
        z1l=z1 & z2l=z2
        z1=(10^(z1l)-1.)/ls*(maximum-minimum)+minimum
        z2=(10^(z2l)-1.)/ls*(maximum-minimum)+minimum
    endif
        
endif

if (keyword_set(log)) then $
    im=( (tablesize-1)*(im-z1l)/(z2l-z1l) ) > 0. < (tablesize-1) $
else $
    im=( (tablesize-1)*(im-z1)/(z2-z1) ) > 0. < (tablesize-1)

im=byte(im)

s=size(im,/dimensions) & dimx=s[0] & dimy=s[1]
zoom=(!d.x_size/float(dimx)) < (!d.y_size/float(dimy))
im=congrid(im,round(dimx*zoom),round(dimy*zoom))
if ~keyword_set(nodisplay) then tv,im
ret_im=im
if ~keyword_set(silent) then begin
    print,'z1:',z1
    print,'z2:',z2
    if (keyword_set(log)) then suffix=' (log)' else suffix=''
    if (keyword_set(med)) then print,'median'+suffix+':',m
    if (keyword_set(moy)) then print,'moyenne'+suffix+':',m
    if (n_elements(sig) ne 0) then print,'sigma'+suffix+':',sig
endif

if keyword_set(true) then begin
    tvlct,v0,v1,v2,/get
    imtmp=im
    if (true eq 1) then begin
        im=bytarr(3,round(dimx*zoom),round(dimy*zoom))
        im[0,*,*]=v0[imtmp]
        im[1,*,*]=v1[imtmp]
        im[2,*,*]=v2[imtmp]
    endif
    if (true eq 3) then begin
        im=bytarr(round(dimx*zoom),3,round(dimy*zoom))
        im[*,0,*]=v0[imtmp]
        im[*,1,*]=v1[imtmp]
        im[*,2,*]=v2[imtmp]
    endif
    if (true eq 3) then begin
        im=bytarr(round(dimx*zoom),round(dimy*zoom),3)
        im[*,*,0]=v0[imtmp]
        im[*,*,1]=v1[imtmp]
        im[*,*,2]=v2[imtmp]
    endif
endif
end
