pro flat_field,flat_dir,outdir

;reduce the "special" flatfields"
;A = flat
;AM = masked flat
;SM = shade patterns in masked on flat
;dS = AM-A = difference in shade between masked and non-masked flat
;S = SM - dS = shade pattern in non-masked flat

f=file_search(flat_dir+'/*_xtalk.fits')
a=mk_cube(f)

;remove xtalk for each file
alpha=1.4d-5
for i=0,nf-1 do begin
  im=a[*,*,i]
  xtalk,im,alpha
  a[*,*,i]=im
endfor

;J flats _should_ be in expected order, but user
;should CHECK this!!!
foff=a[*,*,0]+a[*,*,7]
fon=a[*,*,3]+a[*,*,4]
foff_mask=a[*,*,1]+a[*,*,6]
fon_mask=a[*,*,2]+a[*,*,5]

;extract shade patterns from masked flats
s_off_mask = median(foff_mask[5:150,*],dim=1)
s_on_mask = median(fon_mask[5:150,*],dim=1)

;compute difference in shade between masked and non-masked flats
ds_off=median((foff_mask-foff)[500:600,*],dim=1)
ds_on=median((fon_mask-fon)[500:600,*],dim=1)

;compute real shade patterns
s_off = s_off_mask - ds_off
s_on = s_on_mask- ds_on

;remove shade from flats
for i=0,1023 do begin
   foff[i,*]-=s_off
   fon[i,*]-=s_on
endfor

;subtract foff from fon
mflat=fon-foff
;stop
writefits,outdir+'/'+'mflat.fits',mflat
end
