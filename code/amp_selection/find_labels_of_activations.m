function [labels index]= find_labels_of_activations(a,imglist,boxes,kps)
%% FIND_LABELS_OF_ACTIVATIONS() returns the labels and index in the 
%% ground truth of the poselet activations
%% INPUT
% a         : annotations
% imglist   : list of images
% boxes     : activations of poselets
% kps       : keypoint model for poselets

a = struct_select(a,~a.img_flipped);
Kp = size(kps.kps_mean,1);
iou_thresh = 0.5;

torso_ks = [1 4 7 10];

tt = a.coords(torso_ks,1:2,:);
gt_bounds = [min(tt,[],1) max(tt,[],1)-min(tt,[],1)]; clear tt;
gt_bounds = permute(gt_bounds,[3 2 1]);
image_ids = a.image_id(:);
valid = find(~isnan(gt_bounds(:,1)));
gt_bounds = gt_bounds(valid,:);
image_ids = image_ids(valid);

labels=false(size(boxes,1),1);
index=zeros(size(boxes,1),1);

for i=1:size(boxes,1)
    
    if mod(i,10000)==1
        fprintf('In %d / %d \n',i,size(boxes,1))
    end
    
    imid = boxes(i,end);
    image_id = imglist(imid).image_id;
    kid = boxes(i,end-1);
    keep = find(image_ids==image_id);
    if isempty(keep), error('Hmm?'); end
    
    K = kps.num_parts(kid);
    bb=boxes(i,1:4*K);
    bb = reshape(bb,[4 K])';
    ctr = (bb(:,1:2)+bb(:,3:4))/2;
    width = bb(:,3)-bb(:,1);
    tt = zeros(Kp,2);
    for k=1:K
        temp_coords = kps.kps_mean(:,:,k,kid)*width(k);
        temp_coords = bsxfun(@plus,temp_coords,ctr(k,:));
        tt=tt+bsxfun(@times,temp_coords,kps.kps_weights(:,k,kid));
    end
    tt = tt(torso_ks,:);
    bound = [min(tt,[],1) max(tt,[],1)-min(tt,[],1)];
    iou = inters_union(gt_bounds(keep,:),bound);
    
    if any(iou>=iou_thresh)
        [m mi] = max(iou);
        labels(i)=true;
        index(i)=valid(keep(mi));
    end
    
end

end

function iou = inters_union(bounds1,bounds2)

inters = rectint(bounds1,bounds2);
ar1 = bounds1(:,3).*bounds1(:,4);
ar2 = bounds2(:,3).*bounds2(:,4);
union = bsxfun(@plus,ar1,ar2')-inters;

iou = inters./(union+0.001);

end