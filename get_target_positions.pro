pro get_target_positions,outdir
manual_target_pos=1
if ~file_test(outdir+'/tpos.txt') then begin
readcol,outdir+'/obslog.txt',type,ut,t,filt,exptime,file,format='(a,a,d,a,f,a)'
load8colors
nf=n_elements(file)
im0=readfits(file[0],hdr)
dim1=n_elements(im0[*,0])
dim2=n_elements(im0[0,*])
box=31.
xx=findgen(box)#ones(box)
yy=ones(box)#findgen(box)
xtarg=fltarr(nf)
ytarg=fltarr(nf)
num=fltarr(nf)
tmp=24d * (t-min(t))

;split BAM data into their ~15 min groupings
split_sets,tmp,0.1,parts,nparts=nparts,starts=starts,len=len

for i=0, nf-1 do begin
   im=readfits(file[i],hdr)
   if len[parts[i]] ge 3 then begin
      ind=where(parts eq parts[i] and file ne file[i],nind)
   endif else begin
      ind=i-1
      nind=1
   endelse
   ;do a stupid sky subtraction just to get preliminary positions
   skyfiles=file[ind]
   print, 'Index:'+trim(i)
   print, 'Parts:'+trim(parts[i])
   print, 'Len:'+trim(len[parts[ind]])
   print,'skyfiles:'
   print,skyfiles
   if n_elements(skyfiles) lt 2 then stop
   if nind ge 3 then  sky=medfits(skyfiles) else sky=readfits(file[ind[0]])
   im2=im-sky   
   
   ;Find all sources in image and identify target via vector matching
   im2=smooth(im2,3)
   find,im2,x1,y1,flux,sharp,round,20.,10.,[-1,1],[0.1,10],/silent
   nsrc=n_elements(x1)

   ;user to identify target position in first image
   if i eq 0 then begin
      print, '>>>>>>>>>>Click on target (first click) plus 1-3 bright nearby reference stars (second click)'
      print, '>>>>>>>>>>Chosen reference must be a point source!'
      print, '>>>>>>>>>>Middle-click (option/alt-clik with Mac) to exit'
      grab_im_coords,im2,xpos0,ypos0
      if n_elements(xpos0) lt 2 or total(xpos0 gt dim1 or xpos0 lt 0 or ypos0 gt dim2 or ypos0 lt 0) gt 0 then message, $
         'Wrong number of sources, or sources out of bounds!'
      nclick=n_elements(xpos0)
      for j=0,nclick-1 do begin
         cntrd,im2,xpos0[j],ypos0[j],x_new,y_new,5.,/silent
         xpos0[j]=x_new
         ypos0[j]=y_new
      endfor
      xtarg0=xpos0[0]
      ytarg0=ypos0[0]
  
      ;define vectors between target and chosen references
      xvec0=xpos0-xtarg0
      yvec0=ypos0-ytarg0
      remove,[0],xvec0,yvec0
   endif
      nv=n_elements(xvec0)-1
      
   ;define all vectors between star pairs
   xvectors=fltarr(nsrc,nsrc)
   yvectors=fltarr(nsrc,nsrc)
   for j=0,nsrc-1 do begin
      for k=0,nsrc-1 do begin
         xvectors[j,k]=x1[j]-x1[k]
         yvectors[j,k]=y1[j]-y1[k]
      endfor
   endfor

;find vectors that match xvec0 and yvec0 within 1 pixel
;if no match or >1 match for first vector, try subsequent
   match=0
   cnt=0
   while match eq 0 and cnt lt nv do begin
      dist=sqrt((xvectors-xvec0[cnt])^2 + (yvectors-yvec0[cnt])^2)
    ;  stop
      ind=where(dist lt 1,ni)
      if ni eq 1 then begin
         targind=ind/nsrc
         match=1
         x2=x1[targind]
         y2=y1[targind]
      endif else begin
         cnt++
      endelse
   endwhile
   if match eq 0 then begin
      print, 'Warning: target not found in slice...'+trim(i)+'...'
      tvdl,im2,z1,z2,/med
      plotimage,im2,range=[z1,z2],/iso
      oplot,x1,y1,psym=4,col=2,thick=2
      stop
      if keyword_set(manual_target_pos) then begin
         print,'Click on target position, then middle-click (alt-click on Mac) to exit:'
         grab_im_coords,im2,x2,y2
      endif
   endif

xtarg[i]=x2
ytarg[i]=y2
;visual aid
tvdl,im2,pc=99,z1,z2
plotimage,im2,range=[z1,z2],/iso
oplot,[xtarg[i]],[ytarg[i]],psym=4,col=2,thick=1

endfor
writecol_jr,outdir+'/tpos.txt',xtarg,ytarg,t,num,replicate('   ',nf),filt,replicate('   ',nf),file,width=1000,format='(f,f,d,f,a,a,a,a)'
endif
end
