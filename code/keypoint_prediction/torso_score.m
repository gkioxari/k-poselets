function clusters = torso_score(detections,clusters,kps_models,prec_rec,target_kps)
%% TORSO_SCORE() assigns each cluster a torso bound and a  score, 
%% based on the torso precision-recall mapping
%% Input
% detections : kposelet activations
% clusters   : clusters of activations
% prec_rec   : prec-rec mapping based on torso prediction
%% OUTPUT
% clusters   : clusters of activations with a field of a score
%%

for i=1:length(clusters)
    
    keep = clusters(i).members;
    bb = detections.boxes(keep,:);
    sc = detections.scores(keep);
    kpids = detections.kpids(keep,:);
    num_det = size(bb,1);
    
    new_sc = -Inf(num_det,1);
    for j=1:num_det
        [m mi] = min(abs(prec_rec(kpids(j)).scores-sc(j)));
        new_sc(j) = prec_rec(kpids(j)).prec(mi);
        clear m mi;
    end
    
    [max_sc maxi] = max(new_sc);
    coords = predict_keypoints(bb(maxi,:),kps_models(kpids(maxi)));
    coords = coords(target_kps,:);
    torso_bounds = [min(coords,[],1) max(coords,[],1)-min(coords,[],1)];
    clusters(i).torso_score = max_sc;
    clusters(i).torso_bounds = torso_bounds;
    
end

end