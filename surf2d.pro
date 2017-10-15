function surf2d,x,y,p
z=p[0] + p[1]*x + p[2]*y + p[3]*x^2 + p[4]*y^2 + p[5]*x*y 
return,z
end
