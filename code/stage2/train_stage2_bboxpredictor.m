function [model, centroids]=train_stage2_bboxpredictor(clusters, detections, kps, precrec_mapping,imglist,a, bbox_pred, selected)
rng('default');
rng(1);
%get the mapped scores
newscores = map_scores_using_precrec(detections.scores, detections.kpids, precrec_mapping);

%get the leader
leaders=get_cluster_leader(clusters, newscores);

%use the leader to predict torsos
%torsos=get_torso_predictions(detections.boxes(leaders,:), detections.kpids(leaders), kps);
torsos=get_weighted_torso_predictions(clusters, newscores, detections.boxes, detections.kpids, kps);


%get regression data
[index, ovall, gt_bounds]=get_regression_trainingdata(a, imglist, [clusters.imid],torsos);
pick=find(ovall>=0.3);
numel(pick)

[labels, centroids]= get_bbox_reg_labels(gt_bounds(index(pick),:), torsos(pick,:),2);

%get the baseline bounds predictions
pred_bounds=get_baseline_bounds_predictions(clusters, newscores, detections.boxes, detections.kpids,  bbox_pred);
pred_bounds=clipboxes(pred_bounds, [clusters.imid], imglist);

feats=extract_bbox_hog_feats(torsos(pick,:), pred_bounds(pick,:), [clusters(pick).imid], imglist);

model=liblinear_train(labels, feats, '-s 0 -c 0.1 -B 1', 'col');
[ypred, acc, dec]=predict(labels, feats, model,'-b 1', 'col');
acc

