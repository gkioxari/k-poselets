function [labels index]= find_labels_of_activations_bbox...
    (a, imglist, detections, kps_models, iou_thresh)
%% FIND_LABELS_OF_ACTIVATIONS() returns the labels and index in the 
%% ground truth of the poselet activations
%% INPUT
% a             : annotations
% imglist       : list of images
% detections    : struct of N activations of poselets
% kps_models    : bbox model for poselets
% iou_thresh    : threshold for IOU
%% OUTPUT
% labels        : Nx1 vector of true/false
% index         : Nx1 vector of indices to a

%%
a  = select_annotations(a,~a.img_flipped);
N  = size(detections.boxes,1); % # of activations
Nkpids = max(detections.kpids);% # of poselets

tt = a.bounds;
gt_bounds = tt;%[min(tt,[],1) max(tt,[],1)-min(tt,[],1)]; clear tt;
image_names = a.img_name;
valid = find(~isnan(gt_bounds(:,1)));
gt_bounds = gt_bounds(valid,:);
image_names = image_names(valid);
[dummy gt_imids] = ismember(image_names,{imglist.id});


labels = false(N,1);
index  = zeros(N,1);
pred_bounds = nan(N,4);

fprintf('Doing kid ');
for kid=1:Nkpids
	if(rem(kid,10)==0)
    	fprintf('[%d]',kid);
	end
    % activations of kid
    keep = detections.kpids==kid;   
    boxes = detections.boxes(keep,:);
    
    % get keypoint predictions
    coords = predict_keypoints(boxes,kps_models(kid));
    ttx = coords(:,1,:); ttx = permute(ttx,[1 3 2]); 
    tty = coords(:,2,:); tty = permute(tty,[1 3 2]);
    %ttx=ttx(target_kps,:);
	%tty=tty(target_kps,:);
	minx=min(ttx,[],1);
	maxx=max(ttx,[],1);
	miny=min(tty,[],1);
	maxy=max(tty,[],1);
    pred_bounds(keep,:) = [minx(:) miny(:) maxx(:)-minx(:) maxy(:)-miny(:)];
    
end

fprintf('\n Doing imid\n')
for imid = unique(detections.imids)'
    
    gt_keep = find(gt_imids==imid);
    keep = find(detections.imids==imid);
    
    gt_bb = gt_bounds(gt_keep,:);
    bb = pred_bounds(keep,:);
    
    iou = inters_union(bb,gt_bb);
    [miou mi] = max(iou,[],2);
    
    labels(keep(miou>=iou_thresh)) = true;
    index(keep(miou>=iou_thresh))  = valid(gt_keep(mi(miou>=iou_thresh)));
    
end


function iou = inters_union(bounds1,bounds2)

inters = rectint(bounds1,bounds2);
ar1 = bounds1(:,3).*bounds1(:,4);
ar2 = bounds2(:,3).*bounds2(:,4);
union = bsxfun(@plus,ar1,ar2')-inters;

iou = inters./(union+0.001);

