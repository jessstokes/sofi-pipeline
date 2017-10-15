function median_iter,arrayin,nsig,niter,sig=s,bind=bind

;calcule la mediane de facon iterative en rejetant
;les point  deviants de plus de nsig*sigma de la mediane
;sig=sigma, retourne sigma calcule de facon iterative
;bind=bad indices, indices des pixels rejetes

array=arrayin
iok=where(finite(array) ne 0,c)
if c lt 4 then return,!values.f_nan
m=median(array)
s=stddev(array,/nan)
for n=1,niter do begin
    bind=where(array gt (m+nsig*s) or array lt (m-nsig*s) or finite(array) eq 0)
    if (bind[0] ne -1) then array[bind]=!values.f_nan
    iok=where(finite(array) ne 0,c)
    if c lt 4 then return,!values.f_nan
    m=median(array)
    s=stddev(array,/nan)
endfor

return,m
end

