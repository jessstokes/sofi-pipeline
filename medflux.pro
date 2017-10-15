function medflux,farr,skip=skip,stop=stop,avg=avg
;farr is a flux array of form [nstar,nslice]
nslice=n_elements(farr[*,0])
nstar=n_elements(farr[0,*])
ftmp=farr

if keyword_set(skip) or (size(skip))[0] eq 1 then begin
    for i=0,nstar-1 do begin
        if total(i eq skip) gt 0 then ftmp[*,i]=!values.f_nan
    endfor
endif
if keyword_set(stop) then stop
;take median over nslices
if ~keyword_set(avg) then medflux=median(ftmp,dim=2,/even)
if keyword_set(avg) then begin
   medflux=fltarr(nslice)
   for i=0,nslice-1 do begin
       good=where(finite(ftmp[i,*]),ng)
       if ng gt 0 then medflux[i]=total(ftmp[i,good])/float(ng) else $
          medflux[i]=!values.f_nan
   endfor
endif
return,medflux
end
