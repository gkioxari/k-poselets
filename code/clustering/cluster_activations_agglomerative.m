function clusters = cluster_activations_agglomerative...
            (detections, kps_models, pr, target_kps, thresh)
%% CLUSTER_ACTIVATIONS_AGGLOMERATIVE() returns clusters of activations 
%% by clustering them based on target kps overlap
%% INPUT
% detections    : detections of poselets
% kps_models    : keypoint models
% pr            : prec-rec mappings for poselets
% target_kps    : set of target keypoints
% thresh        : overlap threshold for clustering
%% OUTPUT
% clusters      : Cx1 structure of clusters, where
%                members is a Nx1 vector of indices in detections
%                imid is a scalar, unique for a given image 

ci=0;
imids = unique(detections.imids)';

for imid=image_ids
    
    keep = find(detections.imid==imid);
    N = length(keep);
    if N==0, continue; end

    fprintf('Imid %d\n',imid);
    fprintf('...Getting torso bounds\n');
    torso_bounds = nan(N,4);
    scores = nan(N,1);
    for i=1:N
        kid = detections.kpids(keep(i));
        box = detections.boxes(keep(i),:);
        scr = detections.scores(keep(i));
        coords = predict_keypoints(box,kps_models(kid));
        cc = coords(target_kps,:);
        torso_bounds(i,:) = [min(cc,[],1) max(cc,[],1)-min(cc,[],1)];
        clear cc coords box;
        
        [m mi] = min(abs(pr(kid).scores-scr));
        scores(i) = pr(kid).prec(mi);
    end
    
    fprintf('...Computing IOU\n');
    iou = inters_union(torso_bounds,torso_bounds);
    
    fprintf('...Agglomerative Clustering\n');
    Z=leaderlinkage(1-iou, scores);
    if ~isempty(Z)
    	T = cluster(Z,'cutoff',1-thresh,'criterion','distance');
    else
        T = 1;
    end
    num_clust = max(T);
    for i=1:num_clust
        ci = ci+1;
        clusters(ci).members = keep(T==i);
        clusters(ci).imid = imid;
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
