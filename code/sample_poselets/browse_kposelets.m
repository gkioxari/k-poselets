function browse_kposelets(a,imglist,poselets,pid)

fig = figure;
K = numel(poselets);
colors = {'r','b','g'};
i=1;
while 1

    if i==poselets{1}(pid).size+1, i = i-1; end
    if i==0, i=1; end
    
    % read image
    id = poselets{1}(pid).dst_entry_ids(i);
    img_name = a.img_name{id};
    img = imread(imglist(strcmp(img_name,{imglist.id})).im);
    
    if a.img_flipped(id)
        img = img(:,end:-1:1,:);
    end
    
    figure(fig); clf;
    imshow(img); hold on; 
    title(sprintf('Example %d / %d',i,poselets{1}(pid).size)); hold on;
    
    for k=1:K
        [bounds,rot]=poselet_example_bounds(poselets{k}(pid).img2unit_xforms(:,:,i),poselets{k}(pid).dims);
        rectangle('Position',bounds,'EdgeColor',colors{k}); hold on;
    end
       
     while 1  
        [x,y,ch] = ginput(1);
        if isscalar(ch)
            break;
        end       
    end

   
    switch ch
        case 27 %escape
            close(fig);
            return;
        case 29 % ->
            i = i + 1;        
        case 28 % <-
            i = i - 1;
    end
end

end