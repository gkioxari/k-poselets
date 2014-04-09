function pred_bounds=test_stage2_bboxpredictor(clusters, detections,kps, precrec_mapping, imglist, bbox_pred, model, centroids, selected,pred_torsos, pred_bounds)
if(~exist('pred_torsos', 'var'))
%get the mapped scores
newscores = map_scores_using_precrec(detections.scores, detections.kpids, precrec_mapping);

%get the leader
leaders=get_cluster_leader(clusters, newscores);

%use the leader to predict torsos
pred_torsos=get_weighted_torso_predictions(clusters, newscores, detections.boxes, detections.kpids, kps);

%get the baseline bounds predictions
pred_bounds=get_baseline_bounds_predictions(clusters, newscores, detections.boxes, detections.kpids,  bbox_pred);
pred_bounds=clipboxes(pred_bounds, [clusters.imid], imglist);

end

feats2=[];%create_fv_v2(clusters, boxes, data, imglist, im, selected, kps);

pred_bounds=predict_all_bboxes(pred_torsos, pred_bounds, [clusters.imid], imglist, model, centroids,feats2);
pred_bounds=clipboxes(pred_bounds, [clusters.imid], imglist);

