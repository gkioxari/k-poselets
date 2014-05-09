function stage2model=train_stage2_detection_top_withbbox(trimids, clusters, detections,...
							 kps, precrec_mapping,precrec_mapping_bbox, imglist,a, bbox_pred, selected)
%function stage2model=train_stage2_detection_top_withbbox(trimids, clusters, detections,...
%							 kps, precrec_mapping,precrec_mapping_bbox, imglist,a, bbox_pred, selected)
%trains the second stage. Input arguments:
%trimids				: indices of training images. These are indices into imglist
%clusters				: clusters of detections
%kps					: keypoint models
%precrec_mapping		: precision recall mapping computed from torsos
%precrec_mapping_bbox	: precision recall mapping computed from bounding box
%imglist				: list of images.
%a						: annot structure
%bbox_pred				: bounding box models (see bbox_klet.m)
%selected				: list of selected k-poselet ids
rng('default');
rng(3);
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


fprintf('Getting baseline scores..\n');
%get the leader according to torso
leaders=get_cluster_leader(clusters, bbox_newscores);
baseline_scores=bbox_newscores(leaders);





fprintf('Training bbox predictor : getting training data..\n');
%get regression data
[index, ovall, gt_bounds]=get_regression_trainingdata(a, imglist, [clusters.imid],torsos);
pick=find(ovall>=0.3);
numel(pick)

[labels, centroids]= get_bbox_reg_labels(gt_bounds(index(pick),:), torsos(pick,:),2);

fprintf('Training bbox predictor : extracting features..\n');
feats=extract_bbox_hog_feats(torsos(pick,:), pred_bounds(pick,:), [clusters(pick).imid], imglist);

fprintf('Training..\n');
model=liblinear_train(labels, feats, '-s 0 -c 0.1 -B 1', 'col');
[ypred, acc, dec]=predict(labels, feats, model,'-b 1', 'col');
acc

%svmmodel=[];
%fmax=[];
%return;

fprintf('Getting bbox predictions on training data..\n');
pred_bounds=predict_all_bboxes(torsos, pred_bounds, [clusters.imid], imglist, model, centroids);
pred_bounds=clipboxes(pred_bounds, [clusters.imid], imglist);

fprintf('Training rescorer : getting training data..\n');
%remove empty boxes
idx=all(pred_bounds(:,3:4)>0,2);
pred_bounds=pred_bounds(idx,:);
clusters=clusters(idx);
baseline_scores=baseline_scores(idx);

%use this to evaluate
output=compute_ap_boxesin(a, imglist,[clusters.imid], pred_bounds, baseline_scores, 0, 0.5, trimids);

fprintf('Getting feature vectors..\n');
feats=fv_for_rescoring(clusters, detections, newscores, imglist, selected);
feats=feats(:,~output.duplicate);
labels=[double(output.labels(~output.duplicate))];
labels=2*labels-1;

fmax=max(abs(feats),[],2);
fmax=fmax+double(fmax==0);
feats=bsxfun(@rdivide, feats, fmax); 


fprintf('Training\n');
svmmodel=liblinear_train(labels, feats, '-s 3 -c 0.05 -w1 3 -B 1', 'col');
svmmodel.w(1:end-1)=svmmodel.w(1:end-1)./fmax';

stage2model.bboxmodel=model;
stage2model.bboxcentroids=centroids;
stage2model.rescoremodel=svmmodel;










