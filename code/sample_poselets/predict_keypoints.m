function coords = predict_keypoints(boxes,kps)
%% PREDICT_KEYPOINTS() returns the predicted keypoints 
%% based on the keypoint models kps 

%%
Kp = size(kps.kps_mean,1); % # of keypoints
K = kps.num_parts;         % # of parts
N = size(boxes,1);         % # of activations

ttx=zeros(Kp,N);
tty=zeros(Kp,N);

for k=1:K
    ctr=(boxes(:,(k-1)*4+1:(k-1)*4+2)+boxes(:,(k-1)*4+3:k*4))/2;
    width=boxes(:,(k-1)*4+3)-boxes(:,(k-1)*4+1);
    kpmeanx=kps.kps_mean(:,1,k);
    kpmeany=kps.kps_mean(:,2,k);
    ttx=ttx+bsxfun(@times,kps.kps_weights(:,k),bsxfun(@plus,kpmeanx*width',ctr(:,1)'));
    tty=tty+bsxfun(@times,kps.kps_weights(:,k),bsxfun(@plus,kpmeany*width',ctr(:,2)'));
end

coords = cat(3,ttx,tty);
coords = permute(coords,[1 3 2]);

end