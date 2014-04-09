function pred_bounds=predict_all_bboxes(torsos, pred_bounds, imids, imglist, lrmodel, centroids, feats2)
origtorsos=torsos;
%expand torsos first
torsos(:,1:2)=torsos(:,1:2)-torsos(:,3:4);
torsos(:,3)=3*torsos(:,3);
torsos(:,4)=2*torsos(:,3);


boxes=torsos;
boxes(:,3:4)=boxes(:,3:4)+boxes(:,1:2);
model=init_model(boxes, [128 64],1);
uniqimids=unique(imids);

for k=1:numel(uniqimids)
	imid=uniqimids(k);
	ind=find(imids==imid);
	img=imread(imglist(imid).im);
	hogfeats=box2features_tree(boxes(ind,:), img, model);
	
	hogfeats(end+1,:)=pred_bounds(ind,4)./origtorsos(ind,4);
	[ypred, acc, dec]=predict(ones(numel(ind),1), (hogfeats), lrmodel,'-b 1', 'col');
	z=dec*centroids(lrmodel.Label);
	pred_bounds(ind,4)=origtorsos(ind,4).*z;
	if(rem(k-1,10)==0) fprintf('.'); end
end
fprintf('\n');


