function pck_pred = kposelet_pck_prediction(a,imglist,detections,clusters,prec_rec,kps_prec_rec,kps_models)
%% KPOSELET_PCK_PREDICTION() predicts keypoints based on the pck metric. For each gt instance
%% we assign the highest scoring activation with torso iou>0.5. 
%% INPUT
% a             : annotations
% imglist       : list of images
% detections    : detections of kposelets
% clusters      : clusters of detections 
% prec_rec      : precision-recall mapping based on torso prediction
% kps_prec_rec  : precision-recall mapping based on keypoint prediction
% kps_models    : keypoint models
%% OUTPUT
% pck_pred      : prediction of keypoint with pck metric

%%

a = select_annotations(a,~a.img_flipped);
iou_thresh = 0.5;
torso_ks = {'R_Shoulder','L_Shoulder','R_Hip','L_Hip'};
[dummy torso_ks] = ismember(torso_ks,a.kps_labels);
Kp = length(a.kps_labels);


for i=1:size(a.coords,3)
    
    fprintf('[%d/%d] \n',i,size(a.coords,3));
    
    % Ground truth torso
    gt_torso = a.coords(torso_ks,1:2,i);
    gt_torso = [min(gt_torso,[],1) max(gt_torso,[],1)-min(gt_torso,[],1)];
    
    pck_pred.img_name{i} = a.img_name{i};
    pck_pred.bounds(i,:) = a.bounds(i,:);
    
    if any(isnan(gt_torso(:)))
        pck_pred.coords(:,:,i) = nan(Kp,2);
        continue;
    end
    
    % predicted torsos and scores for each cluster
    imid = find(strcmp(a.img_name{i},{imglist.id}));    
    clis = find([clusters.imid]==imid);
    
    torso_bounds=nan(length(clis),4);
    torso_scores=nan(length(clis),1);
    for ci = 1:length(clis)
        
        % scores for clusters
        keep = clusters(clis(ci)).members;
        bb = detections.boxes(keep,:);
        sc = detections.scores(keep);
        kpids = detections.kpids(keep,:);
        
        scores = nan(size(bb,1),1);
        for bi=1:size(bb,1)
            [m mi] = min(abs(prec_rec(kpids(bi)).scores-sc(bi)));
            scores(bi) = prec_rec(kpids(bi)).prec(mi); clear m mi;
        end
        
        [s si] = sort(scores,'descend');
        si = si(1);
        bb = bb(si,:);
        scores = scores(si);
        kpids = kpids(si);
        clear s si;
        
        % torso prediction for clusters
        coords = predict_keypoints(bb,kps_models(kpids)); 
        temp_bounds = coords(torso_ks,1:2);
        
        torso_bounds(ci,:) = [min(temp_bounds,[],1) max(temp_bounds,[],1)-min(temp_bounds,[],1)];
        torso_scores(ci,:) = scores;
        clear temp_bounds;
    end
    
    % assign cluster to gt instance
    iou = inters_union(torso_bounds,gt_torso);
    clis = clis(iou>=iou_thresh);
    if isempty(clis)
        pck_pred.coords(:,:,i) = nan(Kp,2);
        continue; 
    end    
    torso_bounds = torso_bounds(iou>=iou_thresh,:);
    torso_scores = torso_scores(iou>=iou_thresh);
    
    % Pick winner cluster and predict keypoints 
    [m mi] = max(torso_scores);
    clis = clis(mi);
    
    bb = detections.boxes(clusters(clis).members,:);
    kpids = detections.kpids(clusters(clis).members);
    scores = detections.scores(clusters(clis).members);
     
    kp_scores = nan(size(bb,1),Kp);
    all_coords = nan(Kp,2,size(bb,1));
    
    for bi = 1:size(bb,1)
        for ki = 1:Kp
            [m mi] = min(abs(kps_prec_rec(kpids(bi),ki).scores-scores(bi)));
            kp_scores(bi,ki) = kps_prec_rec(kpids(bi),ki).prec(mi);
        end
        all_coords(:,:,bi) = predict_keypoints(bb(bi,:),kps_models(kpids(bi)));
    end
   
     [m mi] = max(kp_scores,[],1);
     coords = nan(Kp,2);
     for ki=1:Kp
        coords(ki,:) = all_coords(ki,:,mi(ki));
     end
     pck_pred.coords(:,:,i) = coords;
     clear coords;
    
        
end



function iou = inters_union(bounds1,bounds2)

inters = rectint(bounds1,bounds2);
ar1 = bounds1(:,3).*bounds1(:,4);
ar2 = bounds2(:,3).*bounds2(:,4);
union = bsxfun(@plus,ar1,ar2')-inters;

iou = inters./(union+0.001);

