function pred_bounds=predict_all_bboxes_perimg(torsos, pred_bounds, imid, imglist, lrmodel, centroids)
if(isempty(torsos)) return; end
origtorsos=torsos;
%expand torsos first
torsos(:,1:2)=torsos(:,1:2)-torsos(:,3:4);
torsos(:,3)=3*torsos(:,3);
torsos(:,4)=2*torsos(:,3);


boxes=torsos;
boxes(:,3:4)=boxes(:,3:4)+boxes(:,1:2);
model=init_model(boxes, [128 64],1);

img=imread(imglist(imid).im);
hogfeats=box2features_tree(boxes, img, model);

hogfeats(end+1,:)=pred_bounds(:,4)./origtorsos(:,4);
[ypred, acc, dec]=predict(ones(size(boxes,1),1), (hogfeats), lrmodel,'-b 1', 'col');
z=dec*centroids(lrmodel.Label);
pred_bounds(:,4)=origtorsos(:,4).*z;
fprintf('\n');


