function data=get_klets_from_poslist(a,poslists,first_el,last_el)

K = numel(poslists);

for i=first_el:last_el
    
    data(i).boxes = [];
    
    for exi = 1:poslists{1}(i).size
        
        temp_bounds = [];
        
        for k=1:K
            
            id = find(a.entry_id==poslists{k}(i).dst_entry_ids(exi));
            [bbox,rot]=poselet_example_bounds(poslists{k}(i).img2unit_xforms(:,:,exi),poslists{k}(i).dims);
            flip = double(a.img_flipped(id));
                       
            image_name = a.img_name{id};
            
            temp_bounds = [temp_bounds flip bbox];
            
        end
        data(i).images{exi,1} = image_name;
        data(i).boxes = [data(i).boxes;temp_bounds];
        
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

