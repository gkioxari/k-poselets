function   [part,examples_info] = create_poselet_procrustes_dist(unit_dims, src_annot, src_patch, a, imglist, disable_rotation)
%% CREATE_POSELET_PROCRUSTES_DISTANCE() constructs the poselet list 

%%
MIN_OVERLAP = 0.3;
annot_size = size(a.coords,3);

warning('off');

if ~exist('disable_rotation','var')
    disable_rotation=true;
end

examples_info.out_of_image=[];
examples_info.out_of_instance=[];
examples_info.scale=[];
examples_info.rot=[];

src_coords = src_annot.coords;
src_dims = src_patch(3:4);
src_angle = src_patch(5);
src_scale = mean(src_dims);

% initialize poselet with seed example
part = poselet(src_annot.entry_id, [src_patch(1:2)-src_dims/2 src_dims], unit_dims);


unit2src_xform = [ src_scale*cos(src_angle) src_scale*sin(src_angle) 0         0
                  -src_scale*sin(src_angle) src_scale*cos(src_angle) 0         0
                   0                        0                        src_scale 0
                   src_patch(1)             src_patch(2)             0         1];
src2unit_xform = inv(unit2src_xform);              
               
unit_square = [-.5 -.5 1; .5 -.5 1; .5 .5 1; -.5 .5 1];
unit_square = unit_square.*repmat([src_dims/min(src_dims) 1],[4 1]);

% Transform the source coords to unit space and select the ones that are
% close. We ignore far away keypoints in computing the fit.
% Unit space is centered at the patch and is scaled so that the shortest
% patch dimenison goes from -0.5 to 0.5
unit_src_coords = [src_coords ones(size(src_coords,1),1)]* src2unit_xform;    

src_kp_inside = get_kp_inside(unit_src_coords,src_dims,1);
valid_src_keypts = ~isnan(src_coords(:,1)) & src_kp_inside;
visible_valid_srckeypts = valid_src_keypts & src_annot.visible;

if sum(valid_src_keypts)<2 || ~any(visible_valid_srckeypts) % the source has less than two keypoints
    return;
end

dst2unit_xforms = zeros([3 2 0]);
errs = [];
selected = [];
for dst_i = 1:annot_size

    dst_coords = a.coords(:,:,dst_i);
    dst_kp_exists = ~isnan(dst_coords(:,1));
    dst_coords(~dst_kp_exists,:) = 0;
    
    shared_keypoints = valid_src_keypts & dst_kp_exists;
    N = sum(shared_keypoints);
    
    if N<max(0.75*sum(valid_src_keypts),3)
       continue;   % This sample has few keypoints shared with the source
    end
    
    % Least squares Ax = b
    if disable_rotation
        A = [unit_src_coords(shared_keypoints,1) ones(N,1) zeros(N,1); ...
             unit_src_coords(shared_keypoints,2) zeros(N,1) ones(N,1)];
        b = [dst_coords(shared_keypoints,1); dst_coords(shared_keypoints,2)];
        x = lscov(A,b);    
    %    x = pinv(A'*A)*A'*b;
        if x(1)<0
           continue;    % optimal match has reflection. Not allowed.
        end
        
        rot=0;
        unit2dst_xform = [x(1) 0 0; 0 x(1) 0; x(2) x(3) 1];
    else
        A = [unit_src_coords(shared_keypoints,1) -unit_src_coords(shared_keypoints,2) ones(N,1) zeros(N,1); ...
             unit_src_coords(shared_keypoints,2)  unit_src_coords(shared_keypoints,1) zeros(N,1) ones(N,1)];
        b = [dst_coords(shared_keypoints,1); dst_coords(shared_keypoints,2)];

        x = lscov(A,b);    
    %    x = pinv(A'*A)*A'*b;
        rot = asin(x(2)/sqrt(x(1)*x(1)+x(2)*x(2)));
        if x(1)<0
            if rot>0
                rot = pi-rot;
            else
                rot = -pi-rot;
            end
        end

        unit2dst_xform = [x(1) x(2) 0; -x(2) x(1) 0; x(3) x(4) 1];
    end
    
    dst2unit_xform = inv(unit2dst_xform);
    if any(isinf(dst2unit_xform(:)))
       continue;    % failed to find the similarity transform
    end
    
    scale = sqrt(sum(dst2unit_xform(1,1:2).^2));
    if scale<0.0001
        continue; % The scale is way out of normal range. It is likely due to degenerate keypoints
    end
    
    examples_info.rot(end+1)   = rot;
    examples_info.scale(end+1) = scale;
                
    rect_coords = unit_square * unit2dst_xform;
    rect_coords(:,3)=[];
    img_dims = imglist(strcmp(a.img_name{dst_i},{imglist.id})).dims;
    examples_info.out_of_image(end+1)=any([rect_coords(:)<=0; rect_coords(:,1)>img_dims(1); rect_coords(:,2)>img_dims(2)]);

    % if outside of bounding box of annotation
    bb_rect = [min(rect_coords,[],1) max(rect_coords,[],1)-min(rect_coords,[],1)];
    examples_info.out_of_instance(end+1)=rectint(bb_rect,a.bounds(dst_i,:))<MIN_OVERLAP*prod(bb_rect(3:4));
    
    % Compute the residual error
    ppp=Inf;
    unit_dst_coords = [dst_coords(:,1:2) ones(size(dst_coords,1),1)]*dst2unit_xform;    
    proc_dist = norm(sqrt(sum((unit_dst_coords(shared_keypoints,1:2) - unit_src_coords(shared_keypoints,1:2)).^2,2)),ppp);

    errs(end+1,1) = proc_dist;
        
    dst2unit_xforms(:,:,end+1) = dst2unit_xform(:,1:2);
    selected(end+1,1)=dst_i;
end
if isempty(errs), return; end

[errs,srtd] = sort(errs,'ascend');
part.img2unit_xforms = dst2unit_xforms(:,:,srtd);
part.errs = errs;
part.dst_entry_ids = a.entry_id(selected(srtd));
part.size=length(errs);
examples_info.out_of_image=examples_info.out_of_image(srtd);
examples_info.out_of_instance=examples_info.out_of_instance(srtd);
examples_info.scale=examples_info.scale(srtd);
examples_info.rot=examples_info.rot(srtd);

end

function kp_inside=get_kp_inside(unit_coords, src_dims, scale)
    unit_dims = src_dims/min(src_dims)*scale;
    kp_inside = unit_coords(:,1)>=-unit_dims(1)/2 & unit_coords(:,1)<=unit_dims(1)/2 & unit_coords(:,2)>=-unit_dims(2)/2 & unit_coords(:,2)<=unit_dims(2)/2;
end



