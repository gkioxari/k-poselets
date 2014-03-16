function [pyra, img2f, f2img]=featpyramid_plus(img, model)
%compute featpyramid
pyra=featpyramid2(img, model);
levels=1:length(pyra.feat);
padx=pyra.padx;
pady=pyra.pady;
scales=pyra.scale;


%for every level of the pyramid, store the transformation from the resp array to image coordinates, and vice versa.
%This will allow us to simply transform between the different levels of the pyramid (by going to the image coordinates 
% and coming back.
% f2img is the transformation from the hog coordinates to the image coordinates and img2f is the other one
% Both these are stored as [x_offset y_offset x_multiplier y_multiplier]
for l=levels
	scale=scales(l);
	%x_img=(x_f-1-padx)*scale+1		
f2img(l,:)=[(1-scale*(1+padx)) (1-scale*(1+pady)) scale scale];
	img2f(l,:)=[ (-1/scale+1+padx)  (-1/scale+1+pady)  1/scale 1/scale];
end
