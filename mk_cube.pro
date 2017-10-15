function mk_cube,flist,etime=etime,chip=chip,nodata=nodata,dim1=dim1,dim2=dim2,dim3=dim3
;flist--a string vector of fits files
;returns: a data cube
hdr=headfits(flist[0])
dim1=sxpar(hdr,'NAXIS1') & dim2=sxpar(hdr,'NAXIS2') ;find dimensions
n=n_elements(flist) & dim3=n
if ~keyword_set(nodata) then cube=fltarr(dim1,dim2,n) ;create array
etime=fltarr(n)
filter=strarr(n)
chip=intarr(n)
for i=0, n-1 do begin
    if ~keyword_set(nodata) then cube[*,*,i]=readfits(flist[i],/silent)
    h=headfits(flist[i])
    etime[i]=float(sxpar(h,'EXPTIME'))
    filter[i]=sxpar(h,'FILTER')
    chip[i]=fix(sxpar(h,'CHIP'))
endfor
if ~keyword_set(nodata) then return,cube else return,0
end
