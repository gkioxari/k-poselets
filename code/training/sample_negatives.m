function boxes=sample_negatives(pyr, img2f, f2img, model, numper)
numparts=model.numparts;
boxes=[];
cnt=0;
while(cnt<numper)

fail=false;
%allowed levels for the root
if(numparts>1)
	minscale=max(1,1-(min(cell2mat(model.scaleanchor))));
	maxscale=min(numel(pyr.feat), numel(pyr.feat)-(max(cell2mat(model.anchor))));
	if(maxscale-minscale<10) return; end
else
	minscale=1;
	maxscale=numel(pyr.feat);
end
%sample level for the root
i=minscale+ceil(rand*(maxscale-minscale));
currscale=pyr.scale(i);

%sample possible box
fsz=size(pyr.feat{i});
xmin=ceil(rand*(fsz(2)-model.sizes(1,2)+1));
ymin=ceil(rand*(fsz(1)-model.sizes(1,1)+1));
imgxmin=f2img(i,1)+f2img(i,3)*xmin;
imgymin=f2img(i,2)+f2img(i,4)*ymin;
boxes1=get_box_helper(imgxmin, imgymin, currscale, model.sizes(1,:));
boxes(cnt+1,1:4)=boxes1;
boxes(cnt+1,numparts*4+1)=i;

numparts=model.numparts;
for j=2:numparts
	%sample possible scale
	[scale, i1]=get_scale_in_pyramid(pyr, i, j, model);
	if(isempty(i1)) fail=true; break; end
	assert(~isempty(i1))	
	
	%sample possible deformation
	deformation=model.deformations(:,ceil(rand*size(model.deformations,2)));
	
	deformation=deformation';
	%get offset
	offset=get_offset_in_img(deformation, currscale,scale, j, model);
	boxes2=get_box_helper(imgxmin+offset(1), imgymin+offset(2), pyr.scale(i1), model.sizes(j,:));
	
	maximgx=f2img(i1,1)+f2img(i1,3)*size(pyr.feat{i1},2);
	maximgy=f2img(i1,2)+f2img(i1,4)*size(pyr.feat{i1},1);
	minimgx=f2img(i1,1)+f2img(i1,3)*1;
	minimgy=f2img(i1,2)+f2img(i1,4)*1;

	
	if(boxes2(1)<minimgx || boxes2(2)<minimgy || boxes2(3)>maximgx || boxes2(4)>maximgy) 
	%boxes2
	%[minimgx minimgy maximgx maximgy]
	%f2img(i1,:)	
%fail=true; fprintf('failbox\n');
	fail=true;
break; end
	
		%size(boxes2)
	boxes(cnt+1,(j-1)*4+1:j*4)=boxes2;
	boxes(cnt+1,numparts*4+j)=i1;
		
end
if(fail) continue; end
cnt=cnt+1;
end


function boxes=get_box_helper(x, y, scale, hogsize)
%hogsize is [ny nx]
h=hogsize(1)*scale;
w=hogsize(2)*scale;
boxes=[x(:) y(:) w h];
boxes(:,3:4)=boxes(:,3:4)+boxes(:,1:2);

function offset=get_offset_in_img(def, scale1, scale2, partnum, model)
d1=model.anchor{partnum}+def*scale2;
offset=d1*scale1;
