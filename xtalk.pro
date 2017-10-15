pro xtalk,im,alpha
;impliment xtalk correction for SoFI data as described here:
;
;input image is replaced with corrected image
;
dim1=n_elements(im[*,0])
dim2=n_elements(im[0,*])

rowsum=fltarr(dim2)
for i=0,dim1-1 do rowsum[i]=total(im[*,i])
rowsum=ones(1024)#rowsum

rowsum_512=rowsum
rowsum_512[*,0:511]=rowsum[*,512:1023]
rowsum_512[*,512:1023]=rowsum[*,0:511]

im=im-alpha*(rowsum+rowsum_512)
end
