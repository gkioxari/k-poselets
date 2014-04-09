function [index, ovall, gt_bounds]=compute_ap_boxesin(a, imglist, cluster_imids, cluster_pred_boxes, image_ids_present)
%keyboard


%first get ground truth
	torso_ks = [1 4 7 10];
	tt = a.coords(torso_ks,1:2,:);
	gt_torso_bounds = [min(tt,[],1) max(tt,[],1)-min(tt,[],1)]; clear tt;
	gt_torso_bounds = permute(gt_torso_bounds,[3 2 1]);
	tt=a.bounds;
	gt_bounds = tt;clear tt;

[gt_valid, gt_imids]=ismember(a.img_name, {imglist.id});

%the valid ground truth
gt_valid=gt_valid & ~a.img_flipped & ~isnan(gt_bounds(:,1));

%the valid detections
det_valid=true(numel(cluster_imids),1);


if(exist('image_ids_present', 'var'))
	%only evaluate on subset
	gt_valid=gt_valid & ismember(gt_imids, image_ids_present);
	det_valid=det_valid & ismember(cluster_imids(:), image_ids_present);
end
gt_valid=find(gt_valid);
det_valid=find(det_valid);

gt_torso_bounds = gt_torso_bounds(gt_valid,:);
gt_bounds = gt_bounds(gt_valid,:);
gt_imids = gt_imids(gt_valid); 

cluster_imids=cluster_imids(det_valid);
cluster_pred_boxes=cluster_pred_boxes(det_valid,:);

covered = false(size(gt_bounds,1),1);



index=zeros(length(cluster_imids),1);
ovall=zeros(length(cluster_imids),1);

all_imids=unique([cluster_imids(:); gt_imids(:)]);
cl_keep_all=cell(max(all_imids),1);
for k=1:numel(cl_keep_all)
	cl_keep_all{k}=zeros(1,1000);
	cnt(k)=0;
end
for i=1:numel(cluster_imids)
	cl_keep_all{cluster_imids(i)}(cnt(cluster_imids(i))+1)=i;
	cnt(cluster_imids(i))=cnt(cluster_imids(i))+1;
	if(rem(i-1,10000)==0) fprintf('.'); end
end
fprintf('\n');
sum(cnt)
for k=1:numel(cl_keep_all)
	cl_keep_all{k}=cl_keep_all{k}(1:cnt(k));
end



for imid=all_imids(:)'
    
    if(rem(imid, 100)==0) fprintf('In %d / %d\n',imid,length(all_imids)); end
    
    cl_keep = cl_keep_all{imid};%find([clusters.imid]==imid);
    pred_torsos = cluster_pred_boxes(cl_keep,:);   
    gt_keep = find(gt_imids==imid); 
	if(isempty(gt_keep))
		continue;
	end

    
    iou = inters_union(pred_torsos,gt_torso_bounds(gt_keep,:));
    [m,i]=max(iou, [],2);
	index(cl_keep)=gt_keep(i);
	ovall(cl_keep)=m;
    
end
end

function iou = inters_union(bounds1,bounds2)

inters = rectint(bounds1,bounds2);
ar1 = bounds1(:,3).*bounds1(:,4);
ar2 = bounds2(:,3).*bounds2(:,4);
union = bsxfun(@plus,ar1,ar2')-inters;

iou = inters./(union+0.001);

end
