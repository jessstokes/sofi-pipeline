pro grab_im_coords,image,xpos,ypos,xwin=xwin,noplot=noplot,circx=circx,circy=circy,pc=pc
;Grab image coordinates by poiting and clicking
;Left-clik (or one-button click) to select points, middle-click (or
;alt-click on Mac) to exit.  Mac users may have to modify their X
;window settings for this to work properly.

load8colors
original=image
s=size(image)
dimx=s[1]
dimy=s[2]

;use correct aspect ratio for window
if ~keyword_set(xwin) then xwin=500.
ywin=xwin*dimy/dimx

;display window
windex=5 ;arbitrary
window,windex,retain=2,xsize=xwin,ysize=ywin

;display image using tvdl
tvdl,image,z1,z2,/med
;display image using plotimage
plotimage,image,range=[z1,z2],ximgrange=[0,dimx],yimgrange=[0,dimy]

;cirle preselected points
if keyword_set(circx) and keyword_set(circy) then begin
   if n_elements(circx) ne n_elements(circy) then message, $
      'circx and circy must have same size'
   for i=0,n_elements(circx)-1 do begin
      hs=5 ;half-side of box
      xx=circx[i]
      yy=circy[i]
     
      ;plot square around position
      plotsym,8,2.5
      oplot,[xx],[yy],psym=8,col=3
   endfor 
endif 

if ~keyword_set(noplot) then tmp=image
;grab coordinates with mouse clicks and store in vectors
if !d.name ne 'X' then stop ;just a check

    ;get positions on-click until abort
    abort=0
    flag=0
    while abort eq 0 do begin
       if flag eq 0 then print, 'Click on image to grab pixel coordinates.'
       if flag eq 0 then print, 'Hit middle button to abort.'
       cursor,x,y,/data,/down ;grab cursor location in normalized coords
       if !mouse.button eq 2 then begin
          abort=1 ;middle button aborts without grabbing data
          goto, endloop
       endif
       x=x ;pixel coords
       y=y
       print, 'Input coords: '+trim(x)+' '+trim(y)
      if ~keyword_set(noplot) then begin
         oplot,[x],[y],psym=4,col=2,thick=3
      endif
       if flag eq 0 then begin
          xpos=x
          ypos=y
          flag=1
       endif else begin
          xpos=[xpos,x]
          ypos=[ypos,y]
       endelse
       endloop:
    endwhile
wdelete,windex
 end
