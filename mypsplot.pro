pro mypsplot,file=file,xsize=xsize,ysize=ysize,encapsulated=encapsulated,bits_per_pixel=bits_per_pixel,color=color,font=font,close=close,isolatin=isolatin,tt_font=tt_font,no_gv=no_gv,xmarg=xmarg,ymarg=ymarg
;INITIALIZE OR CLOSE AND DISPLAY A PS PLOT
if ~keyword_set(close) then begin
;DEVICE DEFAULTS
if ~keyword_set(xsize) then xsize=12
if ~keyword_set(ysize) then ysize=12
if ~keyword_set(encapsulated) then encapsulated=1
if ~keyword_set(bits_per_pixel) then bits_per_pixel=8
if ~keyword_set(color) then color=1
set_plot,'ps'

;OTHER DEFAULTS
if ~keyword_set(xmarg) then !x.margin=[8,3] else !x.margin=xmarg
if ~keyword_set(ymarg) then !y.margin=[4,2] else !y.margin=ymarg
!p.font=0
!p.thick=2
if ~keyword_set(font) then font=0
case font of
   0: sfont='NewCenturySchlbk-Roman'
   1: sfont='Helvetica'
end

;PREPARE TO PLOT
device,set_font=sfont,tt_font=tt_font
device,filename=file,xsize=xsize,ysize=ysize,encapsulated=encapsulated,bits_per_pixel=bits_per_pixel,color=color,isolatin=isolatin
endif else begin
   device,/close
 if ~keyword_set(no_gv) then  spawn, 'open '+file+'&'
endelse
end
