function [hogfeats, deffeats]=box2features_tree(boxes, img, model)
hogfeats=[];
deffeats=[];
numparts=model.numparts;


for i=1:numparts
	%assign memory
	hogfeats1=zeros(sum(prod(model.sizes(i,:),2)*32),size(boxes,1));

	%get the box
	bx=boxes(:,(i-1)*4+1:i*4);
	siz=model.sizes(i,:);
	sbin=model.sbin;

	%get warped image patch
	warped=warppatch(img, bx, sbin, siz);
	
	%get hog features
	for k=1:numel(warped)
		f=features(double(warped{k}),sbin);
		assert(all(size(f)==[siz 32]));
		hogfeats1(:,k)=f(:);
	end
	hogfeats=[hogfeats; hogfeats1];

	%get the scale, i.e size of the box divided by size of the classifier in terms of hog cells. scale is thus the "size" of a hog cell
	scale(:,i)=mean(bsxfun(@rdivide, (bx(:,3:4)-bx(:,1:2)), model.sizes(i,[2 1])),2 );
	
end

for i=2:numparts

	%deformation features
	bx=boxes(:,(i-1)*4+1:i*4);
	relscale=scale(:,i)./scale(:,1);

	%get deformation, in terms of number of hog cells away from the anchor
	def=bsxfun(@minus, bsxfun(@rdivide, (bx(:,1:2)-boxes(:,1:2)), scale(:,1)),model.anchor{i});

    deffeat=[def def.^2]';
	deffeats=[deffeats; deffeat];
end
	


