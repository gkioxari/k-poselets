function [bounds,rot]=poselet_example_bounds(img2obj_xform,dims)
% Given an image-to-patch transform and target dimensions returns the
% axis-aligned bounds that fit the patch 
    scale = norm(img2obj_xform(1:2,1));
    rot = asin(img2obj_xform(2,1)/scale);
    image_to_obj_xform = [1 0 0; 0 1 0; -1.5 -1.5 1]*[img2obj_xform [0;0;1]]*...
        [cos(-rot) -sin(-rot) 0; sin(-rot) cos(-rot) 0; 0 0 1];% * [0.25 0 0; 0 0.25 0; 0 0 1];

    % First figure out a bounding box that spans the area of interest
    unit_square = [-.5 -.5 1; .5 -.5 1; .5 .5 1; -.5 .5 1; -.5 -.5 1];
    unit_square = unit_square.*repmat([dims([2 1])/min(dims) 1],[5 1]);
    rect_coords = unit_square * inv(image_to_obj_xform);
    rect_coords(:,3)=[];

    min_pt = min(rect_coords);
    max_pt = max(rect_coords);
    bounds=[min_pt max_pt-min_pt];
end