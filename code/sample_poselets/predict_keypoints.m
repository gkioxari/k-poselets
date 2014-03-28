function coords = predict_keypoints(boxes,kps)
%% PREDICT_KEYPOINTS() returns the predicted keypoints 
%% based on the keypoint models kps 

%%
Kp = size(kps.kps_mean,1); % # of keypoints
K = kps.num_parts;         % # of parts

bb=boxes(1:4*K);
bb = reshape(bb,[4 K])';
ctr = (bb(:,1:2)+bb(:,3:4))/2;
width = bb(:,3)-bb(:,1);
coords = zeros(Kp,2);
for k=1:K
    temp_coords = kps.kps_mean(:,:,k)*width(k);
    temp_coords = bsxfun(@plus,temp_coords,ctr(k,:));
    coords=coords+bsxfun(@times,temp_coords,kps.kps_weights(:,k));
end

end