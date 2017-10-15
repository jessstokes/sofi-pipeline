; Function to obtain the value of a parameter in a FITS header
; Written to replace sxpar.pro from the idl-astro package 
; which does not work with the non-standard ESO fits headers
;
; Revision history:
; - December 1, 2010  : added warning when count = 0
;                       fixed bug in other warning (warn when count > 1, not < 1)
; - February 16, 2005 : created, VCG

FUNCTION esosxpar, header, name, count=count

count=0

N= N_ELEMENTS(header)
FOR i=0, N-1 DO BEGIN
    tmpstr    = header[i]
    tmpstrspl = STRSPLIT(tmpstr,'=',/EXTRACT)
    tmpvar    = tmpstrspl[0]
    tmpidx = STRPOS(tmpvar,name)
    IF tmpidx NE -1 THEN BEGIN
        IF count EQ 0 THEN res = STRTRIM((STRSPLIT(tmpstrspl[1],'/',/EXTRACT))[0],2)
	count = count + 1
    ENDIF
ENDFOR

IF count EQ 0 THEN print,'ESOSXPAR: Warning: parameter not found in header (reminder: capital-sensitive)'
IF count GT 1 THEN PRINT,'ESOSXPAR: Warning: parameter found more than once in header'
IF NOT KEYWORD_SET(res) THEN res = ''

res=trim((strsplit(res,"'",/EXTRACT))[0])

RETURN,res
END
