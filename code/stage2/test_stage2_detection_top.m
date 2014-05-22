function [scores, bounds, idx]=test_stage2_detection_top(clusters, detections, kps, ...
							precrec_mapping, precrec_mapping_bbox, imglist, bbox_pred, ...
							selected, stage2model)
%function [scores, bounds, idx]=test_stage2_detection_top(clusters, detections, kps, ...
%							precrec_mapping, precrec_mapping_bbox, imglist, bbox_pred, ...
%							selected, stage2model)
%input arguments:
%clusters					: clusters of detections
%detections					: detections
%kps						: kp models for k-poselets
%precrec_mapping			: precision recall mapping from torsos
%precrec_mapping_bbox		: precision recall mapping from bbox
%imglist 					: list of images
%bbox_pred					: bbox models for k-poselets
%selected					: set of selected kpids
%stage2model				: stage 2 model
%
%outputs:
%scores						: score for each cluster
%bounds						: bbox prediction for each cluster [xmin ymin w h]
%idx						: remaining clusters after pruning boxes outside and after nms


bboxmodel=stage2model.bboxmodel;
bboxcentroids=stage2model.bboxcentroids;
rescoremodel=stage2model.rescoremodel;

%get the mapped scores

fprintf('Computing mapped scores..\n');
newscores = map_scores_using_precrec(detections.scores, detections.kpids, precrec_mapping);
bbox_newscores = map_scores_using_precrec(detections.scores, detections.kpids, precrec_mapping_bbox);



fprintf('Getting torso predictions..\n');
torsos=get_weighted_torso_predictions(clusters, newscores, detections.boxes, detections.kpids, kps);

%get the baseline bounds predictions
fprintf('Getting baseline bounds predictions..\n');
pred_bounds=get_baseline_bounds_predictions(clusters, bbox_newscores, detections.boxes, detections.kpids,  bbox_pred);
pred_bounds=clipboxes(pred_bounds, [clusters.imid], imglist);


%predicting bounds
fprintf('Predicting bounds. Note that this can be parallelized over images...\n');
pred_bounds2=pred_bounds;
imids=[clusters.imid];
for k=1:numel(imglist)
	pred_bounds2(imids==k,:)=predict_all_bboxes_perimg(torsos(imids==k,:), pred_bounds(imids==k,:), k, imglist, bboxmodel, bboxcentroids);
end
pred_bounds2=clipboxes(pred_bounds2, [clusters.imid], imglist);
bounds=pred_bounds2;

%rescoring
fprintf('Computing features for rescoring..\n');
feats=fv_for_rescoring(clusters, detections, newscores, imglist, selected);

fprintf('Rescoring..\n');
scores=rescoremodel.w(1:end-1)*feats+rescoremodel.w(end);
if(rescoremodel.Label(1)~=1)
	%invert score
	scores=-scores;
end

fprintf('Removing empty boxes and doing nms..\n');
idx=find(all(pred_bounds2(:,3:4)>0,2));
idx2=do_final_nms(pred_bounds2(idx,:), scores(idx), imids(idx));
idx=idx(idx2);


















