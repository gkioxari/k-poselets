function [hogfeats, deffeats]=box2features_pyr_tree(boxes, pyr,img2f, model)
hogfeats=[];
deffeats=[];
scaledeffeats=[];
numparts=model.numparts;
ubconstrdef=[];
ubconstrscaledef=[];
for i=1:numparts
	%assign memory
	hogfeats1=zeros(sum(prod(model.sizes(i,:),2)*32),size(boxes,1));

	%get the box
	bx=boxes(:,(i-1)*4+1:i*4);

	%look up hog feats from the pyramid
	pyrindex=boxes(:,numparts*4+i);
	for k=1:numel(pyrindex)
		flocx=round(img2f(pyrindex(k),1)+img2f(pyrindex(k),3)*bx(k,1));
		flocy=round(img2f(pyrindex(k),2)+img2f(pyrindex(k),4)*bx(k,2));
		f=pyr.feat{pyrindex(k)}(flocy:flocy+model.sizes(i,1)-1, flocx:flocx+model.sizes(i,2)-1,:);
		hogfeats1(:,k)=f(:);
	end
	hogfeats=[hogfeats; hogfeats1];
	
	%get the scale, i.e size of the box divided by size of the classifier in terms of hog cells. scale is thus the "size" of a hog cell
	scale(:,i)=mean(bsxfun(@rdivide, (bx(:,3:4)-bx(:,1:2)),model.sizes(i,[2 1])),2 );
	
end
for i=2:numparts

	%deformation features
	bx=boxes(:,(i-1)*4+1:i*4);
	relscale=scale(:,i)./scale(:,1);
	
	%get deformation, in terms of number of hog cells away from the anchor
	def=bsxfun(@minus, bsxfun(@rdivide, (bx(:,1:2)-boxes(:,1:2)), scale(:,1)), model.anchor{i});

	%get deformation features
	deffeat=[def def.^2]';	
	deffeats=[deffeats; deffeat];

end
	


