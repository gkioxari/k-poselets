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

%%
% Get torso bounds for detections
N = size(detections.boxes,1);
pred_bounds = nan(N,4);
pred_scores = nan(N,1);
fprintf('Doing kid ');
for kid = unique(detections.kpids')
    fprintf('[%d]',kid);
    % activations of kid
    keep = detections.kpids==kid;   
    boxes = detections.boxes(keep,:);
    
    % get keypoint predictions
    coords = predict_keypoints(boxes,kps_models(kid));
    ttx = coords(:,1,:); ttx = permute(ttx,[1 3 2]); 
    tty = coords(:,2,:); tty = permute(tty,[1 3 2]);
    ttx=ttx(target_kps,:);
	tty=tty(target_kps,:);
	minx=min(ttx,[],1);
	maxx=max(ttx,[],1);
	miny=min(tty,[],1);
	maxy=max(tty,[],1);
    pred_bounds(keep,:) = [minx(:) miny(:) maxx(:)-minx(:) maxy(:)-miny(:)];

    scr = detections.scores(keep);
    if length(pr(kid).scores)>10000
        step = floor(length(pr(kid).scores)/10000);
        pr(kid).scores = pr(kid).scores(1:step:length(pr(kid).scores));
        pr(kid).prec   = pr(kid).prec(1:step:length(pr(kid).prec));
    end
    for j=1:length(scr)
        ind = find(scr(j)>=pr(kid).scores);
        if isempty(ind)
            scr(j) = pr(kid).prec(end);
        else 
            ind = [ind(1) ind(1)-1 ind(1)+1];
            ind = ind(ind>=1 & ind<=length(pr(kid).scores));
            [m mi] = min(abs(pr(kid).scores(ind)-scr(j)));
            scr(j) = pr(kid).prec(ind(mi));
        end
    end
    pred_scores(keep) = scr;
    clear keep m mi scr minx miny maxx maxy ttx tty coords boxes;
end

ci=0;
imids = unique(detections.imids)';

for imid=imids
    
    keep = find(detections.imids==imid);
    N = length(keep);
    if N==0, continue; end

    fprintf('Imid %d\n',imid);
    %torso bounds
	torso_bounds = pred_bounds(keep,:);
    scores = pred_scores(keep);
    
    %I-over-U
    iou = inters_union(torso_bounds,torso_bounds);
    
	%agglomerative clustering
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
