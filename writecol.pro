pro writecol,fname,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16,v17,v18,v19,v20,v21,v22,v23,v24,v25,v26,v27,v28,v29,v30,format=format,header=header
openw,funit,fname,/get_lun
if keyword_set(header) then for n=0,n_elements(header)-1 do printf,funit,header[n]

nlines=n_elements(v1)
case (n_params()-1) of
1: for n=0l,nlines-1 do printf,funit,v1[n],format=format
2: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],format=format
3: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],format=format
4: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],format=format
5: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],format=format
6: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],format=format
7: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],format=format
8: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],format=format
9: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],format=format
10: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],format=format
11: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],format=format
12: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],format=format
13: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],format=format
14: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],format=format
15: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],format=format
16: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],format=format
17: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],format=format
18: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],v18[n],format=format
19: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],v18[n],v19[n],format=format
20: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],v18[n],v19[n],v20[n],format=format
21: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],v18[n],v19[n],v20[n],v21[n],format=format
22: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],v18[n],v19[n],v20[n],v21[n],v22[n],format=format
23: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],v18[n],v19[n],v20[n],v21[n],v22[n],v23[n],format=format
24: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],v18[n],v19[n],v20[n],v21[n],v22[n],v23[n],v24[n],format=format
25: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],v18[n],v19[n],v20[n],v21[n],v22[n],v23[n],v24[n],v25[n],format=format
26: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],v18[n],v19[n],v20[n],v21[n],v22[n],v23[n],v24[n],v25[n],v26[n],format=format
27: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],v18[n],v19[n],v20[n],v21[n],v22[n],v23[n],v24[n],v25[n],v26[n],v27[n],format=format
28: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],v18[n],v19[n],v20[n],v21[n],v22[n],v23[n],v24[n],v25[n],v26[n],v27[n],v28[n],format=format
29: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],v18[n],v19[n],v20[n],v21[n],v22[n],v23[n],v24[n],v25[n],v26[n],v27[n],v28[n],v29[n],format=format
30: for n=0l,nlines-1 do printf,funit,v1[n],v2[n],v3[n],v4[n],v5[n],v6[n],v7[n],v8[n],v9[n],v10[n],v11[n],v12[n],v13[n],v14[n],v15[n],v16[n],v17[n],v18[n],v19[n],v20[n],v21[n],v22[n],v23[n],v24[n],v25[n],v26[n],v27[n],v28[n],v29[n],v30[n],format=format
endcase
free_lun,funit
end
