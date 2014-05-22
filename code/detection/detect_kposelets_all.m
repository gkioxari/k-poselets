function detections = detect_kposelets_all(img, models, maxnumparts, use_sse)
%function detections = detect_kposelets_all(img, models, maxnumparts)
%detects kposelets in img
if(~exist('use_sse', 'var'))
	use_sse=true;
end

%get maximum template size	
maxmodel=models(1);
for k=1:numel(models)
	maxmodel.maxsize=max(maxmodel.maxsize, models(k).maxsize);
end


boxes=nan(10000, maxnumparts*4);
scales=nan(10000,2);
kpids=zeros(10000,1);
scores=zeros(10000,1);
cnt=0;

%create the feature pyramid
[pyr, img2f, f2img]=featpyramid_plus(img, maxmodel);

%for every model
for k=1:numel(models)
	model=models(k);
	if(rem(k-1,100)==0) disp(k); end

	%detect
	[boxes1 resp]=run_kposelet_tree_dt(pyr, img2f, f2img, model, model.thresh-1, use_sse);
	if(isempty(boxes1))
		continue;
	end

	%add the bias
	boxes1(:,end)=boxes1(:,end)-model.thresh;
	
	%nms
	[s1, i1]=sort(boxes1(:,end), 'descend');
	boxes1=boxes1(i1,:);
	boxes1=nms_kposelet(boxes1,model.numparts,0.5);

	%remove boxes that fall outside the image
	boxes1=prune_boxes_outside(boxes1, model.numparts, size(img));

	
	%store
	boxes(cnt+1:cnt+size(boxes1,1),1:model.numparts*4)=boxes1(:,1:model.numparts*4);
	scales(cnt+1:cnt+size(boxes1,1),1:model.numparts)=boxes1(:,model.numparts*4+(1:model.numparts));

	kpids(cnt+1:cnt+size(boxes1,1),1)=model.kpid;
	scores(cnt+1:cnt+size(boxes1,1),end)=boxes1(:,end);
	cnt=cnt+size(boxes1,1);
end
boxes=boxes(1:cnt,:);
scales=scales(1:cnt,:);
scores=scores(1:cnt);
kpids=kpids(1:cnt);


detections.boxes=boxes;
detections.scales=scales;
detections.scores=scores;
detections.kpids=kpids;
%set the dummy image id
detections.imids=zeros(size(kpids));


function boxes=prune_boxes_outside(boxes, numparts, imsize)
idx=true(size(boxes,1),1);
for i=1:numparts
	bx=boxes(:, (i-1)*4+1:i*4);
	mx=min(bx(:,3:4), ones(size(bx,1),1)*imsize([2 1]));
	mn=max(bx(:,1:2), ones(size(bx,1),2));
	idx=idx & all(mx>mn, 2);
end
boxes=boxes(idx,:);



