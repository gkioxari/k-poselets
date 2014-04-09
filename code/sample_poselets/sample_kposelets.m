function part=sample_kposelets(a,imglist,unit_dims,K,N)
%% SAMPLE_KPOSELETS() returns N K-poselets initialized with random seed examples
%% INPUT
% a         : annot structure
% imglist   : image info
% unit_dims : nx2 of different [h w] aspects
% K         : scalar of the numbers of parts
% N         : scalar of the numbers of K-poselets
%% OUTPUT
% part      : Kx1 cell, each of which contains a part of N different
%            poselets, e.g. the k-th (k=1,...,K) part of i-th poselet 
%            (i=1,...,N) is in part{k}.poselet(i)

%%
num_candidates=N;
num_poslist = 40; % minimum examples for each poselet
MIN_OVERLAP = 0.5;
MIN_NUM_KPS = 4;
MAX_POSLIST = 200;

all_bounds = a.bounds;
annot_size = size(a.coords,3);

rng('shuffle');
%  [status seed] = system('od /dev/urandom --read-bytes=4 -tu | awk ''{print $2}''');
%  seed=str2double(seed);
%  rng(seed);

for k=1:K
    part{k} = poselet(0,0,0);
end
while length(part{1})<num_candidates+1
    
    % pick a random annotation
    annot_id = ceil(rand*annot_size);
    annot_bounds = all_bounds(annot_id,:);
    if any(isnan(annot_bounds(:))), continue; end
    
    disp(annot_id);
    
    found_example = false(K,1);
    
    keep_trying = true;
    for k=1:K
        
        num_iter = 0;
       
        while keep_trying && ~found_example(k)
            
            % if it can't find a part after 100 trials, change the seed
            num_iter = num_iter+1;
            if num_iter>100 
                keep_trying=false;
                continue; 
            end
            
            % pick an aspect ratio and a location for the seed
            pick_unit_dims(k,:) = unit_dims(randi(size(unit_dims,1),1),:);
            ctr(k,:) = ceil(rand(1,2).*annot_bounds(3:4))+annot_bounds(1:2);
            scale(k) = rand*min(annot_bounds(3:4)./pick_unit_dims(k,[2 1])*2);
            dims(k,:) = pick_unit_dims(k,[2 1])*scale(k);
            bounds(k,:) = [ctr(k,:)-dims(k,:)/2 dims(k,:)];

            % check which keypoints are within the bounds of the seed
            kps_set{k}=is_within(bounds(k,:),a.coords(:,1:2,annot_id));

            % check whether bounds is significantly within ground truth bounds
            if rectint(annot_bounds,bounds(k,:))<MIN_OVERLAP*prod(dims(k,:))
                keep_trying=true;
                continue;
            end

            % check whether keypoints within bounds are few
            if length(kps_set{k})<MIN_NUM_KPS
                keep_trying = true;
                continue;
            end

            % check wether part is outside the image borders
            img_dims = imglist(strcmp(a.img_name{annot_id},{imglist.id})).dims;
            if any(bounds(k,1:2)<=0) || any(bounds(k,1:2)+bounds(k,3:4)>img_dims)
                keep_trying = true;
                continue;
            end

            % check whether the parts include a diverse set of keypoints
            if K>1
                if k==1
                    found_example(k)=true;
                end
                for kk = 1:(k-1)
                    iou = length(intersect(kps_set{k},kps_set{kk}))/length(union(kps_set{k},kps_set{kk}));
                    if iou<0.5
                        found_example(k)=true; 
                    end
                end
            else
                found_example(k)=true;
            end
        end
    end

    
    % if no K parts at the seed example have been found, change seed
    if ~all(found_example)
        continue;
    end
        
    % for each of the K parts, find similar examples (poselet construction)
    for k=1:K
        a_sel = select_annotations(a,annot_id);
        new_part(k) = create_poselet_examples(pick_unit_dims(k,:),a_sel,[ctr(k,:) dims(k,:) 0], a, imglist, true);
        new_part(k).src_bounds = bounds(k,:);
    end
    
    dst_entry_ids = new_part(1).dst_entry_ids;
    for k=2:K
        dst_entry_ids = intersect(dst_entry_ids,new_part(k).dst_entry_ids);
    end
    
    
    if length(dst_entry_ids)<num_poslist
        fprintf('Reject1 (%d)\n',length(dst_entry_ids));
        continue;
    end
    
    errs = zeros(length(dst_entry_ids),1);
    for k=1:K
        [tf loc] = ismember(dst_entry_ids,new_part(k).dst_entry_ids);
        loc = loc(tf);
        new_part(k)=new_part(k).select(loc);
        errs = errs+new_part(k).errs;
    end
    [s si] = sort(errs,'ascend');
    for k=1:K
        new_part(k) = new_part(k).select(si);
    end
    
    % Reject if displacement in space or scale is large
    bounds = nan(new_part(1).size,4,K);
    scale_diff = nan(new_part(1).size,K);
    space_diff = nan(new_part(1).size,K);
    for exi=1:new_part(1).size
        for k=1:K
            [bounds(exi,:,k),rot]=poselet_example_bounds(new_part(k).img2unit_xforms(:,:,exi),new_part(k).dims);
            
            scale_diff(exi,k) = bounds(exi,3,k)/bounds(exi,3,1);
            scale_diff(exi,k) = scale_diff(exi,k)/scale_diff(1,k);
            
            displ = bounds(exi,1:2,k)+bounds(exi,3:4,k)/2-bounds(exi,1:2,1)-bounds(exi,3:4,1)/2;
            seed_displ = bounds(1,1:2,k)+bounds(1,3:4,k)/2-bounds(1,1:2,1)-bounds(1,3:4,1)/2;
            wt = bounds(1,3,1)/bounds(exi,3,1);
            displ_allow = bounds(1,3,k)/new_part(k).dims(2)*8*4;
            
            space_diff(exi,k) = norm(seed_displ-wt*displ)/displ_allow;
        end
    end
    clear bounds;
    keep = scale_diff<=1.2 & scale_diff>=1/1.2 & space_diff<=1;
    keep = sum(keep,2);
    keep = find(keep==K);
    
    if length(keep)<num_poslist
        fprintf('Reject2 (%d)\n',length(keep));
        continue;
    end
    
    keep = keep(1:min(length(keep),MAX_POSLIST));
    for k=1:K
        new_part(k) = new_part(k).select(keep);
        part{k}(end+1)=new_part(k);
    end

    fprintf('\n');
    disp(sprintf('Added part %d',length(part{1})));
end
for k=1:K
    part{k}(1)=[]; % the first part is empty
end

end

function index_in=is_within(bounds,coords)

bounds(3:4) = bounds(1:2)+bounds(3:4);
index_in = coords(:,1)>=bounds(1) & coords(:,1)<=bounds(3) & coords(:,2)>=bounds(2) & coords(:,2)<=bounds(4);
index_in = find(index_in);

end

