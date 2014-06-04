function apk_pred = kposelet_apk_prediction(a,imglist,detections,clusters,kps_prec_rec,kps_models)
%% KPOSELET_APK_PREDICTION() predicts keypoints based on the apk metric. For each gt instance
%% we assign the highest scoring activation with torso iou>0.5. 
%% INPUT
% a             : annotations
% imglist       : list of images
% detections    : detections of kposelets
% clusters      : clusters of detections 
% kps_prec_rec  : precision-recall mapping based on keypoint prediction
% kps_models    : keypoint models
%% OUTPUT
% apk_pred      : prediction of keypoint with apk metric

%%

a = select_annotations(a,~a.img_flipped);
Kp = length(a.kps_labels);

% note: for pose estimation we evaluate only on the images that contain 
% annotations.
image_names = unique(a.img_name); 

num_cl=0;

for i=1:length(image_names)
    
    img_name = image_names{i};
    imid = find(strcmp(img_name,{imglist.id}));
    fprintf('[%d/%d] %s \n',i,length(image_names),img_name);
       
    % predicted keypoints for each cluster
    clis = find([clusters.imid]==imid);
        
    for ci = 1:length(clis)
        
        % detections of clusters
        keep = clusters(clis(ci)).members;
        bb = detections.boxes(keep,:);
        sc = detections.scores(keep);
        kpids = detections.kpids(keep,:);
        
        % keypoint scores and predictions for each detection
        all_coords = nan(Kp,2,size(bb,1));
        kp_scores = nan(size(bb,1),Kp);
        for bi = 1:size(bb,1)
            % for each keypoint, map the detection score to the keypoint
            % score
            for ki = 1:Kp
                [m mi] = min(abs(kps_prec_rec(kpids(bi),ki).scores-sc(bi)));
                kp_scores(bi,ki) = kps_prec_rec(kpids(bi),ki).prec(mi);
            end
            % each detection predicts a set of keypoints
            all_coords(:,:,bi) = predict_keypoints(bb(bi,:),kps_models(kpids(bi)));
        end
        
        % best scoring keypoint prevails
        [kp_scores mi] = max(kp_scores,[],1);
        coords = nan(Kp,2);
        for ki=1:Kp
           coords(ki,:) = all_coords(ki,:,mi(ki));
        end
        
        num_cl = num_cl+1;
        apk_pred.img_name{num_cl} = img_name;
        apk_pred.coords(:,:,num_cl) = coords;
        apk_pred.scores(:,num_cl) = kp_scores;
        
    end
    
        
end

