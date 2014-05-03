function scores=test_stage2_rescorer(clusters, detections, precrec_mapping, imglist, selected, kps, svmmodel)
%get the mapped scores
newscores = map_scores_using_precrec(detections.scores, detections.kpids, precrec_mapping);

%get the feature vectors
feats=fv_for_rescoring(clusters, detections, newscores, imglist, selected);

scores=svmmodel.w(1:end-1)*feats+svmmodel.w(end);
if(svmmodel.Label(1)~=1)
	scores=-scores;
end
