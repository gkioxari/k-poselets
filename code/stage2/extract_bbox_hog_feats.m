function feats=extract_bbox_hog_feats(torsos, pred_bounds, imids, imglist)
%expand torsos first
origtorsos=torsos;
torsos(:,1:2)=torsos(:,1:2)-torsos(:,3:4);
torsos(:,3)=3*torsos(:,3);
torsos(:,4)=2*torsos(:,3);


boxes=torsos;
boxes(:,3:4)=boxes(:,3:4)+boxes(:,1:2);
model=init_model(boxes, [64*2 64], 1);
feats=zeros(prod(model.sizes)*32, size(boxes,1));
uniqimids=unique(imids);
for k=1:numel(uniqimids)
	imid=uniqimids(k);
	ind=find(imids==imid);
	img=imread(imglist(imid).im);
	hogfeats=box2features_tree(boxes(ind,:), img, model);
	feats(:,ind)=hogfeats;
	if(rem(k-1,10)==0) fprintf('.'); end
end
feats(end+1,:)=pred_bounds(:,4)./origtorsos(:,4);
fprintf('\n');


