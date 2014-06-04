function prec_rec = kps_prec_rec(a,imglist,detections,kps_models,alpha)
%% KPS_PREC_REC() computes the precision recall mapping from the activations
%% based on the pck metric (alpha * torso_height)
%% INPUT
% a         : annotations
% imglist   : list of images
% detections: detections of kposelets
% kps_models: keypoint models
% alpha     : tolerance of pck metric
%% OUTPUT
% prec_rec  : prec-rec mapping for each keypoint

%%
a = select_annotations(a,~a.img_flipped);
[dummy a_imids] = ismember(a.img_name,{imglist.id});
torso_ks = {'R_Shoulder','L_Shoulder','R_Hip','L_Hip'};
[dummy torso_ks] = ismember(torso_ks,a.kps_labels);

% tolerance for each gt
gt_torso = a.coords(torso_ks,1:2,:);
gt_torso = [min(gt_torso,[],1) max(gt_torso,[],1)-min(gt_torso,[],1)];
gt_torso = permute(gt_torso,[3 2 1]);
gt_thresh = gt_torso(:,4)*alpha;
clear gt_torso;

kpids = unique(detections.kpids);
Kp = size(a.coords,1);

fprintf('Doing ');
for j = 1:length(kpids)
    kid = kpids(j);
    fprintf('[%d] ',kid);
    
    keep  = find(detections.kpids==kid);
    boxes = detections.boxes(keep,:);
    coords = predict_keypoints(boxes,kps_models(kid));
    
    scores = cell(Kp,1);
    labels = cell(Kp,1);
    
    for i=1:size(coords,3)
        imid = detections.imids(keep(i));
        gt_keep = a_imids==imid;
        gt_coords = a.coords(:,1:2,gt_keep);
        thresh = gt_thresh(gt_keep);
        for ki=1:Kp
            dist = bsxfun(@minus,permute(gt_coords(ki,:,:),[3 2 1]),coords(ki,1:2,i));
            dist = sqrt(sum(dist.^2,2));
            dist = dist./thresh;
            scores{ki} = [scores{ki};detections.scores(keep(i))];
            if any(dist<=1)
                labels{ki} = [labels{ki};true];
            else
                labels{ki} = [labels{ki};false];
            end
        end
    end
    
    for ki=1:Kp
        
        [ap,rec,prec,scrs] = get_precision_recall(scores{ki},labels{ki},'max',[]);
        prec_rec(kid,ki).ap = ap;
        prec_rec(kid,ki).rec = rec;
        prec_rec(kid,ki).prec = prec;
        prec_rec(kid,ki).scores = scrs;
        prec_rec(kid,ki).kid = kid;
        prec_rec(kid,ki).kp = ki;
        
    end

end
fprintf('\n');



