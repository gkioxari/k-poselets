rootdir='../data';
imglist.id='000058';
imglist.im=fullfile(rootdir,'000058.jpg');
img=imread(imglist.im);
imglist.dims=[size(img,2) size(img,1)];
load(fullfile(rootdir, 'kposelet_models.mat'));
load(fullfile(rootdir, 'bigram_stage2_models.mat'));%replace with unigram_stage2_models to use only unigrams

%only use selected models
models=models(C);

use_sse=true;

%detect
tic;
detections=collect_detections_on_imglist(imglist, models, 3,1,1, use_sse);
t=toc;
fprintf('Detected models in %f seconds\n',t);
%cluster
clusters = cluster_activations_agglomerative...
            (detections, kps, prec_rec_torsos, [1 4 7 10], 0.3);

%rescore
[scores, bounds, idx]=test_stage2_detection_top(clusters, detections, kps, ...
							prec_rec_torsos, prec_rec_bbox, imglist, bboxpred, ...
							C, stage2model);
%visualize top 3 detections
[s1, i1]=sort(scores, 'descend');
showboundsandscores(img, bounds(i1(1:3),:),scores(i1(1:3)));


