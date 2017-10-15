pro mk_stack,outdir,stack,xtarg,ytarg
readcol,outdir+'/tpos.txt',xtarg,ytarg,time,num,filt,files,format='(f,f,d,f,a,a)'
if outdir eq 'out_1010' then begin
ind=indgen(137)
remove,indgen(40),ind
files=files[ind] ;remove portion where target positioned poorly
;xypos=xypos[*,*,ind]
xtarg=xtarg[ind]
ytarg=ytarg[ind]
;cenxypos=cenxypos[*,*,ind]
;nsky=nsky[ind]
;fwhm=fwhm[*,ind,*]
time=time[ind]
end

x0=xtarg[0]
y0=ytarg[0]
nf=n_elements(files)
arr=fltarr(1024+round(max(xtarg)-min(xtarg)), 1024+round(max(ytarg)-min(ytarg)),nf)
sz=size(arr)
dim1=sz[1]
dim2=sz[2]

x_max=max(xtarg)
y_max=max(ytarg)
dir=outdir+'/skysub'
for i=0,nf-1 do begin
   pos1=strpos(files[i],'.fits')
    pos2=strpos(files[i],'SOFI')
   tmp=strmid(files[i],pos2,pos1-pos2)
   fname=tmp+'_skysub.fits'
   
   im=readfits(dir+'/'+fname,h)
   dx=round(x_max-xtarg[i])
   dy=round(y_max-ytarg[i])
   arr[dx:dx+1024-1,dy:dy+1024-1,i]=im
endfor
stop
stack=median(arr,dim=3)
tvdl,stack,z1,z2,pc=99.5

if 0 then begin
plotimage,stack,range=[z1,z2],/iso
restore,outdir+'/xypos.sav'
xy=xypos[*,*,0]
xoff=xy[0,0]-min(xtarg)
yoff=xy[1,0]-min(ytarg)
xy[0,*]+=xoff
xy[1,*]+=yoff
load8colors
xyouts,xy[0,*],xy[1,*],trim(indgen(n_elements(xy[0,*]))),col=2,chars=1.7
endif
end
