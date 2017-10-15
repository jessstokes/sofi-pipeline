function medfits,flist,prefix=prefix,suffix=suffix,rns=rns,dir=dir,gz=gz,$
                 exten_no=exten_no,silent=silent,nzero=nzero,hdr=h,even=even,$
                 clip=clip,domean=domean

;Calcule et retourne l'image mediane de plusieurs fichiers fits.
;
;flist: vecteur string des noms de fichiers
;       ou liste des # de fichiers, scalaire string, format '1-10,12,15-18'
;       ou integer array des numeros de fichiers
;prefix=prefix: prefixe des noms de fichiers
;suffix=suffix: suffixe des noms de fichier, i.e., entre le "####" et
;               le ".fits"
;rns=rns: "Read'N Skip", integer array de dimension 2.
;         De flist, lit sequentiellement rns[0] 
;         fichiers et saute rns[1] fichiers
;dir=repertoire
;/gz: pour fichiers compresses avec gzip
;exten_no=exten_no: extension fits a lire
;nzero=nzero: nombre de chiffres dans le compteur numerique de fichiers
;/silent: pas d'affichage
;
;clip=number of sigma for clipping median
;/domean: to do mean instead of median

fnames=filelist(flist,nfiles,prefix=prefix,suffix=suffix,dir=dir,gz=gz,nzero=nzero,rns=rns)

;obtient dimension des images a partir du premier header
h=headfits(fnames[0],exten=exten_no,silent=silent)
dim1=sxpar(h,'naxis1') & dim2=sxpar(h,'naxis2')

if dim1*dim2*nfiles gt 5.e7 then split=1 else split=0
if keyword_set(exten_no) then split=0

;On charge tout dans un seul cube
if split eq 0 then begin
    if ~keyword_set(silent) then print,'Direct median of the data cube ('+$
      strtrim(dim1,2)+'x'+strtrim(dim2,2)+'x'+strtrim(nfiles,2)+')'
    cube=fltarr(dim1,dim2,nfiles,/nozero)
    for n=0,nfiles-1 do cube[*,*,n]=readfits(fnames[n],exten_no=exten_no,silent=silent)
    if nfiles eq 1 then return,cube[*,*,0]
    
    ;clip if desired
    if keyword_set(clip) then begin
        tmp1=cube
        mtmp=median(cube,dim=3)
        for k=0L,nfiles-1 do tmp1[0:dim1-1,0:dim2-1,k]-=mtmp
        tmp1=abs(tmp1)
        sig=median(tmp1,dim=3)
        ibad=where(total(finite(tmp),3) lt 3,nbad)
        if nbad gt 0 then sig[ibad]=!values.f_nan
        for k=0L,nfiles-1 do begin
            ibad=where(tmp1[0:dim1-1,0:dim2-1,k]/sig gt clip/0.6745,cbad)
            if cbad gt 0 then cube[ibad+k*dim1*dim2]=!values.f_nan
        endfor
        deletevar,tmp1
    endif

    if ~keyword_set(domean) then return,median(cube,dimension=3,even=even)
    if keyword_set(domean) then return,total(cube,3,/nan)/(total(finite(cube),3)>1)
endif

;On fait plusieurs tranches

;image qui contiendra l'image de sortie
out = fltarr(dim1,dim2)

;determine pas pour que les tranches ne contienne pas plus de 2^22 pixels
;pas=pas sur la deuxieme dimension
pas=ceil(dim2/(dim1*dim2*nfiles/2.^22))
nslice=ceil(float(dim2)/pas)

if ~keyword_set(silent) then print,strtrim(nslice,2)+' slices will be made to handle the data cube ('+$
  strtrim(dim1,2)+'x'+strtrim(dim2,2)+'x'+strtrim(nfiles,2)+')'
t = systime(1)

time=dblarr(nslice)
tmp = fltarr(dim1,pas,nfiles)
for n=0,nslice-1 do begin
    time[n]=systime(1)
    debut = n*pas ;on calcule la position du début de la Nieme tranche
    fin = (n+1)*pas-1 ;on calcule la position de la fin de la Nieme tranche

    ;si ~silent, affiche a quelle tranche on en est rendu
    if ~keyword_set(silent) then print,'slice '+strtrim(n+1,2)+'/'+strtrim(nslice,2)+'-> ('+$
      strtrim(dim1,2)+'x'+strtrim(fin-debut+1,2)+'x'+strtrim(nfiles,2)+') ... '+strtrim(systime(1)-time[0],2)+' s'+$
      ' (time remaining: '+strtrim( (systime(1)-time[(n-5)>0])/(5<n)*(nslice-n) ,2)+' s)'

    if n eq (nslice-1) then begin
        fin = dim2-1
        tmp=fltarr(dim1,fin-debut+1,nfiles)
        pas=fin-debut+1
    endif

    for i = 0,nfiles-1 do begin
        fxread,fnames[i],data,hdr,-1,-1,debut,fin
        tmp[*,*,i] = data
    endfor  

    ;clip if desired
    if keyword_set(clip) then begin
        tmp1=tmp
        mtmp=median(tmp,dim=3)
        for k=0L,nfiles-1 do tmp1[0:dim1-1,0:pas-1,k]-=mtmp
        tmp1=abs(tmp1)
        sig=median(tmp1,dim=3)
        ibad=where(total(finite(tmp),3) lt 3,nbad)
        if nbad gt 0 then sig[ibad]=!values.f_nan
        for k=0L,nfiles-1 do begin
            ibad=where(tmp1[0:dim1-1,0:pas-1,k]/sig gt clip/0.6745,cbad)
            if cbad gt 0 then tmp[ibad+k*dim1*pas]=!values.f_nan
        endfor
        deletevar,tmp1
    endif

    if ~keyword_set(domean) then out[*,debut:fin] = median(tmp,dimension=3,even=even)
    if keyword_set(domean) then out[*,debut:fin] = avg(tmp,2,/nan)
;total(tmp,3,/nan)/(total(finite(tmp),3)>1)
    
endfor
print,'Total time: '+strtrim((systime(1)-time[0]),2)+' s'

return,out
end
