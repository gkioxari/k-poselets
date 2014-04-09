function [svmmodel, feats, labels, fmax] = train_stage2_rescorer_torso(trimids, clusters, detections, precrec_mapping, a, imglist, selected, kps, clusters_neg, detections_neg, imglist_neg)
%restrict attention to clusters in training list
clusters=clusters(ismember([clusters.imid], trimids));

%get the mapped scores
newscores = map_scores_using_precrec(detections.scores, detections.kpids, precrec_mapping);

%get the leader
leaders=get_cluster_leader(clusters, newscores);

%use the leader to predict torsos
torsos=get_torso_predictions(detections.boxes(leaders,:), detections.kpids(leaders), kps);
baseline_scores=newscores(leaders);

%use this to evaluate
output=compute_ap_boxesin(a, imglist,[clusters.imid], torsos, baseline_scores, 1, 0.5, trimids);
%get the feature vectors
feats=fv_for_rescoring(clusters, detections, newscores, imglist, selected);
if(exist('clusters_neg', 'var'))
	newscores_neg = map_scores_using_precrec(detections_neg.scores, detections_neg.kpids, prec_rec);

	featsneg=fv_for_rescoring(clusters_neg, detections_neg, newscores_neg, imglist_neg, selected);
else
	featsneg=[];
end

feats=[feats(:,~output.duplicate) featsneg];
labels=[double(output.labels(~output.duplicate)); zeros(size(featsneg,2),1)];
labels=2*labels-1;

fmax=max(abs(feats),[],2);
fmax=fmax+double(fmax==0);
feats=bsxfun(@rdivide, feats, fmax); 



svmmodel=liblinear_train(labels, feats, '-s 3 -c 0.05 -w1 3 -B 1', 'col');
svmmodel.w(1:end-1)=svmmodel.w(1:end-1)./fmax';







