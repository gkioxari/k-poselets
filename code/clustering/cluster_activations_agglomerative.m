function [clusters]=cluster_activations_agglomerative(boxes,kps,dtc_prec,thresh)

Kp = size(kps.kps_mean,1);
torso_ks = [1 4 7 10];
ci=0;

image_ids = unique(boxes(:,end))';

for imid=image_ids
    
    keep = find(boxes(:,end)==imid);
    N = length(keep);
    if N==0, continue; end
    fprintf('Image Id %d\n',imid);
    fprintf('...Getting torso bounds\n');
    torso_bounds = nan(N,4);
    scores = nan(N,1);
    for i=1:N
        kid = boxes(keep(i),end-1);
        K = kps.num_parts(kid);
        bb = reshape(boxes(keep(i),1:4*K),[4 K])';
        ctr = (bb(:,1:2)+bb(:,3:4))/2;
        width = bb(:,3)-bb(:,1);
        tt = zeros(Kp,2);
        for k=1:K
            temp_coords =kps.kps_mean(:,:,k,kid)*width(k);
            temp_coords = bsxfun(@plus,temp_coords,ctr(k,:));
            tt=tt+bsxfun(@times,temp_coords,kps.kps_weights(:,k,kid));
        end
        tt = tt(torso_ks,:);
        torso_bounds(i,:) = [min(tt,[],1) max(tt,[],1)-min(tt,[],1)];
        
        [m mi]=min(abs(dtc_prec(kid).scores-boxes(keep(i),end-2)));
        scores(i)=dtc_prec(kid).prec(mi);
    end
    fprintf('...Computing IOU\n');
    iou = inters_union(torso_bounds,torso_bounds);
    fprintf('...Computing dist\n');
%    dist = inf(1,N*(N-1)/2);
%    di=0;
 %   for j=1:N
  %      for i=j+1:N
  %          di = di+1;
   %         dist(di)=1-iou(i,j);
   %     end
   % end
    
    fprintf('...Agglomerative Clustering\n');
%     Z = linkage(dist,'complete');
    Z=leaderlinkage2(1-iou, scores);
    if ~isempty(Z)
    	T = cluster(Z,'cutoff',thresh,'criterion','distance');
    else
	T=1;
    end
    num_clust = max(T);
    for i=1:num_clust
        ci = ci+1;
        clusters(ci).members = keep(T==i);
        clusters(ci).imid = imid;
    end
        
end

end

function iou = inters_union(bounds1,bounds2)

inters = rectint(bounds1,bounds2);
ar1 = bounds1(:,3).*bounds1(:,4);
ar2 = bounds2(:,3).*bounds2(:,4);
union = bsxfun(@plus,ar1,ar2')-inters;

iou = inters./(union+0.001);

end
