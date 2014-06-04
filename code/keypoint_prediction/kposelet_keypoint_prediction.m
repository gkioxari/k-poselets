function kp_pred = kposelet_keypoint_prediction(imglist,detections,clusters,kps_prec_rec,kps_models)
%% KPOSELET_KEYPOINT_PREDICTION() predicts keypoints for each cluster
%% INPUT
% imglist       : list of images
% detections    : detections of kposelets
% clusters      : clusters of detections 
% kps_prec_rec  : precision-recall mapping based on keypoint prediction
% kps_models    : keypoint models
%% OUTPUT
% pred      : prediction of keypoint with apk metric

%%

Kp = size(kps_models(1).kps_mean,1);

imids = unique(detections.imids);
image_names = {imglist.id};
image_names = image_names(imids);
clear imids;

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
        kp_pred.img_name{num_cl} = img_name;
        kp_pred.coords(:,:,num_cl) = coords;
        kp_pred.scores(:,num_cl) = kp_scores;
        
    end
    
        
end

