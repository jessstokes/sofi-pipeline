pro split_sets,vsplit,thr,parts,nparts=nparts,starts=starts,len=len
;INPUTS:
;splits a vector with gaps larger than 'thr' into parts
;thr--minimum gap size
;RETURNS:
;parts--integer vector of length vsplit, indicating which part
;       element belongs to
;nparts--number of parts vsplit is split into
;starts--array containing index locations of the first element of each
;        set
;len--length of each vector in set
nv=n_elements(vsplit)
cnt=0
parts=intarr(nv)
parts[0]=0
starts=0
for i=1,nv-1 do begin
   if abs(vsplit[i]-vsplit[i-1]) gt thr then begin
      cnt++
      starts=[starts,i]
   endif
   parts[i]=cnt
endfor
nparts=cnt+1
len=intarr(nparts)
for i=0,nparts-1 do begin
if i ne nparts-1 then len[i]=starts[i+1]-starts[i] else $
   len[i]=nv-starts[i]
endfor
end
