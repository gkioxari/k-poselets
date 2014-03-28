function output=keypoint_klet(a,poslist,first_el,last_el)
%% KEYPOINT_KLET() computes the mean relative location of the keypoints for each klet
%% INPUT
% a         : annot structure
% poslist   : Kx1 cell array of the poslist for each part k=1...K
%% OUTPUT
% output    : Nx1 struct of kps_mean [Kpx2xK array of the mean relative location 
%             of Kp keypoints for each of the K parts of each of the N klets] 
%             and kps_weights [KpxK]

%%
K = numel(poslist); % # of parts
N = numel(poslist{1}); % # of poselets
Kp = size(a.coords,1); % # of keypoints

if nargin<3
    first_el=1;
    last_el=N;
end
%% compute mean
disp('Compute mean...');
kps_mean = nan(Kp,2,K,last_el-first_el+1);

for n=first_el:last_el
    fprintf('In %d\n',n);
    for k=1:K
        part = poslist{k}(n);
        temp_coords = nan(Kp,2,part.size);
        for i=1:part.size
            bounds=poselet_example_bounds(part.img2unit_xforms(:,:,i),part.dims);
            ctr = bounds(1:2)+bounds(3:4)/2;
            width = bounds(3);
            coords = a.coords(:,1:2,part.dst_entry_ids(i));
            coords = bsxfun(@minus,coords,ctr);
            coords = coords/width;
            temp_coords(:,:,i) = coords;
        end
        kps_mean(:,:,k,n-first_el+1)=nanmean(temp_coords,3);
    end
end

%% Learn weights
disp('Compute weights...');
kps_weights = nan(Kp,K,last_el-first_el+1);
final_mean = nan(Kp,2,last_el-first_el+1);
final_std = nan(Kp,2,last_el-first_el+1);

opts = optimset('Algorithm','interior-point-convex','Display','on');

for n=first_el:last_el
    dst_kps = nan(Kp,2,poslist{1}(n).size);
    src_kps = nan(Kp,2,K,poslist{1}(n).size);
    
    final_width = nan(poslist{1}(n).size,1);
    final_ctr = nan(poslist{1}(n).size,2);
    
    for i=1:poslist{1}(n).size
        dst_kps(:,:,i) = a.coords(:,1:2,poslist{1}(n).dst_entry_ids(i));
        for k=1:K
            bounds=poselet_example_bounds(poslist{k}(n).img2unit_xforms(:,:,i),poslist{k}(n).dims);
            ctr = bounds(1:2)+bounds(3:4)/2;
            width = bounds(3);
            if k==1
                final_width(i) = width;
                final_ctr(i,:) = ctr;
            end
            coords = kps_mean(:,:,k,n-first_el+1);
            coords = coords*width;
            coords = bsxfun(@plus,coords,ctr);
            src_kps(:,:,k,i) = coords;
        end
    end
    
    % Solve convex programming of least squares
    for kp = 1:Kp
        f = zeros(K,1);
        H = zeros(K,K);
        for i=1:poslist{k}(n).size
            if isnan(dst_kps(kp,1,i)), continue; end
            for k=1:K
                f(k) = f(k)-2*dst_kps(kp,:,i)*src_kps(kp,:,k,i)';
                for l=1:K
                    H(k,l) = H(k,l)+src_kps(kp,:,k,i)*src_kps(kp,:,l,i)';                   
                end
            end
        end
        
        % solve quadprog
        Aeq = ones(1,K);
        beq = 1;
        if sum(H(:))==0, 
            alphas = nan(K,1);
        else
            alphas = quadprog(2*H,f,[],[],Aeq,beq,zeros(1,K),ones(1,K),[],opts);
        end
        kps_weights(kp,:,n-first_el+1) = alphas';
    end
    
    pred_kps = zeros(size(dst_kps));
    for k=1:K
        pred_kps = pred_kps+permute(src_kps(:,:,k,:),[1 2 4 3]).*repmat(kps_weights(:,k,n-first_el+1),[1 2 poslist{1}(n).size]);
    end
    pred_kps = (pred_kps-repmat(permute(final_ctr,[3 2 1]),[Kp 1 1]))./repmat(permute(final_width,[3 2 1]),[Kp 2 1]);
    final_mean(:,:,n-first_el+1) = nanmean(pred_kps,3);
    final_std(:,:,n-first_el+1) = nanstd(pred_kps,0,3);
    
end

for n=first_el:last_el
    output(n-first_el+1).kps_mean = kps_mean(:,:,:,n-first_el+1);
    output(n-first_el+1).kps_weights = kps_weights(:,:,n-first_el+1);
    output(n-first_el+1).mean = final_mean(:,:,n-first_el+1);
    output(n-first_el+1).std = final_std(:,:,n-first_el+1);
    output(n-first_el+1).num_parts = K;
    output(n-first_el+1).kpid = n;
end

end