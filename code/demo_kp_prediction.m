rootdir='../data';
%rootdir = '/Users/gkioxari/Desktop/data/tmp/';
imglist.id='im1';
imglist.im=fullfile(rootdir,'im1.jpg');
img=imread(imglist.im);
imglist.dims=[size(img,2) size(img,1)];
load(fullfile(rootdir, 'kposelet_models.mat'));
load(fullfile(rootdir, 'kp_prediction.mat'));

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
            (detections, kps, prec_rec_torso, [1 4 7 10], 0.3);
        
        

% torso predictions
clusters = torso_score(detections,clusters,kps,prec_rec_torso,[1 4 7 10]);

% keypoint predictions
kp_pred = kposelet_keypoint_prediction(...
    imglist,detections,clusters,prec_rec_kps,kps);


[s1, i1]=sort([clusters.torso_score], 'descend');

%visualize top 1 torso detections
bounds = clusters(i1(1)).torso_bounds;
score = clusters(i1(1)).torso_score;
showboundsandscores(img, bounds,score);

%visualize corresponding keypoint predictions
figure;
showkeypoints(img,kp_pred.coords(:,:,i1(1)));


