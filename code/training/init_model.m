function model=init_model(boxes, poselet_dims, K)

%initialize model
model.sbin=8;
model.interval=10;
model.hogsize=32;
model.thresh=0;
model.numparts=K;
model.w=cell(model.numparts,1);
model.sizes=poselet_dims./model.sbin;
model.maxsize=max(model.sizes,[],1);


%get the anchors
scales=mean(bsxfun(@rdivide,(boxes(:,3:4)-boxes(:,1:2)), model.sizes(1,[2 1])),2);

for i=2:model.numparts
	bx=boxes(:, (i-1)*4+1:i*4);
	def=bsxfun(@rdivide, bx(:,1:2)-boxes(:,1:2), scales);
	model.anchor{i}=mean(def,1);
	scale2=mean(bsxfun(@rdivide,(bx(:,3:4)-bx(:,1:2)), model.sizes(i,[2 1])),2);
	leveldiff=model.interval*log2(scale2./scales);
	leveldiff=round(mean(leveldiff));
	model.scaleanchor{i}=leveldiff;
end

%possible deformations
[x,y]=meshgrid([-4:4], [-4:4]);
x=x(:)';
y=y(:)';
model.deformations=[x;y];
model.boxes = boxes;
