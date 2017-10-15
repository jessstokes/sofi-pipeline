pro remove_xtalk,indir,xoutdir,skip=skip
files=file_search(indir+'/*.fits')
alpha=1.4d-5

t1=systime(1)
dim1=1024
dim2=1024
nfiles=n_elements(files)
for i=0, nfiles-1 do begin
   a=readfits(files[i],hdr)
   pos1=strpos(files[i],'.fits')
   pos2=strpos(files[i],'SOFI.20')
   fname1=strmid(files[i],pos2,pos1-pos2)
   im=a
   if ~keyword_set(skip) then begin 
      xtalk,im,alpha
   endif
   writefits,xoutdir+'/'+fname1+'_xtalk.fits',im,hdr
endfor
print, 'Crosstalk removal for...'+trim(i)+'/'+trim(nfiles)+'...images finished'
t2=systime(1)
print,'Crosstalk removal of '+trim(cnt)+' took '+trim(t2-t1)+' seconds'
t1=systime(1)
end
