function [scale, i2]=get_scale_in_pyramid(pyra, i, partnum, model)
%gets the location in pyramid, and relative scale, of the part number

%the scale step
scalestep=(2.0^(1/model.interval)); %pyra.scale(2)/pyra.scale(1);

%relative scale
s=model.scaleanchor{partnum};



scale=scalestep.^s;
i2=i+s;
if((i2>length(pyra.feat))||(i2<=0))
	i2=[]; 
	return;
end

