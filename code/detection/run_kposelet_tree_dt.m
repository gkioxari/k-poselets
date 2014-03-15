function [boxes resp]=run_kposelet_tree(pyra, img2f,f2img, model, thresh, use_sse)
%% function boxes=run_kposelet_tree(img, model, thresh, [use_sse])
%% Assumes the model is a tree, with the first poselet as the root
%% Uses Ross Girshick's fast_bounded_dt to speed things up.
%% Optionally uses super-fast fconv instead of the slow, compatible version

if(~exist('use_sse', 'var'))
	use_sse=false;
end


%this code generalizes to more than 3 parts per triplet
numparts=model.numparts;


interval=model.interval;
levels=1:length(pyra.feat);

%run all detectors on all levels of the pyramid. Store responses in cell array resp. 
%resp{i}{j} is response of jth filter on ith pyramid level
if(use_sse)
	for k=1:numel(model.w)
		w{k}=single( model.w{k});
	end
end

for l=levels
	if(use_sse)
		resp{l}=fconvsse(single(pyra.feat{l}), w, 1, model.numparts);
	else
		resp{l}=fconv(pyra.feat{l}, model.w, 1, model.numparts);
	end
	    	
end

padx=pyra.padx;
pady=pyra.pady;
scales=pyra.scale;
boxes=zeros(10000, 4*numparts+numparts+1);
cnt=0;

%maximum deformation
maximum_deformation=max(abs(model.deformations(:)));

%for each response array of the first filter
for i=levels
    scrf=resp{i}{1};
    currscale=scales(i);
    xind=[1:size(scrf,2)]';
    yind=[1:size(scrf,1)]';
    imgxind=f2img(i,1)+f2img(i,3)*xind;
    imgyind=f2img(i,2)+f2img(i,4)*yind;


	%for every other filter
	for j=2:numparts
		
		%initialize stuff
		bestscr=-inf*ones(size(scrf));
		better=false(size(scrf));
		tmp=zeros(size(scrf));
		tmpx=zeros(size(scrf));
		tmpy=zeros(size(scrf));

		mx1=-inf*ones(size(scrf));
		my1=-inf*ones(size(scrf));
		ms1=-inf*ones(size(scrf));


		defw=model.defw{j};
		anchor=model.anchor{j};
		deformations=model.deformations;

		
		%get index into pyramid. scale is the relative scale over current scale and i1 is index into pyra.feat
		[scale, i1]=get_scale_in_pyramid(pyra, i, j, model);
			
		%do stuff only if this did not fall off the pyramid continue;
		if(~isempty(i1))			

			%load up the corresponding part response
			scrtmp=resp{i1}{j};

			%re-weigh deformation weights according to scale : deformations are costlier in coarser scales
			defw2=defw.*[scale scale scale^2 scale^2];

			%maximum deformation at this scale
			maxdef2=maximum_deformation*scale;

			%do distance transform
			[M, Ix, Iy]=fast_bounded_dt(scrtmp, -defw2(3), defw2(1), -defw2(4), defw2(2), maxdef2);

			%get the offsets that we care about
			offset=currscale*(anchor);
	
			%get the hog cells we want the score for
			xind1=round(img2f(i1,1)+img2f(i1,3)*(imgxind+offset(1)));
			yind1=round(img2f(i1,2)+img2f(i1,4)*(imgyind+offset(2)));

			%anything outside the response map is obviously ruled out
			I=(xind1>=1 & xind1<=size(scrtmp,2));
			J=(yind1>=1 & yind1<=size(scrtmp,1));
				
			%get score and compare it with current best	
			better(:)=false;
			better(yind(J),xind(I))=(M(yind1(J),xind1(I)))>bestscr(yind(J),xind(I));
			tmp(yind(J), xind(I))=(M(yind1(J),xind1(I)));
			
			%get the part locations that maximize scores
			tmpx(yind(J), xind(I)) = f2img(i1,1)+f2img(i1,3)*Ix(yind1(J), xind1(I));
			tmpy(yind(J), xind(I)) = f2img(i1,2)+f2img(i1,4)*Iy(yind1(J), xind1(I));	
			
			%assign wherever better
			bestscr(better)=tmp(better);

			%record offsets where detected, and the pyramid level
			mx1(better)=tmpx(better);
			my1(better)=tmpy(better);
			ms1(better)=i1;
			

			
		%end if
		end
		
		%add this to the score
		mx{j}=mx1;
		my{j}=my1;
		ms{j}=ms1;
		scrf=scrf+bestscr;
	%end for
	end

	%find things that exceed a threshold and add boxes
	ind=find(scrf>thresh);
	if(isempty(ind)) continue; end;
	[indi, indj]=ind2sub(size(scrf), ind);
	boxes1=get_box_helper(imgxind(indj), imgyind(indi), currscale, model.sizes(1,:));
	boxes(cnt+1:cnt+numel(ind),1:4)=boxes1;
	boxes(cnt+1:cnt+numel(ind),numparts*4+1)=i;
	for j=2:numparts
		boxes2=get_box_helper(mx{j}(ind), my{j}(ind), scales(ms{j}(ind)), model.sizes(j,:));
		boxes(cnt+1:cnt+numel(ind),(j-1)*4+1:j*4)=boxes2;
		boxes(cnt+1:cnt+numel(ind), numparts*4+j)=ms{j}(ind);
	end
	boxes(cnt+1:cnt+numel(ind),end)=scrf(ind);
	cnt=cnt+numel(ind);
		

%end for
end
boxes=boxes(1:cnt,:);

function boxes=get_box_helper(x, y, scale, hogsize)
%hogsize is [ny nx]
h=hogsize(1)*scale;
w=hogsize(2)*scale;
boxes=[x(:) y(:) x(:)+w y(:)+h];
%boxes(:,3:4)=boxes(:,3:4)+boxes(:,1:2);



